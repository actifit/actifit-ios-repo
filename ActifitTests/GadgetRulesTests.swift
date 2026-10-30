//
//  GadgetRulesTests.swift
//  ActifitTests
//
//  Mirrors Android's GadgetTest: the operations must stay what the web signs, and the confirm
//  replies must be read the same way.
//

import XCTest

final class GadgetRulesTests: XCTestCase {

    private func opsJson(_ op: HiveOp) -> String {
        return HiveTransaction(refBlockNum: 1, refBlockPrefix: 1, expiration: 0, operations: [op]).operationsJson
    }

    private func json(_ op: HiveOp) -> String {
        if case let .customJson(_, _, _, json) = op { return json }
        return ""
    }

    func testBuyMatchesTheWebOperation() {
        XCTAssertEqual(opsJson(GadgetOps.buy(user: "alice", gadgetId: "g1")),
                       "[[\"custom_json\",{\"required_auths\":[],\"required_posting_auths\":[\"alice\"],\"id\":\"actifit\","
                        + "\"json\":\"{\\\"transaction\\\": \\\"buy-gadget\\\", \\\"gadget\\\": \\\"g1\\\"}\"}]]")
    }

    func testActivateCarriesTheBeneficiaryOnlyWhenGiven() {
        XCTAssertEqual(json(GadgetOps.activate(user: "alice", gadgetId: "g1", benefic: "")),
                       "{\"transaction\": \"activate-gadget\" , \"gadget\": \"g1\"}")
        XCTAssertEqual(json(GadgetOps.activate(user: "alice", gadgetId: "g1", benefic: "bob")),
                       "{\"transaction\": \"activate-gadget\" , \"gadget\": \"g1\", \"benefic\": \"bob\"}")
    }

    func testDeactivateMatchesTheWebOperation() {
        XCTAssertEqual(json(GadgetOps.deactivate(user: "alice", gadgetId: "g1")),
                       "{\"transaction\": \"deactivate-gadget\" , \"gadget\": \"g1\"}")
    }

    func testHiveBuyIsATransferToTheMarketWithTheGadgetMemo() throws {
        XCTAssertEqual(opsJson(GadgetOps.buyWithHive(user: "alice", market: "actifit.market", gadgetId: "g1",
                                                     amount: try HiveAmount.format(12.3456, symbol: "HIVE"))),
                       "[[\"transfer\",{\"from\":\"alice\",\"to\":\"actifit.market\",\"amount\":\"12.346 HIVE\",\"memo\":\"buy-gadget:g1\"}]]")
    }

    func testOnlyAnExplicitSuccessCounts() {
        XCTAssertEqual(GadgetReply.classify(["status": "success"]), .ok)
        XCTAssertEqual(GadgetReply.classify(["status": "Success"]), .ok)
        XCTAssertEqual(GadgetReply.classify(["success": true]), .ok)
        XCTAssertEqual(GadgetReply.classify([:]), .failed)
        XCTAssertEqual(GadgetReply.classify(["status": "failed"]), .failed)
        XCTAssertEqual(GadgetReply.classify(["status": "error"]), .failed)   // on-chain verification failed
    }

    func testSuccessFalseWithoutDetailIsAnExpiredSession() {
        XCTAssertEqual(GadgetReply.classify(["success": false]), .session)
    }

    func testKeyRotationGatesWin() {
        XCTAssertEqual(GadgetReply.classify(["success": false, "code": "KEY_ROTATION_HOLD"]), .gate)
        XCTAssertEqual(GadgetReply.classify(["error": "x", "code": "KEY_ROTATION_RECOMMENDED"]), .gate)
    }

    func testKnownRefusalsAreNamed() {
        XCTAssertEqual(GadgetReply.classify(["error": "User does not have enough AFIT funds to buy this gadget"]), .insufficientAfit)
        XCTAssertEqual(GadgetReply.classify(["error": "Another AFIT transaction for this account is being processed. Please try again in a moment."]), .busy)
        XCTAssertEqual(GadgetReply.classify(["error": "Product not found"]), .unavailable)
        XCTAssertEqual(GadgetReply.classify(["error": "Error performing buy action"]), .failed)
        XCTAssertEqual(GadgetReply.classify(["error": "trx already exists"]), .failed)
    }

    func testAlreadyProcessedIsRecognised() {
        XCTAssertTrue(GadgetReply.alreadyProcessed("trx already exists"))
        XCTAssertTrue(GadgetReply.alreadyProcessed("Transaction already verified"))
        XCTAssertFalse(GadgetReply.alreadyProcessed("Product not found"))
    }
}
