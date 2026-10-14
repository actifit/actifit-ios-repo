//
//  FriendsLogicTests.swift
//  ActifitTests
//
//  Rules from the Android Friends brief: username validation, compact stats, plurals,
//  suggestion filtering and mutual friends.
//

import XCTest

final class FriendsLogicTests: XCTestCase {

    func testHandlesAreNormalisedAndValidated() {
        XCTAssertEqual(FriendsLogic.normalize("  @@Vevita "), "vevita")
        XCTAssertTrue(FriendsLogic.isValidUsername("vevita"))
        XCTAssertTrue(FriendsLogic.isValidUsername("jfang003-afit"))
        XCTAssertTrue(FriendsLogic.isValidUsername("felt.buzz"))
        XCTAssertFalse(FriendsLogic.isValidUsername("ab"))                 // too short
        XCTAssertFalse(FriendsLogic.isValidUsername("1abc"))               // starts with a digit
        XCTAssertFalse(FriendsLogic.isValidUsername("abc-"))               // ends with a dash
        XCTAssertFalse(FriendsLogic.isValidUsername("averyveryverylongname")) // over 16
        XCTAssertEqual(FriendsLogic.searchPrefix("@Ve\"vi ta"), "vevita")
    }

    func testCompactKeepsOneDecimal() {
        XCTAssertEqual(FriendsLogic.compact(999), "999")
        XCTAssertEqual(FriendsLogic.compact(1303), "1.3K")
        XCTAssertEqual(FriendsLogic.compact(44_573), "44.6K")   // not 45K
        XCTAssertEqual(FriendsLogic.compact(100_000), "100K")
        XCTAssertEqual(FriendsLogic.compact(2_100_000), "2.1M")
    }

    func testStatsUsePluralsAndOmitFailedParts() {
        XCTAssertEqual(FriendsText.reports(1), "1 report")
        XCTAssertEqual(FriendsText.mutual(1), "1 mutual friend")
        XCTAssertEqual(FriendsText.mutual(3), "3 mutual friends")
        var row = FriendRow(username: "a", kind: .suggested)
        XCTAssertNil(FriendsLogic.primaryStats(row))
        row.afit = 1234
        XCTAssertEqual(FriendsLogic.primaryStats(row), "1.2K AFIT")
        row.reports = 44_573
        XCTAssertEqual(FriendsLogic.primaryStats(row), "44.6K reports · 1.2K AFIT")
        row.reports = 0
        XCTAssertEqual(FriendsLogic.primaryStats(row), "0 reports · 1.2K AFIT")   // a real zero is shown
    }

    func testSuggestionCandidatesDropExcludedAndDuplicates() {
        let exclude: Set<String> = ["me", "friend", "pending"]
        XCTAssertEqual(FriendsLogic.usableCandidates(["friend", "a", "me", "b", "a", "", "pending"], excluding: exclude), ["a", "b"])
        // A source made only of excluded accounts yields nothing, so it can't win the race.
        XCTAssertTrue(FriendsLogic.usableCandidates(["friend", "me"], excluding: exclude).isEmpty)
    }

    func testParsingAndState() {
        let friends = FriendsLogic.friends(from: [["friend": "alice"], ["friend": ""], ["x": 1]])
        XCTAssertEqual(friends, ["alice"])
        let req = FriendsLogic.requests(from: ["received_pending": [["initiator": "sergey44"]], "sent_pending": [["target": "bob"]]])
        XCTAssertEqual(req.received, ["sergey44"])
        XCTAssertEqual(req.sent, ["bob"])
        XCTAssertEqual(FriendsLogic.state(of: "Alice", friends: friends, received: [], sent: []), .friends)
        XCTAssertEqual(FriendsLogic.state(of: "sergey44", friends: friends, received: req.received, sent: req.sent), .received)
        XCTAssertEqual(FriendsLogic.state(of: "bob", friends: friends, received: req.received, sent: req.sent), .sent)
        XCTAssertEqual(FriendsLogic.state(of: "zed", friends: friends, received: req.received, sent: req.sent), .none)
    }

    func testMutualFriendsAreTheIntersectionInTheirOrder() {
        XCTAssertEqual(FriendsLogic.mutualFriends(mine: ["a", "b", "c"], theirs: ["c", "x", "a", "c"]), ["c", "a"])
        XCTAssertTrue(FriendsLogic.mutualFriends(mine: [], theirs: ["a"]).isEmpty)
    }
}
