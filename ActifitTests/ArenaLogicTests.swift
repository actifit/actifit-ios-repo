//
//  ArenaLogicTests.swift
//  ActifitTests
//
//  Mirrors Android's ArenaLogicTest.java case for case, plus the parsing and copy checks the
//  iOS port adds. The target that runs it is created by ci_scripts/add_unittest_target.rb.
//

import XCTest

final class ArenaLogicTests: XCTestCase {

    private let day: TimeInterval = 86400
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let epoch = Date(timeIntervalSince1970: 0)

    func testJoinableOnlyWhileOpenOrActive() {
        XCTAssertTrue(ArenaLogic.isJoinable("open"))
        XCTAssertTrue(ArenaLogic.isJoinable("active"))
        XCTAssertFalse(ArenaLogic.isJoinable("settled"))
        XCTAssertFalse(ArenaLogic.isJoinable("some_future_state"))
        XCTAssertFalse(ArenaLogic.isJoinable(nil))
    }

    func testArtPrefersTheChallengeKeyThenFallsBackByType() {
        XCTAssertEqual(ArenaLogic.artKey(art: "weekend-warrior", type: "liveops"), "weekend-warrior")
        XCTAssertEqual(ArenaLogic.artKey(art: nil, type: "daily_focus"), "daily-focus")
        XCTAssertEqual(ArenaLogic.artKey(art: "", type: "liveops"), "monthly-event")
        XCTAssertEqual(ArenaLogic.artKey(art: nil, type: "duel"), "step-league")
        XCTAssertEqual(ArenaLogic.artURL(art: nil, type: nil)?.absoluteString, "https://actifit.io/img/arena/step-league.webp")
    }

    func testArtKeyThatCouldEscapeTheImageFolderIsIgnored() {
        XCTAssertEqual(ArenaLogic.artKey(art: "../../evil", type: "league_fixture"), "step-league")
        XCTAssertEqual(ArenaLogic.artKey(art: "a/b", type: nil), "step-league")
    }

    func testParsesBothTimestampShapesTheApiSends() {
        XCTAssertEqual(ArenaLogic.parseDate("2026-09-23T13:06:26.509Z")!.timeIntervalSince1970, 1790168786.509, accuracy: 0.001)
        XCTAssertEqual(ArenaLogic.parseDate("2026-09-23T13:06:30")!.timeIntervalSince1970, 1790168790, accuracy: 0.001)
        XCTAssertNil(ArenaLogic.parseDate("not a date"))
        XCTAssertNil(ArenaLogic.parseDate(nil))
    }

    func testDurationUsesTheWebThresholds() {
        func d(_ days: Double) -> (ArenaLogic.DurationUnit, Int)? {
            return ArenaLogic.duration(start: epoch, end: epoch.addingTimeInterval(days * day)).map { ($0.unit, $0.count) }
        }
        XCTAssertTrue(d(1)! == (.days, 1))
        XCTAssertTrue(d(2)! == (.days, 2))
        XCTAssertTrue(d(7)! == (.days, 7))
        XCTAssertTrue(d(14)! == (.weeks, 2))
        XCTAssertTrue(d(30)! == (.months, 1))
        XCTAssertNil(ArenaLogic.duration(start: epoch.addingTimeInterval(day), end: epoch.addingTimeInterval(day)))
        XCTAssertNil(ArenaLogic.duration(start: nil, end: epoch.addingTimeInterval(day)))
    }

    func testRemainingBreaksDownAndClampsAtZero() {
        let end = now.addingTimeInterval(day + 5 * 3600 + 12 * 60)
        XCTAssertTrue(ArenaLogic.remaining(until: end, now: now) == (1, 5, 12))
        XCTAssertTrue(ArenaLogic.remaining(until: now.addingTimeInterval(-1), now: now) == (0, 0, 0))
        XCTAssertTrue(ArenaLogic.remaining(until: nil, now: now) == (0, 0, 0))
        XCTAssertTrue(ArenaLogic.hasEnded(now, now: now))
        XCTAssertFalse(ArenaLogic.hasEnded(nil, now: now))
    }

    func testCountdownBreaksDownToTheSecondAndClampsAtZero() {
        let end = now.addingTimeInterval(2 * day + 4 * 3600 + 12 * 60 + 9)
        XCTAssertTrue(ArenaLogic.countdown(until: end, now: now) == (2, 4, 12, 9))
        XCTAssertTrue(ArenaLogic.countdown(until: now.addingTimeInterval(59.999), now: now) == (0, 0, 0, 59))
        XCTAssertTrue(ArenaLogic.countdown(until: now, now: now) == (0, 0, 0, 0))
        XCTAssertTrue(ArenaLogic.countdown(until: now.addingTimeInterval(-1), now: now) == (0, 0, 0, 0))
        XCTAssertTrue(ArenaLogic.countdown(until: nil, now: now) == (0, 0, 0, 0))
    }

    func testMembershipFollowsTheServerWhenNothingIsPending() {
        XCTAssertEqual(ArenaLogic.membership(serverJoined: true, op: nil, at: epoch, now: now), .joined)
        XCTAssertEqual(ArenaLogic.membership(serverJoined: false, op: nil, at: epoch, now: now), .notJoined)
    }

    func testFreshJoinShowsAsPendingUntilTheServerCatchesUp() {
        let recent = now.addingTimeInterval(-10)
        XCTAssertEqual(ArenaLogic.membership(serverJoined: false, op: .join, at: recent, now: now), .pendingJoin)
        // indexed: the server row now exists
        XCTAssertEqual(ArenaLogic.membership(serverJoined: true, op: .join, at: recent, now: now), .joined)
        XCTAssertTrue(ArenaLogic.pendingConfirmed(serverJoined: true, op: .join))
    }

    func testFreshLeaveShowsAsPendingUntilTheServerCatchesUp() {
        let recent = now.addingTimeInterval(-10)
        XCTAssertEqual(ArenaLogic.membership(serverJoined: true, op: .leave, at: recent, now: now), .pendingLeave)
        XCTAssertEqual(ArenaLogic.membership(serverJoined: false, op: .leave, at: recent, now: now), .notJoined)
    }

    func testUnconfirmedJoinStopsBeingTrustedAfterTheTtl() {
        let old = now.addingTimeInterval(-ArenaLogic.pendingTTL)
        XCTAssertTrue(ArenaLogic.pendingExpired(serverJoined: false, op: .join, at: old, now: now))
        XCTAssertEqual(ArenaLogic.membership(serverJoined: false, op: .join, at: old, now: now), .notJoined)
        // a confirmed op is never "expired", however old
        XCTAssertFalse(ArenaLogic.pendingExpired(serverJoined: true, op: .join, at: old, now: now))
        XCTAssertFalse(ArenaLogic.pendingExpired(serverJoined: false, op: nil, at: old, now: now))
    }

    func testCatalogKindCoversKnownTypesAndDefaultsTheRest() {
        XCTAssertEqual(ArenaLogic.kind(of: "league_fixture"), .league)
        XCTAssertEqual(ArenaLogic.kind(of: "daily_focus"), .daily)
        XCTAssertEqual(ArenaLogic.kind(of: "liveops"), .event)
        XCTAssertEqual(ArenaLogic.kind(of: "brawl"), .other)
        XCTAssertEqual(ArenaLogic.kind(of: nil), .other)
    }

    func testChallengeIdFromNotificationLinks() {
        XCTAssertEqual(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena/def_weekly_step_league"), "def_weekly_step_league")
        XCTAssertEqual(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena/def_daily_focus%402026-10-13"), "def_daily_focus@2026-10-13")
        XCTAssertEqual(ArenaLogic.challengeId(fromURL: "https://www.actifit.io/arena/ch_x/?ref=push"), "ch_x")
        XCTAssertEqual(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena/ch_x#top"), "ch_x")
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena/"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://actifit.io/arena/create"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://actifit.io/mcfarhat/wallet"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://evil.example/arena/ch_x"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: "https://actifit.io.evil.example/arena/ch_x"))
        XCTAssertNil(ArenaLogic.challengeId(fromURL: nil))
        XCTAssertEqual(ArenaLogic.challengeId(fromURL: " https://actifit.io/arena/ch_x\n"), "ch_x")
    }

    func testUserCreatedChallengesAndBadgesAreMarkedCommunity() {
        var c = ArenaChallenge(json: ["id": "ch_a", "origin_tier": "community"])
        XCTAssertEqual(c.tierText, ArenaText.community)
        c.originTier = "official"
        XCTAssertNil(c.tierText)
        c.originTier = ""
        XCTAssertNil(c.tierText)
        XCTAssertEqual(ArenaText.badgeRow("Focus", "", community: true), "Focus · Community")
        XCTAssertEqual(ArenaText.badgeRow("Focus", "Daily Focus Goal", community: false), "Focus · Daily Focus Goal")
    }

    // MARK: - iOS additions

    func testGapIsMeasuredToTheNearestBetterRankNotATiedRow() {
        let rows = [row("a", 1, 900), row("b", 2, 500), row("c", 2, 500), row("me", 2, 500), row("d", 5, 10)]
        let s = ArenaLogic.standing(of: "me", in: rows)!
        XCTAssertEqual(s.mine.rank, 2)
        XCTAssertEqual(s.ahead?.entity, "a")
        XCTAssertNil(ArenaLogic.standing(of: "a", in: rows)!.ahead)
        XCTAssertNil(ArenaLogic.standing(of: "nobody", in: rows))
        XCTAssertNil(ArenaLogic.standing(of: "", in: rows))
    }

    func testDetailParsingCountsActiveParticipantsAndTheViewer() {
        let doc: [String: Any] = [
            "challenge": [
                "id": "def_daily_focus@2026-10-13", "type": "daily_focus", "state": "open", "title": "Daily Focus Goal",
                "window": ["start": "2026-10-13T00:00:00.000Z", "end": "2026-10-14T00:00:00"],
                "scoring": ["metric": "goal_hit", "rule": "threshold", "threshold": 5000],
                "rewards": ["badges": ["Focus", ""], "summary": "Badge for every finisher"]
            ],
            "participants": [
                ["entity": "alice", "state": "enrolled", "result": NSNull()],
                ["entity": "me", "state": "left"],
                ["entity": "bob", "state": "enrolled", "result": ["rank": 1, "reward": ["afit": 12.5, "badges": ["Focus"]]]]
            ]
        ]
        let c = ArenaChallenge.fromDetail(doc, viewer: "me")!
        XCTAssertEqual(c.participantCount, 2)
        XCTAssertFalse(c.serverJoined, "a participant who left is not in the challenge")
        XCTAssertEqual(c.threshold, 5000)
        XCTAssertEqual(c.offeredBadges, ["Focus"])
        XCTAssertEqual(c.prizeText, "Badge for every finisher")
        XCTAssertEqual(c.participant("bob")?.resultRank, 1)
        XCTAssertEqual(c.participant("bob")?.rewardAfit, 12.5)
        XCTAssertNil(c.participant("alice")?.resultRank)
        XCTAssertNotNil(c.end)
        XCTAssertTrue(ArenaChallenge.fromDetail(doc, viewer: "alice")!.serverJoined)
        XCTAssertNil(ArenaChallenge.fromDetail([:], viewer: "me"))
    }

    func testFractionalScoresAreKeptAndShown() {
        let rows = ArenaChallenge.standings(from: ["rows": [["entity": "a", "rank": 1, "score": 12.75], ["entity": ""]]])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].score, 12.75)
        XCTAssertTrue(ArenaFormat.number(12.75).contains("75"))
    }

    func testCopyFallsBackByTypeWhenTheChallengeCarriesNone() {
        var c = ArenaChallenge()
        c.type = "league_fixture"
        XCTAssertEqual(c.taglineText, ArenaText.tagline(.league))
        c.tagline = "Own tagline"
        XCTAssertEqual(c.taglineText, "Own tagline")
    }

    /// Entry is free: no Arena copy may read like gambling (mirrors the web repo's check).
    func testArenaCopyNeverUsesWageringWords() throws {
        let source = URL(fileURLWithPath: #file).deletingLastPathComponent()
            .appendingPathComponent("../Actifit/Controllers/Arena/ArenaText.swift").standardized
        let text = try String(contentsOf: source, encoding: .utf8).lowercased()
        for word in ["bet", "bets", "wager", "stake", "staking", "odds", "jackpot", "entry fee", "gamble"] {
            XCTAssertNil(text.range(of: "\\b\(word)\\b", options: .regularExpression), "Arena copy contains \"\(word)\"")
        }
    }

    private func row(_ entity: String, _ rank: Int, _ score: Double) -> ArenaStandingRow {
        var r = ArenaStandingRow()
        r.entity = entity
        r.rank = rank
        r.score = score
        return r
    }
}
