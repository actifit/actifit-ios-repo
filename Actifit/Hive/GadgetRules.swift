//
//  GadgetRules.swift
//  Actifit
//
//  The gadget operations, built exactly as the web builds them (components/Product.vue), and the
//  rules for reading the backend's confirm replies. Ported from Android's GadgetOps and
//  GadgetReply. Foundation only, so ActifitTests can pin them: the backend matches the signed
//  operation against the chain, so changing a string here changes what gets verified.
//

import Foundation

enum GadgetOps {

    static func buy(user: String, gadgetId: String) -> HiveOp {
        return .postingJson(account: user, id: "actifit",
                            json: "{\"transaction\": \"buy-gadget\", \"gadget\": \"\(gadgetId)\"}")
    }

    /// benefic: the friend receiving the boost, or empty.
    static func activate(user: String, gadgetId: String, benefic: String) -> HiveOp {
        let json = benefic.isEmpty
            ? "{\"transaction\": \"activate-gadget\" , \"gadget\": \"\(gadgetId)\"}"
            : "{\"transaction\": \"activate-gadget\" , \"gadget\": \"\(gadgetId)\", \"benefic\": \"\(benefic)\"}"
        return .postingJson(account: user, id: "actifit", json: json)
    }

    static func deactivate(user: String, gadgetId: String) -> HiveOp {
        return .postingJson(account: user, id: "actifit",
                            json: "{\"transaction\": \"deactivate-gadget\" , \"gadget\": \"\(gadgetId)\"}")
    }

    /// The AI workout fee; the backend charges the AFIT when it finds this on chain.
    static func generateWorkout(user: String) -> HiveOp {
        return .postingJson(account: user, id: "actifit", json: "{\"transaction\": \"generate-workout-wizard\"}")
    }

    /// amount: e.g. "12.346 HIVE" (see HiveAmount.format).
    static func buyWithHive(user: String, market: String, gadgetId: String, amount: String) -> HiveOp {
        return .transfer(from: user, to: market, amount: amount, memo: "buy-gadget:" + gadgetId)
    }
}

/// Reads the backend's reply to a gadget confirm call (buy / activate / deactivate).
enum GadgetReply {

    enum Kind: Equatable {
        case ok
        /// A key-rotation / try-again gate: show the server's own message.
        case gate
        case insufficientAfit
        /// Another AFIT action for this account is in flight; nothing was charged.
        case busy
        /// The product can't be bought (gone, not a gadget, bad price); nothing was charged.
        case unavailable
        /// Session missing or expired (the backend answers 200 with success:false).
        case session
        case failed
    }

    private static let gateCodes = ["KEY_ROTATION_REQUIRED", "KEY_ROTATION_HOLD", "KEY_ROTATION_RECOMMENDED", "TRY_AGAIN"]

    static func classify(_ reply: [String: Any]) -> Kind {
        let err = reply["error"]
        let hasError = err != nil && !(err is NSNull) && !((err as? Bool) == false)
        return classify(hasError: hasError, error: err as? String ?? "", status: reply["status"] as? String ?? "",
                        success: reply["success"] as? Bool, code: reply["code"] as? String ?? "")
    }

    static func classify(hasError: Bool, error: String, status: String, success: Bool?, code: String) -> Kind {
        if gateCodes.contains(code) { return .gate }
        // Allowlist: every gadget route answers {status:'Success'} or {status:'success'} when it
        // worked. Anything else, including an empty object, is not a success.
        if !hasError && (status.lowercased() == "success" || (status.isEmpty && success == true)) { return .ok }
        let e = error.lowercased()
        if e.contains("not have enough afit funds") { return .insufficientAfit }
        if e.contains("afit transaction for this account is being processed") { return .busy }
        if ["product not found", "product is not an in-game gadget", "product cannot be bought",
            "product price is not valid"].contains(where: { e.hasPrefix($0) }) { return .unavailable }
        if success == false && !hasError && status != "error" { return .session }
        return .failed
    }

    /// The server has already used this transaction id and won't process it again.
    static func alreadyProcessed(_ error: String) -> Bool {
        let e = error.lowercased()
        return e.contains("trx already exists") || e.contains("transaction already verified")
    }
}
