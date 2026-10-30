//
//  HiveBroadcaster.swift
//  Actifit
//
//  Signs a transaction on the device with the user's own key and broadcasts it straight to a
//  Hive node, falling back through a short node list. The key never leaves the phone: only the
//  signed transaction goes to the node. The result carries the transaction id, which the
//  backend's *Keychain routes then use to confirm the operation from the chain.
//
//  A broadcast whose fate is unclear (a node may have taken it before its reply was lost) is
//  never replaced by a newly signed one while it can still land: the same signed transaction
//  is re-sent until it expires, and after that the chain is asked whether it got in.
//
//  Ported from Android's HiveBroadcaster.java.
//

import Foundation

enum HiveBroadcaster {

    /// Which of the user's keys an operation needs.
    enum KeyRole: String { case posting, active }

    /// A signed transaction, as callers may store it to re-send or re-confirm later.
    struct Signed: Codable {
        let txJson: String
        let txId: String
        let refBlockNum: Int
        let opsJson: String
        /// Device time at which the transaction expires (only decides re-send vs. check).
        let expiresAt: Date
        /// Head block when signed: the transaction can only be in a later block.
        let startBlock: UInt64
        /// Chain expiration (unix seconds): the proof of absence compares block times to it.
        let expirationSec: UInt32
    }

    struct Result {
        let ok: Bool
        /// Set when ok.
        let txId: String?
        let refBlockNum: Int
        /// The ops array as JSON, for the backend's ?operation= confirm parameter.
        let operationsJson: String?
        /// Set when !ok: a message fit to show the user.
        let error: String?
        /// !ok but the transaction may still be (or get) on chain: do not sign a replacement.
        let ambiguous: Bool

        static func fail(_ message: String) -> Result {
            return Result(ok: false, txId: nil, refBlockNum: 0, operationsJson: nil, error: message, ambiguous: false)
        }
    }

    /// Seconds until the signed transaction expires (hived allows up to 3600).
    private static let expirationSeconds: UInt32 = 120
    /// An unresolved transaction is reused for a retry of the same action only this long after
    /// it expired; later, the same operations are a new intent (e.g. vote, unvote, vote again).
    /// Money moves with the active key, so an unclear transfer is held much longer: a retry
    /// hours later must settle the first one, never pay a second time.
    private static func reuseWindow(_ role: KeyRole) -> TimeInterval {
        return role == .active ? 6 * 60 * 60 : 10 * 60
    }
    /// Blocks scanned after signing to prove a transaction is NOT on chain (120 s = 40 blocks).
    private static let scanBlocks = 50

    /// Actifit's node first, then public fallbacks; at most four per attempt, so a dead network
    /// fails in seconds rather than minutes.
    static let nodes = Array(FriendsAPI.hiveNodes.prefix(4))

    private static let queue = DispatchQueue(label: "io.actifit.hive.broadcast", attributes: .concurrent)
    private static let lock = NSLock()
    /// Transactions whose broadcast is unresolved, keyed by role|ops. Kept on disk, so an
    /// unclear broadcast is still settled (not signed again) after the app is closed.
    private static let pendingKey = "hivePendingTx"
    /// Actions being signed or sent right now: a second tap waits rather than signs again.
    private static var inFlight = Set<String>()

    /// The posting key saved at login ("" when there is none).
    static var storedPostingKey: String {
        return User.current()?.private_posting_key ?? ""
    }

    /// Signs with the stored posting key (or `explicitKey`, e.g. the active key from Settings or
    /// a dialog) and broadcasts. The completion runs on the main queue.
    static func broadcast(_ ops: [HiveOp], role: KeyRole, explicitKey: String? = nil,
                          completion: @escaping (Result) -> Void) {
        queue.async {
            let r = signAndSend(ops, role: role, explicitKey: explicitKey, onSigned: nil)
            DispatchQueue.main.async { completion(r) }
        }
    }

    /// Blocking: signs and broadcasts. Call off the main queue. `onSigned` gets the signed
    /// transaction before anything is sent, so a caller can store it first.
    static func signAndSend(_ ops: [HiveOp], role: KeyRole, explicitKey: String?,
                            onSigned: ((Signed) -> Void)?) -> Result {
        let given = explicitKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let wif = !given.isEmpty ? given : (role == .posting ? storedPostingKey : "")
        return run(ops, wif: wif, role: role, onSigned: onSigned)
    }

    /// Blocking: settles a transaction signed earlier. Before it expires it is re-sent as is;
    /// after, the chain is asked. ok = it is on chain; !ok && !ambiguous = it never landed.
    static func resend(_ s: Signed, role: KeyRole) -> Result {
        if Date() < s.expiresAt { return send(key: nil, s, role: role, fresh: false) }
        return settleExpired(key: nil, s)
    }

    /// Drops the in-memory record of an action the caller has settled.
    static func forget(role: KeyRole, opsJson: String) {
        setPending(role.rawValue + "|" + opsJson, nil)
    }

    /// Claims the account's pending rewards: reads the exact pending balances from the chain
    /// (the claim must not exceed them) and signs claim_reward_balance with the posting key.
    /// ok with a nil txId means there was nothing to claim.
    static func claimRewards(account: String, completion: @escaping (Result) -> Void) {
        queue.async {
            var r: Result
            var acc: [String: Any]?
            for node in nodes {
                if let res = try? call(node, "condenser_api.get_accounts", "[[" + HiveJSON.string(account) + "]]"),
                   let list = res["result"] as? [[String: Any]], let first = list.first {
                    acc = first
                    break
                }
            }
            if let acc = acc {
                let hive = acc["reward_hive_balance"] as? String ?? "0.000 HIVE"
                let hbd = acc["reward_hbd_balance"] as? String ?? "0.000 HBD"
                let vests = acc["reward_vesting_balance"] as? String ?? "0.000000 VESTS"
                if isZero(hive) && isZero(hbd) && isZero(vests) {
                    r = Result(ok: true, txId: nil, refBlockNum: 0, operationsJson: nil, error: nil, ambiguous: false)
                } else {
                    r = run([.claimRewardBalance(account: account, rewardHive: hive, rewardHbd: hbd, rewardVests: vests)],
                            wif: storedPostingKey, role: .posting, onSigned: nil)
                }
            } else {
                r = .fail(HiveText.network)
            }
            DispatchQueue.main.async { completion(r) }
        }
    }

    // MARK: - Flow

    private static func run(_ ops: [HiveOp], wif: String, role: KeyRole, onSigned: ((Signed) -> Void)?) -> Result {
        guard !wif.isEmpty else { return .fail(role == .active ? HiveText.noActiveKey : HiveText.noPostingKey) }
        guard (try? HiveKeys.decodeWif(wif)) != nil else { return .fail(HiveText.badKey) }

        let opsJson = "[" + ops.map { $0.json }.joined(separator: ",") + "]"
        let key = role.rawValue + "|" + opsJson
        guard claim(key) else { return .fail(HiveText.inProgress) }
        defer { release(key) }
        if let earlier = pendingEntry(key) {
            if Date() > earlier.expiresAt.addingTimeInterval(reuseWindow(role)) {
                setPending(key, nil)   // long settled one way or the other: this is a new action
            } else {
                onSigned?(earlier)     // the caller stores what it settles
                if Date() < earlier.expiresAt {
                    // A previous attempt at exactly this action may already be on chain: re-send it.
                    return send(key: key, earlier, role: role, fresh: false)
                }
                let settled = settleExpired(key: key, earlier)
                if settled.ok {
                    // The earlier attempt did land. This tap may be a retry of it or a deliberate
                    // repeat (the same deposit again), and only the user knows which: say so
                    // rather than report this tap as sent. The record is cleared, so tapping
                    // again signs a new one.
                    return Result(ok: false, txId: nil, refBlockNum: 0, operationsJson: nil,
                                  error: HiveText.earlierLanded(settled.txId ?? ""), ambiguous: false)
                }
                if settled.ambiguous { return settled }
                // it never landed: sign afresh below
            }
        }

        // 1. A recent block to anchor the transaction (TaPoS), and the chain's clock.
        var dgp: [String: Any]?
        for node in nodes {
            if let res = try? call(node, "condenser_api.get_dynamic_global_properties", "[]"),
               let result = res["result"] as? [String: Any] {
                dgp = result
                break
            }
        }
        guard let props = dgp,
              let headBlock = (props["head_block_number"] as? NSNumber)?.uint64Value,
              let headId = props["head_block_id"] as? String,
              let time = (props["time"] as? String).flatMap(HiveTime.parse) else { return .fail(HiveText.network) }

        // 2. Sign on the device.
        let expiration = time + expirationSeconds
        let tx = HiveTransaction(headBlockNumber: headBlock, headBlockId: headId, expiration: expiration, operations: ops)
        guard let signature = try? HiveCrypto.sign(tx, wif: wif), let txId = try? tx.txId() else {
            return .fail(HiveText.generic)
        }
        let s = Signed(txJson: tx.json(signature: signature), txId: txId, refBlockNum: Int(tx.refBlockNum),
                       opsJson: tx.operationsJson,
                       // The expiration comes from the node's clock; never treat the transaction
                       // as expired (and re-signable) before the chain would.
                       expiresAt: max(Date().addingTimeInterval(TimeInterval(expirationSeconds)),
                                      Date(timeIntervalSince1970: TimeInterval(expiration))),
                       startBlock: headBlock, expirationSec: expiration)
        setPending(key, s)
        onSigned?(s)
        return send(key: key, s, role: role, fresh: true)
    }

    /// 3. Broadcast. Re-sending the SAME signed transaction is safe: the chain refuses a
    /// duplicate id. `fresh`: never sent before, so a refusal by every node proves it isn't on chain.
    private static func send(key: String?, _ s: Signed, role: KeyRole, fresh: Bool) -> Result {
        var unclear = false
        var refusal: String?
        // A node could relay the transaction and still answer "insufficient funds". For money
        // (active key) a refusal only counts once a second node refuses it too.
        let refusalsNeeded = role == .active ? min(2, nodes.count) : 1
        var refusals = 0
        for node in nodes {
            guard let res = try? call(node, "condenser_api.broadcast_transaction", "[" + s.txJson + "]") else {
                unclear = true   // the node may have taken it before the reply was lost
                continue
            }
            guard let error = res["error"] else {
                // Only a JSON-RPC result counts as accepted; any other body (a proxy or captive
                // portal page parsed as JSON) says nothing about the chain.
                if res["result"] != nil { return landed(key: key, s) }
                unclear = true
                continue
            }
            let msg = (error as? [String: Any])?["message"] as? String ?? "\(error)"
            let m = msg.lowercased()
            if m.contains("duplicate") { return landed(key: key, s) }   // already on chain
            if isDeterministicRefusal(m) {
                // Missing authority, resource credits, balance: no node could have accepted it,
                // but only for a transaction never sent before. A re-sent one may already be in
                // another node's queue (the balance may have changed since), so it stays open.
                guard fresh else { return ambiguousResult() }
                refusals += 1
                refusal = msg
                guard refusals >= refusalsNeeded else { continue }
                setPending(key, nil)
                return .fail(chainErrorText(msg, role: role))
            }
            // Anything else (an internal error, a proxy timeout, "expired") says nothing certain
            // about whether it landed: try the next node.
            unclear = unclear || !isAssert(m)
            refusal = msg
        }
        if fresh && !unclear && refusals == 0, let refusal = refusal {
            // Every node answered and refused it: it is not on chain.
            setPending(key, nil)
            return .fail(chainErrorText(refusal, role: role))
        }
        // Keep the signed tx: a retry re-sends it, or checks the chain once it expired.
        return ambiguousResult()
    }

    private static func ambiguousResult() -> Result {
        return Result(ok: false, txId: nil, refBlockNum: 0, operationsJson: nil, error: HiveText.unclear, ambiguous: true)
    }

    /// After expiry: did it get in? Re-signing is only allowed on a clear "not found".
    private static func settleExpired(key: String?, _ s: Signed) -> Result {
        switch lookup(s) {
        case .found: return landed(key: key, s)
        case .notFound:
            setPending(key, nil)
            return .fail(HiveText.network)
        case .unknown:
            return ambiguousResult()
        }
    }

    private static func landed(key: String?, _ s: Signed) -> Result {
        setPending(key, nil)
        return Result(ok: true, txId: s.txId, refBlockNum: s.refBlockNum, operationsJson: s.opsJson, error: nil, ambiguous: false)
    }

    private enum TxStatus { case found, notFound, unknown }

    /// found if a node has it. notFound only with proof: every block from signing until past the
    /// transaction's expiration (by chain time) was read and none holds it, that stretch is
    /// irreversible, and two nodes agree (one dishonest node can't talk the app into paying twice).
    /// unknown otherwise.
    private static func lookup(_ s: Signed) -> TxStatus {
        for node in nodes {
            if let res = try? call(node, "condenser_api.get_transaction", "[" + HiveJSON.string(s.txId) + "]"),
               let result = res["result"], !(result is NSNull) {
                return .found
            }
        }
        // get_transaction can lag (it is served from account history), so absence is proved from
        // the blocks themselves, and only from irreversible ones.
        guard s.startBlock > 0 else { return .unknown }
        let proofsNeeded = min(2, nodes.count)
        var proofs = 0
        for node in nodes {
            guard let props = (try? call(node, "condenser_api.get_dynamic_global_properties", "[]"))?["result"] as? [String: Any],
                  let lib = (props["last_irreversible_block_num"] as? NSNumber)?.uint64Value,
                  let res = try? call(node, "block_api.get_block_range",
                                      "{\"starting_block_num\":\(s.startBlock + 1),\"count\":\(scanBlocks)}"),
                  let blocks = (res["result"] as? [String: Any])?["blocks"] as? [[String: Any]] else { continue }
            for (i, block) in blocks.enumerated() {
                if (block["transaction_ids"] as? [String] ?? []).contains(s.txId) { return .found }
                if let ts = (block["timestamp"] as? String).flatMap(HiveTime.parse), ts > s.expirationSec {
                    // Every block that could hold it has been read; the proof stands once this
                    // one is irreversible.
                    if s.startBlock + 1 + UInt64(i) <= lib { proofs += 1 }
                    break
                }
            }
            if proofs >= proofsNeeded { return .notFound }
        }
        return .unknown
    }

    // MARK: - Errors

    private static func isDeterministicRefusal(_ m: String) -> Bool {
        return ["missing required posting authority", "missing required active authority", "missing authority",
                "rc mana", "not enough rc", "resource credit", "insufficient", "does not have sufficient funds"]
            .contains { m.contains($0) }
    }

    /// hived's own assertion failures, as opposed to a node or proxy problem.
    private static func isAssert(_ m: String) -> Bool {
        return m.contains("assert exception") || m.contains("exception:")
    }

    /// Turns the node's error into something a user can act on.
    static func chainErrorText(_ msg: String, role: KeyRole) -> String {
        let m = msg.lowercased()
        if m.contains("missing required posting authority") || m.contains("missing required active authority")
            || m.contains("missing authority") {
            return role == .active ? HiveText.wrongActiveKey : HiveText.wrongPostingKey
        }
        if m.contains("rc mana") || m.contains("not enough rc") || m.contains("resource credit") { return HiveText.rc }
        if m.contains("insufficient") || m.contains("does not have sufficient funds") { return HiveText.funds }
        return HiveText.generic
    }

    // MARK: - Plumbing

    private static func isZero(_ asset: String) -> Bool {
        return Double(asset.components(separatedBy: " ").first ?? "") ?? 0 == 0
    }

    private static func pendingEntry(_ key: String) -> Signed? {
        lock.lock(); defer { lock.unlock() }
        let all = UserDefaults.standard.dictionary(forKey: pendingKey) as? [String: Data] ?? [:]
        return all[key].flatMap { try? JSONDecoder().decode(Signed.self, from: $0) }
    }

    private static func setPending(_ key: String?, _ s: Signed?) {
        guard let key = key else { return }
        lock.lock(); defer { lock.unlock() }
        var all = UserDefaults.standard.dictionary(forKey: pendingKey) as? [String: Data] ?? [:]
        all[key] = s.flatMap { try? JSONEncoder().encode($0) }
        // Old settled-or-abandoned entries would only grow the store.
        let cutoff = Date().addingTimeInterval(-reuseWindow(.active) - 3600)
        all = all.filter { (try? JSONDecoder().decode(Signed.self, from: $0.value))?.expiresAt ?? .distantPast > cutoff }
        UserDefaults.standard.set(all, forKey: pendingKey)
    }

    private static func claim(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return inFlight.insert(key).inserted
    }

    private static func release(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        inFlight.remove(key)
    }

    /// A blocking JSON-RPC call (callers are always on a background queue).
    private static func call(_ node: String, _ method: String, _ paramsJson: String) throws -> [String: Any] {
        guard let url = URL(string: node) else { throw HiveError.signingFailed }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = ("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"\(method)\",\"params\":\(paramsJson)}").data(using: .utf8)
        var out: [String: Any]?
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data {
                out = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            }
            done.signal()
        }.resume()
        done.wait()
        guard let result = out else { throw HiveError.signingFailed }
        return result
    }
}

/// User-facing signing messages, under Android's signing_error_* keys.
enum HiveText {
    static var noPostingKey: String { return Copy.text("signing_error_no_posting_key", "Your posting key isn't saved on this phone. Log out and log in again to add it.") }
    static var noActiveKey: String { return Copy.text("signing_error_no_active_key", "This needs your active key. Add it under Settings first.") }
    static var badKey: String { return Copy.text("signing_error_bad_key", "The key saved on this phone isn't a valid Hive private key. Update it under Settings.") }
    static var network: String { return Copy.text("signing_error_network", "Couldn't reach the Hive network. Check your connection and try again.") }
    static var unclear: String { return Copy.text("signing_error_unclear", "We couldn't confirm this went through, and it may still land. Don't send it again yet: check your wallet history in a few minutes, and if it isn't there, tap again (the app re-sends the same transaction, it won't pay twice).") }
    static var inProgress: String { return Copy.text("gadget_action_in_progress", "This is still being processed. Please wait.") }
    static var wrongPostingKey: String { return Copy.text("signing_error_wrong_posting_key", "Your account's posting key has changed. Log out and log in again with the new key.") }
    static var wrongActiveKey: String { return Copy.text("signing_error_wrong_active_key", "The active key saved in Settings doesn't match your account. Update it and try again.") }
    static var rc: String { return Copy.text("signing_error_rc", "Your account is out of Resource Credits right now. Try again later.") }
    static var funds: String { return Copy.text("signing_error_funds", "Your account doesn't have enough HIVE for this.") }
    static var generic: String { return Copy.text("signing_error_generic", "The Hive network rejected this transaction. Please try again.") }
    static func earlierLanded(_ txId: String) -> String {
        return "An identical earlier transaction already went through (" + String(txId.prefix(12))
            + "…). Check your wallet history. To send it again, tap again."
    }
}
