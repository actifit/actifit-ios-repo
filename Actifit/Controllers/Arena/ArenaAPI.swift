//
//  ArenaAPI.swift
//  Actifit
//
//  The Arena (challenge engine) backend, ported from Android's ArenaApi.java.
//
//  Reads are public GETs. Writes are chain-first: a join/leave is a posting-auth
//  `custom_json` with id "actifit_arena", signed on the device and broadcast straight to Hive
//  (HiveBroadcaster); the backend no longer signs for the app. There is NO confirm call: the
//  backend tails the chain and applies the op a few seconds later, so callers keep the new
//  state optimistically (see ArenaPendingStore).
//
//  Every completion runs on the main queue.
//

import Foundation

enum ArenaAPI {

    static let baseURL = "https://api.actifit.io/"
    private static let readTimeout: TimeInterval = 15

    /// Public challenges, optionally filtered by one state and/or a participant.
    /// nil means the request failed, which is not the same as an empty list.
    static func listChallenges(state: String?, entity: String?, completion: @escaping ([ArenaChallenge]?) -> Void) {
        var query: [String] = []
        if let state = state { query.append("state=" + enc(state)) }
        if let entity = entity, !entity.isEmpty { query.append("entity=" + enc(entity)) }
        let url = baseURL + "arena/challenges" + (query.isEmpty ? "" : "?" + query.joined(separator: "&"))
        read(url) { data, _ in
            guard let data = data,
                  let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
                return completion(nil)
            }
            completion(arr.map { ArenaChallenge(json: $0) }.filter { !$0.id.isEmpty })
        }
    }

    /// One challenge with its participants; `viewer` marks whether they are in it.
    static func challenge(id: String, viewer: String, completion: @escaping (_ challenge: ArenaChallenge?, _ notFound: Bool) -> Void) {
        read(baseURL + "arena/challenges/" + enc(id)) { data, status in
            guard let data = data,
                  let doc = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let c = ArenaChallenge.fromDetail(doc, viewer: viewer) else {
                return completion(nil, status == 404)
            }
            completion(c, false)
        }
    }

    /// The standings board. The backend sends an empty body until one has been computed, so
    /// rows are empty in that case and nil only when the fetch itself failed.
    static func standings(id: String, completion: @escaping (_ rows: [ArenaStandingRow]?, _ computedAt: Date?) -> Void) {
        read(baseURL + "arena/standings?id=" + enc(id)) { data, _ in
            guard let data = data else { return completion(nil, nil) }
            guard let doc = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return completion([], nil)   // empty or malformed board: show the empty state
            }
            completion(ArenaChallenge.standings(from: doc), ArenaLogic.parseDate(doc["computed_at"] as? String))
        }
    }

    /// Badges a user has earned in public challenges, and the total count; empty on failure.
    static func badges(user: String, completion: @escaping (_ badges: [ArenaBadge], _ total: Int) -> Void) {
        read(baseURL + "arena/badges/" + enc(user) + "?limit=20") { data, _ in
            guard let data = data,
                  let doc = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return completion([], 0)
            }
            let badges = ArenaChallenge.badges(from: doc)
            completion(badges, max((doc["count"] as? NSNumber)?.intValue ?? 0, badges.count))
        }
    }

    /// The signed operation's json, written the same way every time.
    static func opJson(_ op: ArenaLogic.Op, challengeId: String) -> String {
        return "{\"op\":" + HiveJSON.string(op.rawValue) + ",\"v\":1,\"challenge_id\":" + HiveJSON.string(challengeId) + "}"
    }

    /// Signs a join or leave on the device and broadcasts it. ok means it is on chain, not that
    /// the backend accepted it: a rejected op is silent, so the pending state just never
    /// confirms. ambiguous: it may still land, so the caller keeps the pending state. message is
    /// fit to show when !ok.
    static func send(_ op: ArenaLogic.Op, user: String, challengeId: String,
                     completion: @escaping (_ ok: Bool, _ ambiguous: Bool, _ message: String?) -> Void) {
        guard !user.isEmpty, !challengeId.isEmpty else {
            return DispatchQueue.main.async { completion(false, false, nil) }
        }
        let operation = HiveOp.postingJson(account: user, id: "actifit_arena", json: opJson(op, challengeId: challengeId))
        HiveBroadcaster.broadcast([operation], role: .posting) { r in
            completion(r.ok, r.ambiguous, r.error)
        }
    }

    /// Data is nil on a transport error or a non-2xx status.
    private static func read(_ urlString: String, completion: @escaping (_ data: Data?, _ status: Int?) -> Void) {
        guard let url = URL(string: urlString) else {
            return DispatchQueue.main.async { completion(nil, nil) }
        }
        // Membership and standings must reflect the server, not a cached response.
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: readTimeout)
        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode
            let ok = error == nil && (status.map { (200..<300).contains($0) } ?? false)
            DispatchQueue.main.async { completion(ok ? (data ?? Data()) : nil, status) }
        }.resume()
    }

    /// Strict query/path encoding: rolled-over ids contain "@", which must not pass through raw.
    private static func enc(_ s: String) -> String { return HiveURL.component(s) }
}

/// Remembers a join/leave the user just broadcast, per user and challenge. The backend only
/// indexes the op a few seconds later, so without this the "Joined" state would vanish the
/// moment the screen is reopened.
enum ArenaPendingStore {

    private static let defaultsKey = "arenaPending"

    private static func key(_ user: String, _ challengeId: String) -> String {
        return user + "|" + challengeId
    }

    private static var all: [String: [String: Any]] {
        get { return UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: [String: Any]] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    static func put(user: String, challengeId: String, op: ArenaLogic.Op, at: Date = Date()) {
        all[key(user, challengeId)] = ["op": op.rawValue, "at": at.timeIntervalSince1970]
    }

    static func get(user: String, challengeId: String) -> (op: ArenaLogic.Op, at: Date)? {
        guard let entry = all[key(user, challengeId)],
              let op = (entry["op"] as? String).flatMap(ArenaLogic.Op.init(rawValue:)),
              let at = entry["at"] as? TimeInterval else { return nil }
        return (op, Date(timeIntervalSince1970: at))
    }

    static func clear(user: String, challengeId: String) {
        all[key(user, challengeId)] = nil
    }

    /// Membership as far as we can tell, without consuming the stored op.
    static func membership(user: String, challenge: ArenaChallenge) -> ArenaLogic.Membership {
        guard !user.isEmpty else { return .notJoined }
        let p = get(user: user, challengeId: challenge.id)
        return ArenaLogic.membership(serverJoined: challenge.serverJoined, op: p?.op, at: p?.at ?? Date(), now: Date())
    }

    /// Drops the stored op once the server has caught up with it or it has gone unconfirmed
    /// past the TTL. Returns true when it expired, so the caller can say so.
    static func settle(user: String, challenge: ArenaChallenge) -> Bool {
        guard let p = get(user: user, challengeId: challenge.id) else { return false }
        let expired = ArenaLogic.pendingExpired(serverJoined: challenge.serverJoined, op: p.op, at: p.at, now: Date())
        if expired || ArenaLogic.pendingConfirmed(serverJoined: challenge.serverJoined, op: p.op) {
            clear(user: user, challengeId: challenge.id)
        }
        return expired
    }
}
