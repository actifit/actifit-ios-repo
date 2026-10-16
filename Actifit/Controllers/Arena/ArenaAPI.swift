//
//  ArenaAPI.swift
//  Actifit
//
//  The Arena (challenge engine) backend, ported from Android's ArenaApi.java.
//
//  Reads are public GETs. Writes are chain-first: a join/leave is a posting-auth
//  `custom_json` with id "actifit_arena", broadcast server-side through performTrx with the
//  login token (the same path as the gadget and tip operations in API.swift). There is NO
//  second "index" call: the backend tails the chain and applies the op a few seconds later,
//  so callers keep the new state optimistically (see ArenaPendingStore).
//
//  Every completion runs on the main queue.
//

import Foundation

enum ArenaAPI {

    static let baseURL = "https://api.actifit.io/"
    private static let readTimeout: TimeInterval = 15
    private static let broadcastTimeout: TimeInterval = 30

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

    /// Broadcasts a join or leave. Success means the relay put it on chain, not that the
    /// backend accepted it: a rejected op is silent, so the pending state just never confirms.
    static func send(_ op: ArenaLogic.Op, user: String, challengeId: String, completion: @escaping (Bool) -> Void) {
        let token = UserDefaults.standard.authToken
        guard !user.isEmpty, !challengeId.isEmpty, !token.isEmpty else {
            // The launch-time login may have failed; fetch a token so the next try can work.
            if token.isEmpty && !user.isEmpty { TokenManager.shared.refreshToken() }
            return DispatchQueue.main.async { completion(false) }
        }
        let body: [String: Any] = ["op": op.rawValue, "v": 1, "challenge_id": challengeId]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body),
              let bodyJson = String(data: bodyData, encoding: .utf8) else {
            return DispatchQueue.main.async { completion(false) }
        }
        let operation: [Any] = ["custom_json", [
            "required_auths": [String](),
            "required_posting_auths": [user],
            "id": "actifit_arena",
            "json": bodyJson
        ]]
        guard let opData = try? JSONSerialization.data(withJSONObject: operation),
              let opJson = String(data: opData, encoding: .utf8),
              let url = URL(string: ApiUrls.broadCastQueryAPI + "?user=" + enc(user)
                            + "&operation=" + enc("[" + opJson + "]") + "&bchain=HIVE") else {
            return DispatchQueue.main.async { completion(false) }
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: broadcastTimeout)
        request.addBroadCastHeaderWhenAfitSent()
        // This GET signs and broadcasts: it is sent exactly once, never retried, because a
        // retry after a slow response would put a second op on chain.
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let doc = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            let tx = (doc?["trx"] as? [String: Any])?["tx"] as? [String: Any]
            let ok = doc?["success"] != nil && tx?["ref_block_num"] != nil
            DispatchQueue.main.async { completion(ok) }
        }.resume()
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
    private static func enc(_ s: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
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
