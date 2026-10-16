//
//  FriendsAPI.swift
//  Actifit
//
//  Friend reads and writes against the Actifit backend and Hive, ported from Android's
//  FriendsApi / FriendsActivity / FriendAccountAdapter.
//
//  Every write is TWO steps, reusing the login token (x-acti-token), with no key on the device:
//    1. Broadcast a posting-auth `custom_json` (id "actifit", {transaction, target}) through
//       performTrx. The server signs, broadcasts and stores the tx, and returns its id.
//    2. Call the friend endpoint with that tx id; the backend verifies it against what
//       performTrx stored.
//  Once step 1 has succeeded only step 2 is ever retried, with the same tx id: re-broadcasting
//  would put a duplicate op on chain.
//
//  Every completion runs on the main queue.
//

import Foundation

enum FriendsAPI {

    enum Action {
        case add, accept, cancelRequest, unfriend

        var transaction: String {
            switch self {
            case .add: return "add-friend-request"
            case .accept: return "accept-friendship"
            case .cancelRequest: return "cancel-friend-request"
            case .unfriend: return "cancel-friendship"
            }
        }

        var endpoint: String {
            switch self {
            case .add: return "addFriend"
            case .accept: return "acceptFriend"
            case .cancelRequest: return "cancelFriendRequest"
            case .unfriend: return "dropFriendship"
            }
        }
    }

    static let baseURL = "https://api.actifit.io/"

    /// Actifit's own node first, then public fallbacks (same order as Android).
    static let hiveNodes = [
        "https://hiveapi.actifit.io", "https://api.deathwing.me", "https://api.hive.blog",
        "https://techcoderx.com", "https://api.openhive.network", "https://rpc.mahdiyari.info",
        "https://api.syncad.com", "https://api.c0ff33a.uk"
    ]

    // MARK: - Reads

    /// A user's friends; nil when the request failed (not the same as no friends).
    static func friends(of user: String, completion: @escaping ([String]?) -> Void) {
        get("userFriends/" + enc(user)) { json in completion(json.map { FriendsLogic.friends(from: $0) }) }
    }

    /// Pending requests either way; nil when the request failed.
    static func requests(of user: String, completion: @escaping ((received: [String], sent: [String])?) -> Void) {
        get("userFriendRequests/" + enc(user)) { json in completion(json.map { FriendsLogic.requests(from: $0) }) }
    }

    static func rewardedReports(of user: String, completion: @escaping (Int?) -> Void) {
        get("userRewardedPostCount/" + enc(user)) { json in
            completion(((json as? [String: Any])?["rewarded_post_count"] as? NSNumber)?.intValue)
        }
    }

    static func afitBalance(of user: String, completion: @escaping (Double?) -> Void) {
        get("user/" + enc(user)) { json in
            let tokens = (json as? [String: Any])?["tokens"]
            completion((tokens as? NSNumber)?.doubleValue ?? (tokens as? String).flatMap(Double.init))
        }
    }

    /// Recent verified reporters, most active first. Short timeout: it races the Hive source.
    static func recentVerifiedAuthors(excluding me: String, completion: @escaping ([String]?) -> Void) {
        get("recentVerifiedPosts?exclude=" + enc(me) + "&maxCount=20", timeout: 5) { json in
            completion((json as? [[String: Any]])?.compactMap { $0["_id"] as? String })
        }
    }

    /// One page of recent #actifit posts from Hive, tried node by node. Returns the authors in
    /// order and the cursor (last author/permlink) for the next page; nil if no node answered.
    static func recentActifitAuthors(after cursor: (author: String, permlink: String)?,
                                     completion: @escaping (_ authors: [String]?, _ next: (author: String, permlink: String)?, _ pageSize: Int) -> Void) {
        var query: [String: Any] = ["tag": "actifit", "limit": 20]
        if let c = cursor {
            query["start_author"] = c.author
            query["start_permlink"] = c.permlink
        }
        rpc("condenser_api.get_discussions_by_created", params: [query], timeout: 6) { result in
            guard let posts = result as? [[String: Any]] else { return completion(nil, nil, 0) }
            var authors: [String] = []
            for p in posts { if let a = p["author"] as? String, !authors.contains(a) { authors.append(a) } }
            let next = posts.last.flatMap { last -> (author: String, permlink: String)? in
                guard let a = last["author"] as? String, let p = last["permlink"] as? String else { return nil }
                return (a, p)
            }
            completion(authors, next, posts.count)
        }
    }

    /// Hive accounts starting with `prefix`. Stops at the first node that answers, even with an
    /// empty list (that is a real answer, not a failure).
    static func lookupAccounts(prefix: String, limit: Int, completion: @escaping ([String]) -> Void) {
        rpc("condenser_api.lookup_accounts", params: [prefix, limit], timeout: 4) { result in
            completion((result as? [String]) ?? [])
        }
    }

    // MARK: - Writes

    static func perform(_ action: Action, me: String, target: String, completion: @escaping (Bool) -> Void) {
        let token = UserDefaults.standard.authToken
        guard !me.isEmpty, !target.isEmpty, !token.isEmpty else {
            // The launch-time login may have failed; fetch a token so the next try can work.
            if token.isEmpty && !me.isEmpty { TokenManager.shared.refreshToken() }
            return DispatchQueue.main.async { completion(false) }
        }
        let inner: [String: Any] = ["transaction": action.transaction, "target": target]
        guard let innerData = try? JSONSerialization.data(withJSONObject: inner),
              let innerJson = String(data: innerData, encoding: .utf8) else { return DispatchQueue.main.async { completion(false) } }
        let operation: [Any] = ["custom_json", [
            "required_auths": [String](),
            "required_posting_auths": [me],
            "id": "actifit",
            "json": innerJson
        ]]
        guard let opData = try? JSONSerialization.data(withJSONObject: operation),
              let opJson = String(data: opData, encoding: .utf8),
              let url = URL(string: ApiUrls.broadCastQueryAPI + "?user=" + enc(me)
                            + "&operation=" + enc("[" + opJson + "]") + "&bchain=HIVE") else {
            return DispatchQueue.main.async { completion(false) }
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.addBroadCastHeaderWhenAfitSent()
        // Step 1 is sent once and never retried: a retry could put a second op on chain.
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let doc = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            let tx = (doc?["trx"] as? [String: Any])?["tx"] as? [String: Any]
            guard doc?["success"] != nil, let trxId = tx?["id"] as? String else {
                return DispatchQueue.main.async { completion(false) }
            }
            // The backend verifies by tx id; the block only fills the route.
            let block = (tx?["ref_block_num"] as? NSNumber)?.intValue ?? 0
            let path = action.endpoint + "/" + enc(me) + "/" + enc(target) + "/\(block)/" + enc(trxId) + "/HIVE"
            index(path, attemptsLeft: 2, completion: completion)
        }.resume()
    }

    /// Step 2, safe to repeat: it carries the same tx id every time.
    private static func index(_ path: String, attemptsLeft: Int, completion: @escaping (Bool) -> Void) {
        get(path, timeout: 20) { json in
            if let doc = json as? [String: Any] {
                return completion(doc["status"] as? String == "success")
            }
            if attemptsLeft > 1 { index(path, attemptsLeft: attemptsLeft - 1, completion: completion) }
            else { completion(false) }
        }
    }

    // MARK: - Transport

    /// Parsed JSON, or nil on a transport error, a non-2xx status or a body that isn't JSON.
    private static func get(_ path: String, timeout: TimeInterval = 15, completion: @escaping (Any?) -> Void) {
        guard let url = URL(string: baseURL + path) else { return DispatchQueue.main.async { completion(nil) } }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let json = (error == nil && (200..<300).contains(status)) ? data.flatMap { try? JSONSerialization.jsonObject(with: $0) } : nil
            DispatchQueue.main.async { completion(json) }
        }.resume()
    }

    /// A Hive JSON-RPC call tried across the nodes until one returns a `result`.
    private static func rpc(_ method: String, params: [Any], timeout: TimeInterval, node: Int = 0,
                            completion: @escaping (Any?) -> Void) {
        guard node < hiveNodes.count, let url = URL(string: hiveNodes[node]) else {
            return DispatchQueue.main.async { completion(nil) }
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["jsonrpc": "2.0", "method": method, "params": params, "id": 1])
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let doc = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            if let result = doc?["result"] {
                DispatchQueue.main.async { completion(result) }
            } else {
                rpc(method, params: params, timeout: timeout, node: node + 1, completion: completion)
            }
        }.resume()
    }

    private static func enc(_ s: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
}
