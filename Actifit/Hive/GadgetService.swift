//
//  GadgetService.swift
//  Actifit
//
//  Gadget buy (AFIT or HIVE), activate and deactivate. Each action is signed and broadcast on
//  the device (HiveBroadcaster), then confirmed by the backend's *Keychain route, which finds the
//  transaction on the chain, checks its operations match the ?operation= sent, and ties it to the
//  gadget. Ported from Android's GadgetApi.
//
//  Money safety:
//   - The signed transaction is saved (per user, gadget and action) BEFORE it is sent, and kept
//     until the backend confirms it. Tapping again, or reopening the Market, settles that same
//     transaction (re-sends it, checks the chain, or re-confirms it) instead of signing a new
//     one, so a lost reply or a killed app can never become a second payment.
//   - While any purchase of a gadget is unresolved, every buy button of that gadget settles it
//     rather than starting another purchase.
//   - Paying in HIVE moves funds BEFORE the confirm. The backend answers a bare {status:'error'}
//     for every confirm failure (including "this tx was already used"), so a HIVE payment is only
//     forgotten on an explicit success; until then the user is shown the transaction id and told
//     not to pay again.
//   - Only one action per gadget at a time.
//

import Foundation

enum GadgetService {

    /// Main queue. message is user-facing; nil on success.
    typealias Done = (_ ok: Bool, _ message: String?) -> Void

    private enum Action: String {
        case buy, buyHive = "buyhive", activate, deactivate
        var role: HiveBroadcaster.KeyRole { return self == .buyHive ? .active : .posting }
    }

    static let marketAccount = "actifit.market"
    private static let base = "https://api.actifit.io/"
    /// Head-room over the quoted rate, so a price refresh on the server between quote and confirm
    /// can't make an honest payment fall short.
    private static let hivePriceBuffer = 1.005
    /// The server accepts a transaction for 7 hours; stop re-confirming a little before.
    private static let pendingMaxAge: TimeInterval = 6 * 60 * 60
    private static let defaultsKey = "gadgetPending"

    private static let queue = DispatchQueue(label: "io.actifit.gadgets", attributes: .concurrent)
    private static let lock = NSLock()
    private static var inFlight = Set<String>()

    // MARK: - Public

    /// True while any action for this gadget is running: the card keeps its buttons off.
    static func isBusy(user: String, gadgetId: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return inFlight.contains(user + "|" + gadgetId)
    }

    /// A purchase of this gadget (AFIT or HIVE) is signed but not yet confirmed: a buy tap should
    /// settle it instead of starting another.
    static func hasUnresolvedPurchase(user: String, gadgetId: String) -> Bool {
        return unresolvedBuyKey(user: user, gadgetId: gadgetId) != nil
    }

    /// The HIVE to pay for a gadget priced in AFIT at the given AFIT→HIVE rate, rounded up.
    static func hivePrice(priceAfit: Double, rate: Double) -> String? {
        let raw = priceAfit * rate * hivePriceBuffer
        guard raw > 0, raw.isFinite else { return nil }
        return try? HiveAmount.format((raw * 1000).rounded(.up) / 1000, symbol: "HIVE")
    }

    static func buyWithAfit(user: String, gadgetId: String, done: @escaping Done) {
        start(.buy, user: user, gadgetId: gadgetId, op: GadgetOps.buy(user: user, gadgetId: gadgetId),
              url: base + "buyGadgetKeychain/" + enc(user) + "/" + enc(gadgetId) + "/{tx}/HIVE", key: nil, done: done)
    }

    /// Pays `amount` ("12.346 HIVE") with the active key, then confirms. amount nil: only settle
    /// an unresolved purchase (see hasUnresolvedPurchase).
    static func buyWithHive(user: String, gadgetId: String, amount: String?, activeKey: String, done: @escaping Done) {
        start(.buyHive, user: user, gadgetId: gadgetId,
              op: amount.map { GadgetOps.buyWithHive(user: user, market: marketAccount, gadgetId: gadgetId, amount: $0) },
              url: base + "buyGadgetHiveKeychain/" + enc(user) + "/" + enc(gadgetId) + "/{tx}/HIVE", key: activeKey, done: done)
    }

    /// benefic: the friend receiving the boost, or empty.
    static func activate(user: String, gadgetId: String, benefic: String, done: @escaping Done) {
        let b = benefic.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces).lowercased()
        guard b.isEmpty || FriendsLogic.isValidUsername(b) else {
            return done(false, Copy.text("gadget_bad_benefic", "Enter a valid Hive username for the friend to reward."))
        }
        start(.activate, user: user, gadgetId: gadgetId, op: GadgetOps.activate(user: user, gadgetId: gadgetId, benefic: b),
              url: base + "activateGadgetKeychain/" + enc(user) + "/" + enc(gadgetId) + "/{tx}/HIVE/" + enc(b), key: nil, done: done)
    }

    static func deactivate(user: String, gadgetId: String, done: @escaping Done) {
        start(.deactivate, user: user, gadgetId: gadgetId, op: GadgetOps.deactivate(user: user, gadgetId: gadgetId),
              url: base + "deactivateGadgetKeychain/" + enc(user) + "/" + enc(gadgetId) + "/{tx}/HIVE", key: nil, done: done)
    }

    /// Settles every remembered action for this user (e.g. a HIVE payment whose confirm never got
    /// through because the app was closed). done runs once per action that ended.
    static func resumePending(user: String, done: @escaping Done) {
        for key in all().keys {
            let parts = key.components(separatedBy: "|")
            guard parts.count == 3, parts[1] == user, let action = Action(rawValue: parts[0]) else { continue }
            let lockKey = user + "|" + parts[2]
            guard claim(lockKey) else { continue }
            queue.async {
                let message = settle(key: key, action: action, pending: load(key))
                release(lockKey)
                DispatchQueue.main.async { done(message == nil, message) }
            }
        }
    }

    /// The Market shows this gadget as owned, so any purchase of it still on record has gone
    /// through (the buy buttons are hidden while a copy is owned): stop re-confirming it.
    static func clearSettledPurchase(user: String, gadgetId: String) {
        guard !isBusy(user: user, gadgetId: gadgetId) else { return }
        while let key = unresolvedBuyKey(user: user, gadgetId: gadgetId) { forget(key) }
    }

    // MARK: - Flow

    private static func start(_ action: Action, user: String, gadgetId: String, op: HiveOp?, url: String,
                              key activeKey: String?, done: @escaping Done) {
        // The gadget id and beneficiary go into the signed JSON as is (it must match the web byte
        // for byte), so only plain ids and Hive account names are accepted.
        guard gadgetId.range(of: "^[0-9a-f]{24}$", options: .regularExpression) != nil else {
            return done(false, GadgetText.failed)
        }
        let lockKey = user + "|" + gadgetId
        guard claim(lockKey) else { return done(false, GadgetText.inProgress) }
        let isBuy = action == .buy || action == .buyHive
        queue.async {
            var message: String?
            // An earlier attempt is unresolved: settle THAT one, don't start another. For a buy,
            // either currency's purchase counts, so the other button can't buy twice.
            let key = isBuy ? unresolvedBuyKey(user: user, gadgetId: gadgetId) : action.rawValue + "|" + user + "|" + gadgetId
            var earlier = key.flatMap(load)
            if let k = key, let e = earlier, expired(e), !isHiveBuy(k) {
                forget(k)   // nothing was charged and the server won't take it any more
                earlier = nil
            }
            if let k = key, let e = earlier {
                message = settle(key: k, action: Action(rawValue: k.components(separatedBy: "|")[0]) ?? action, pending: e)
                // An activation naming a different friend: the earlier one is what went through.
                if message == nil && !isBuy && e.url != url { message = GadgetText.earlierActivation }
            } else if let k = key, isHiveBuy(k), all()[k] != nil {
                message = dropUnreadable(k)   // a HIVE payment record we can't read: report it, don't pay
            } else if let op = op {
                message = signSendConfirm(key: action.rawValue + "|" + user + "|" + gadgetId, action: action, op: op,
                                          url: url, activeKey: activeKey)
            } else {
                message = GadgetText.failed   // nothing left to settle
            }
            release(lockKey)
            DispatchQueue.main.async { done(message == nil, message) }
        }
    }

    /// A fresh action. Blocking; nil on success, else a user-facing message.
    private static func signSendConfirm(key: String, action: Action, op: HiveOp, url: String, activeKey: String?) -> String? {
        let r = HiveBroadcaster.signAndSend([op], role: action.role, explicitKey: activeKey) { signed in
            // Saved BEFORE sending: if the reply is lost or the app dies, it is settled later.
            save(key, Pending(signed: signed, url: url, created: signed.expiresAt.addingTimeInterval(-120), sent: false))
        }
        guard r.ok else {
            if !r.ambiguous {
                forget(key)   // it never reached the chain: nothing to settle
                return r.error
            }
            return load(key).map { GadgetText.stillChecking($0.signed.txId) } ?? r.error
        }
        guard var p = load(key) else { return GadgetText.failed }
        p.sent = true
        save(key, p)
        return confirmAndSettle(key: key, pending: p, resumed: false)
    }

    /// An unresolved action from an earlier attempt. Blocking.
    private static func settle(key: String, action: Action, pending: Pending?) -> String? {
        let hive = isHiveBuy(key)
        guard var p = pending else {
            if hive { return dropUnreadable(key) }
            forget(key)
            return nil
        }
        if expired(p) {
            // Past the server's window: it can no longer confirm this. Never drop a HIVE payment
            // silently (even one never seen accepted, it may have landed): the user needs the id.
            forget(key)
            return hive ? GadgetText.hiveExpired(p.signed.txId) : nil
        }
        if !p.sent {
            let r = HiveBroadcaster.resend(p.signed, role: action.role)
            if !r.ok {
                if r.ambiguous { return GadgetText.stillChecking(p.signed.txId) }
                forget(key)   // it never landed: nothing was paid
                return GadgetText.previousNotLanded
            }
            p.sent = true
            save(key, p)
        }
        return confirmAndSettle(key: key, pending: p, resumed: true)
    }

    /// Confirms a broadcast action and decides whether to keep remembering it. Blocking.
    private static func confirmAndSettle(key: String, pending p: Pending, resumed: Bool) -> String? {
        let paidOnChain = isHiveBuy(key)
        // The routes read the chain from ?bchain= while the verifier uses the path one: send both.
        let url = p.url.replacingOccurrences(of: "{tx}", with: enc(p.signed.txId)) + "?bchain=HIVE&operation=" + enc(p.signed.opsJson)
        var reply: [String: Any]?
        var retried = false
        // One retry, only when no JSON came back at all (a dropped connection, a proxy's HTML
        // timeout page). Safe: the server refuses to process the same transaction twice.
        for attempt in 0..<2 where reply == nil {
            retried = attempt > 0
            reply = confirmCall(url)
        }
        guard let doc = reply else {
            // keep it: confirm again later
            return paidOnChain ? GadgetText.hiveUnconfirmed(p.signed.txId) : GadgetText.confirmUnknown(p.signed.txId)
        }
        let kind = GadgetReply.classify(doc)
        if kind == .ok {
            forget(key)
            return nil
        }
        let errText = doc["error"] as? String ?? ""
        if paidOnChain {
            // The HIVE has moved whatever the server said. Its failure reply can't tell "already
            // bought with this payment" from "failed after taking it", so keep the payment on
            // record (until the server's window closes) and never let the user pay again.
            if kind == .gate { return gateMessage(doc) }
            return resumed || retried ? GadgetText.hiveNeedsSupport(p.signed.txId) : GadgetText.hiveUnconfirmed(p.signed.txId)
        }
        if GadgetReply.alreadyProcessed(errText) || ((resumed || retried) && kind == .failed) {
            // The server has already used this transaction (most likely an earlier attempt of
            // ours went through). It won't process it again, so stop retrying it.
            forget(key)
            return GadgetText.alreadyProcessed(p.signed.txId)
        }
        // AFIT is only charged when the confirm succeeds; none of these charged anything.
        forget(key)
        switch kind {
        case .gate: return gateMessage(doc)
        case .insufficientAfit: return GadgetText.insufficientAfit
        case .busy: return GadgetText.busy
        case .unavailable: return key.hasPrefix(Action.activate.rawValue + "|") ? GadgetText.activateUnavailable : GadgetText.buyUnavailable
        case .session: return GadgetText.sessionExpired
        default: return GadgetText.failed
        }
    }

    // MARK: - Records

    /// A signed action awaiting its confirm. sent: a node has accepted it.
    private struct Pending: Codable {
        let signed: HiveBroadcaster.Signed
        let url: String
        let created: Date
        var sent: Bool
    }

    private static func all() -> [String: Data] {
        return UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Data] ?? [:]
    }

    private static func load(_ key: String) -> Pending? {
        return all()[key].flatMap { try? JSONDecoder().decode(Pending.self, from: $0) }
    }

    private static func save(_ key: String, _ p: Pending) {
        guard let data = try? JSONEncoder().encode(p) else { return }
        lock.lock(); defer { lock.unlock() }
        var d = all()
        d[key] = data
        UserDefaults.standard.set(d, forKey: defaultsKey)
    }

    private static func forget(_ key: String) {
        if let p = load(key) { HiveBroadcaster.forget(role: isHiveBuy(key) ? .active : .posting, opsJson: p.signed.opsJson) }
        lock.lock(); defer { lock.unlock() }
        var d = all()
        d[key] = nil
        UserDefaults.standard.set(d, forKey: defaultsKey)
    }

    /// Drops a record that can't be read; for a HIVE payment, tells the user to contact support.
    private static func dropUnreadable(_ key: String) -> String {
        forget(key)
        return GadgetText.hiveNeedsSupport("?")
    }

    /// The stored key of an unresolved purchase of this gadget (HIVE first), or nil.
    private static func unresolvedBuyKey(user: String, gadgetId: String) -> String? {
        let d = all()
        for action in [Action.buyHive, Action.buy] {
            let key = action.rawValue + "|" + user + "|" + gadgetId
            if d[key] != nil { return key }
        }
        return nil
    }

    private static func isHiveBuy(_ key: String) -> Bool { return key.hasPrefix(Action.buyHive.rawValue + "|") }

    private static func expired(_ p: Pending) -> Bool { return Date().timeIntervalSince(p.created) > pendingMaxAge }

    private static func claim(_ lockKey: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return inFlight.insert(lockKey).inserted
    }

    private static func release(_ lockKey: String) {
        lock.lock(); defer { lock.unlock() }
        inFlight.remove(lockKey)
    }

    private static func gateMessage(_ doc: [String: Any]) -> String {
        let m = (doc["message"] as? String) ?? (doc["error"] as? String) ?? ""
        return m.trimmingCharacters(in: .whitespaces).isEmpty ? GadgetText.failed : m
    }

    /// The confirm routes poll the chain for up to 150 s before answering, so wait longer than
    /// that: a client timeout first would abandon a purchase the server then completes.
    private static func confirmCall(_ urlString: String) -> [String: Any]? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 175)
        request.addBroadCastHeaderWhenAfitSent()
        var out: [String: Any]?
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            out = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            done.signal()
        }.resume()
        done.wait()
        return out
    }

    private static func enc(_ s: String) -> String { return HiveURL.component(s) }
}

/// Gadget messages, under Android's gadget_* keys.
enum GadgetText {
    static var inProgress: String { return Copy.text("gadget_action_in_progress", "This is still being processed. Please wait.") }
    static var failed: String { return Copy.text("error_performing_operation", "Something went wrong. Refresh your balance and gadgets before trying again.") }
    static var previousNotLanded: String { return Copy.text("gadget_previous_not_landed", "Your earlier attempt never reached the chain, so nothing was charged. Tap again to retry.") }
    static var insufficientAfit: String { return Copy.text("gadget_buy_insufficient_afit", "You don't have enough AFIT for this. You were not charged.") }
    static var busy: String { return Copy.text("gadget_buy_busy", "Another AFIT action is in progress. Wait a moment and try again; you were not charged.") }
    static var activateUnavailable: String { return Copy.text("gadget_activate_unavailable", "This gadget can't be activated right now. Refresh the market to see its current state.") }
    static var buyUnavailable: String { return Copy.text("gadget_buy_unavailable", "This gadget can't be bought right now. You were not charged.") }
    static var sessionExpired: String { return Copy.text("gadget_session_expired", "Your session has expired. Log out and log in again, then retry.") }
    static func stillChecking(_ tx: String) -> String {
        return Copy.format("gadget_still_checking", "Still checking whether your earlier transaction (%1$@) reached the chain. Please try again in a couple of minutes.", tx)
    }
    static func confirmUnknown(_ tx: String) -> String {
        return Copy.format("gadget_confirm_unknown", "Your transaction reached the chain (%1$@) but its result isn't confirmed yet. Tap the same button again later to re-check it; it won't be signed twice.", tx)
    }
    static func alreadyProcessed(_ tx: String) -> String {
        return Copy.format("gadget_already_processed", "This transaction (%1$@) was already processed. Refresh your gadgets to see the result.", tx)
    }
    static func hiveUnconfirmed(_ tx: String) -> String {
        return Copy.format("gadget_hive_unconfirmed", "Your HIVE payment is on chain (%1$@) but the purchase isn't confirmed yet. Don't pay again: the app will re-check it when you reopen the market, or tap Buy again to retry the confirmation.", tx)
    }
    static func hiveNeedsSupport(_ tx: String) -> String {
        return Copy.format("gadget_hive_needs_support", "Your HIVE payment (%1$@) is on chain but the server didn't confirm the purchase. If the gadget now shows as bought, you're all set. Otherwise don't pay again: contact Actifit support with this transaction id.", tx)
    }
    static func hiveExpired(_ tx: String) -> String {
        return Copy.format("gadget_hive_expired", "An earlier HIVE payment (%1$@) could not be confirmed in time. If you don't own that gadget, contact Actifit support with this transaction id.", tx)
    }
    static func hiveConfirm(amount: String, gadget: String) -> String {
        return Copy.format("gadget_hive_confirm_msg", "Pay %1$@ to buy %2$@? This is a transfer signed with your active key.", amount, gadget)
    }
    static var earlierActivation: String { return "Your earlier request for this gadget went through, with the friend you chose then. Refresh your gadgets to see it." }
    static var hiveConfirmTitle: String { return Copy.text("gadget_hive_confirm_title", "Buy with HIVE") }
    static var hiveConfirmPay: String { return Copy.text("gadget_hive_confirm_pay", "Pay") }
}
