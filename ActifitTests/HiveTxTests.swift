//
//  HiveTxTests.swift
//  ActifitTests
//
//  The expected bytes come from Hive itself (condenser_api.get_transaction_hex on api.hive.blog,
//  trailing signature-count byte removed) and from a real on-chain @actifit transaction. They are
//  the same vectors as Android's HiveTxTest, so both apps sign identical transactions.
//

import XCTest

final class HiveTxTests: XCTestCase {

    private let expiration = HiveTime.parse("2026-10-28T12:00:00")!
    private let gadgetJson = "{\"transaction\": \"buy-gadget\", \"gadget\": \"6012ab34cd56ef7890123456\"}"

    private func tx(_ ops: HiveOp...) -> HiveTransaction {
        return HiveTransaction(refBlockNum: 12345, refBlockPrefix: 2847562398, expiration: expiration, operations: ops)
    }

    private func hex(_ t: HiveTransaction) throws -> String { return HiveHex.encode(try t.serialize()) }

    private func assertHived(_ hived: String, _ op: HiveOp, file: StaticString = #file, line: UInt = #line) throws {
        XCTAssertEqual(try hex(tx(op)), String(hived.dropLast(2)), file: file, line: line)
    }

    func testCustomJsonSerializesLikeHived() throws {
        XCTAssertEqual(try hex(tx(.postingJson(account: "mcfarhat", id: "actifit", json: gadgetJson))),
                       "39309e5abaa9c0e3e16a01120001086d636661726861740761637469666974437b227472616e73616374696f6e"
                        + "223a20226275792d676164676574222c2022676164676574223a2022363031326162333463643536656637"
                        + "383930313233343536227d00")
    }

    func testHiveTransferUsesTheLegacySteemSymbol() throws {
        try assertHived("39309e5abaa9c0e3e16a0102086d636661726861740b616374696669742e706179393000000000000003535445"
                        + "454d0000236275792d6761646765743a3630313261623334636435366566373839303132333435360000",
                        .transfer(from: "mcfarhat", to: "actifit.pay", amount: "12.345 HIVE", memo: "buy-gadget:6012ab34cd56ef7890123456"))
    }

    func testHbdTransferUsesTheLegacySbdSymbol() throws {
        try assertHived("39309e5abaa9c0e3e16a0102086d636661726861740b616374696669742e70617901000000000000000353424400000000000000",
                        .transfer(from: "mcfarhat", to: "actifit.pay", amount: "0.001 HBD", memo: ""))
    }

    func testSeveralOperationsSerializeInOrder() throws {
        let hived = "39309e5abaa9c0e3e16a02120001086d636661726861740761637469666974437b227472616e73616374696f6e223a"
            + "20226275792d676164676574222c2022676164676574223a2022363031326162333463643536656637383930313233"
            + "343536227d02086d636661726861740b616374696669742e706179393000000000000003535445454d0000236275"
            + "792d6761646765743a3630313261623334636435366566373839303132333435360000"
        XCTAssertEqual(try hex(tx(.postingJson(account: "mcfarhat", id: "actifit", json: gadgetJson),
                                  .transfer(from: "mcfarhat", to: "actifit.pay", amount: "12.345 HIVE",
                                            memo: "buy-gadget:6012ab34cd56ef7890123456"))), String(hived.dropLast(2)))
    }

    func testVoteWritesWeightAsSignedInt16() throws {
        try assertHived("39309e5abaa9c0e3e16a0100086d63666172686174076163746966697409736f6d652d706f73743cf60000",
                        .vote(voter: "mcfarhat", author: "actifit", permlink: "some-post", weight: -2500))
    }

    func testCommentSerializesUtf8Bodies() throws {
        try assertHived("39309e5abaa9c0e3e16a0101076163746966697409736f6d652d706f7374086d636661726861740e72652d736f6d652d"
                        + "706f73742d31001d477265617420776f726b20e28094206b65657020676f696e672120c3a9187b22617070223a2261"
                        + "6374696669742f302e31342e32227d0000",
                        .comment(parentAuthor: "actifit", parentPermlink: "some-post", author: "mcfarhat", permlink: "re-some-post-1",
                                 title: "", body: "Great work — keep going! é", jsonMetadata: "{\"app\":\"actifit/0.14.2\"}"))
    }

    func testPowerUpAndPowerDown() throws {
        try assertHived("39309e5abaa9c0e3e16a0103086d63666172686174086d63666172686174e80300000000000003535445454d00000000",
                        .transferToVesting(from: "mcfarhat", to: "mcfarhat", amount: "1.000 HIVE"))
        try assertHived("39309e5abaa9c0e3e16a0104086d6366617268617415cd5b070000000006564553545300000000",
                        .withdrawVesting(account: "mcfarhat", vestingShares: "123.456789 VESTS"))
    }

    func testClaimRewardBalance() throws {
        try assertHived("39309e5abaa9c0e3e16a0127086d63666172686174000000000000000003535445454d00007b0000000000000003534244"
                        + "000000003501b9020000000006564553545300000000",
                        .claimRewardBalance(account: "mcfarhat", rewardHive: "0.000 HIVE", rewardHbd: "0.123 HBD", rewardVests: "45.678901 VESTS"))
    }

    func testWrongPrecisionAndForeignDigitsAreRejectedBeforeSigning() {
        XCTAssertThrowsError(try tx(.transfer(from: "a", to: "b", amount: "1.5 HIVE", memo: "")).serialize())
        XCTAssertThrowsError(try tx(.withdrawVesting(account: "a", vestingShares: "1.000 VESTS")).serialize())
        XCTAssertThrowsError(try tx(.transfer(from: "a", to: "b", amount: "١.٠٠٠ HIVE", memo: "")).serialize())
        XCTAssertThrowsError(try tx(.vote(voter: "a", author: "b", permlink: "c", weight: 10001)).serialize())
    }

    func testControlCharactersAreDroppedFromBothForms() throws {
        let clean = HiveOp.transfer(from: "a", to: "b", amount: "1.000 HIVE", memo: "hi")
        let dirty = HiveOp.transfer(from: "a", to: "b", amount: "1.000 HIVE", memo: "h\u{1}i\u{b}")
        XCTAssertEqual(try hex(tx(clean)), try hex(tx(dirty)))
        XCTAssertEqual(clean.json, dirty.json)
        XCTAssertEqual(HiveJSON.string("a\tb\nc"), "\"a\\tb\\nc\"")   // tab and newline are kept
    }

    func testOnlyADecimalCommaIsNormalized() {
        XCTAssertEqual(HiveAmount.normalize("1,000 HIVE"), "1.000 HIVE")
        XCTAssertEqual(HiveAmount.normalize("12,345678 VESTS"), "12.345678 VESTS")
        XCTAssertEqual(HiveAmount.normalize("1,23 HIVE"), "1,23 HIVE")
        XCTAssertEqual(HiveAmount.normalize("1,000,000 HIVE"), "1,000,000 HIVE")
        XCTAssertEqual(HiveAmount.normalize("2.500 HBD"), "2.500 HBD")
    }

    func testAmountsAlwaysCarryThreeDecimals() throws {
        XCTAssertEqual(try HiveAmount.format(12.3, symbol: "HIVE"), "12.300 HIVE")
        XCTAssertEqual(try HiveAmount.format(0.1, symbol: "HBD"), "0.100 HBD")
        XCTAssertThrowsError(try HiveAmount.format(0, symbol: "HIVE"))
        XCTAssertThrowsError(try HiveAmount.format(1, symbol: "AFIT"))
    }

    /// A real transaction @actifit broadcast on 2026-09-23 (block 110164368).
    static func realActifitTx() -> HiveTransaction {
        let json = "{\"op\":\"challenge_create\",\"v\":1,\"id\":\"def_weekly_step_league\",\"type\":\"league_fixture\","
            + "\"title\":\"Weekly Step League\",\"window\":{\"start\":\"2026-09-23T13:06:26.509Z\",\"end\":\"2026-09-30T13:06:26.509Z\","
            + "\"tz\":\"UTC\"},\"scoring\":{\"metric\":\"activity_count\",\"rule\":\"max\"},\"recurrence\":\"Weekly\",\"art\":\"step-league\","
            + "\"tagline\":\"Climb the weekly leaderboard by staying active every day.\",\"how_it_works\":\"Every activity you log during "
            + "the week counts toward your score. The most active members rise to the top of the league table.\",\"prize_summary\":"
            + "\"Earn AFIT and a featured spot on the weekly leaderboard.\",\"origin_tier\":\"official\",\"entry\":{\"mode\":\"free\"}}"
        return HiveTransaction(refBlockNum: 63887, refBlockPrefix: 3540953098, expiration: HiveTime.parse("2026-09-23T13:07:27")!,
                               operations: [.postingJson(account: "actifit", id: "actifit_arena", json: json)])
    }

    func testReproducesTheIdOfARealOnChainTransaction() throws {
        XCTAssertEqual(try HiveTxTests.realActifitTx().txId(), "5216f7ab940ad2771797a2c969802dcb23f116f2")
    }

    func testRefBlockPrefixComesFromBytesFourToEightLittleEndian() {
        let t = HiveTransaction(headBlockNumber: 0x12345678, headBlockId: "0123456789abcdef0011223344556677",
                                expiration: expiration, operations: [])
        XCTAssertEqual(t.refBlockNum, 0x5678)
        XCTAssertEqual(t.refBlockPrefix, 0xefcdab89)
    }

    func testOperationsJsonIsWhatTheChainReturns() {
        XCTAssertEqual(tx(.postingJson(account: "mcfarhat", id: "actifit", json: gadgetJson)).operationsJson,
                       "[[\"custom_json\",{\"required_auths\":[],\"required_posting_auths\":[\"mcfarhat\"],\"id\":\"actifit\","
                        + "\"json\":\"{\\\"transaction\\\": \\\"buy-gadget\\\", \\\"gadget\\\": \\\"6012ab34cd56ef7890123456\\\"}\"}]]")
    }

    func testBroadcastJsonCarriesTheHeaderAndSignature() {
        let json = tx(.vote(voter: "a", author: "b", permlink: "c", weight: 10000)).json(signature: "1f00")
        XCTAssertEqual(json, "{\"ref_block_num\":12345,\"ref_block_prefix\":2847562398,\"expiration\":\"2026-10-28T12:00:00\","
                        + "\"operations\":[[\"vote\",{\"voter\":\"a\",\"author\":\"b\",\"permlink\":\"c\",\"weight\":10000}]],"
                        + "\"extensions\":[],\"signatures\":[\"1f00\"]}")
    }

    func testKeysDecodeAndValidateChecksums() throws {
        // Fixed test keys (dhive PrivateKey.fromSeed), never used on chain.
        let wif = "5J6BHAoG3K3xwo1BSFqRvVN9NcpvL2yaNbMA6gM1jxBrvvknqTd"
        XCTAssertEqual(try HiveKeys.decodeWif(wif).count, 32)
        let broken = String(wif.dropLast()) + (wif.hasSuffix("A") ? "B" : "A")
        XCTAssertThrowsError(try HiveKeys.decodeWif(broken))
        XCTAssertThrowsError(try HiveKeys.decodeWif("STM681mj7t76AU2VPgRioyy4xUn4ncS2Fp4h6CoLb8KNgJpF6EJmA"))
        // A public key string round-trips through its RIPEMD-160 checksum.
        let pub = "STM5ov9Ho2K8HHCQH5vFVegS1bFQoY4smJ2pH9kaRGJz7ppwMVzFm"
        XCTAssertEqual(HiveKeys.decodePublicKey(pub).map(HiveKeys.publicKeyString), pub)
        XCTAssertNil(HiveKeys.decodePublicKey(String(pub.dropLast()) + "X"))
    }

    func testRipemd160KnownAnswers() {
        XCTAssertEqual(HiveHex.encode(HiveRipemd160.hash([])), "9c1185a5c5e9fc54612808977ee8f548b2258d31")
        XCTAssertEqual(HiveHex.encode(HiveRipemd160.hash(Array("abc".utf8))), "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc")
        XCTAssertEqual(HiveHex.encode(HiveRipemd160.hash(Array(String(repeating: "a", count: 1_000).utf8))).count, 40)
    }

    func testBase58RoundTripsWithLeadingZeros() {
        let bytes: [UInt8] = [0, 0, 1, 2, 255, 128, 7]
        XCTAssertEqual(HiveBase58.decode(HiveBase58.encode(bytes)) ?? [], bytes)
        XCTAssertNil(HiveBase58.decode("0OIl"))
    }

    func testOpsBuiltFromTheScreensParamsMatchTheTypedOnes() throws {
        let vote = try HiveOp.from(name: "vote", params: ["voter": "mcfarhat", "author": "actifit", "permlink": "some-post",
                                                          "weight": -2500, "json_metadata": "{}"])
        XCTAssertEqual(vote.json, HiveOp.vote(voter: "mcfarhat", author: "actifit", permlink: "some-post", weight: -2500).json)
        XCTAssertThrowsError(try HiveOp.from(name: "vote", params: ["voter": "a", "author": "b", "permlink": "c"]))
        let transfer = try HiveOp.from(name: "transfer", params: ["from": "a", "to": "b", "amount": "1,000 HIVE", "memo": NSNull()])
        XCTAssertEqual(transfer.json, HiveOp.transfer(from: "a", to: "b", amount: "1.000 HIVE", memo: "").json)
        let he = try HiveOp.from(name: "custom_json", params: ["required_auths": ["a"], "required_posting_auths": [String](),
                                                               "id": "ssc-mainnet-hive", "json": "{}"])
        XCTAssertEqual(he.json, HiveOp.activeJson(account: "a", id: "ssc-mainnet-hive", json: "{}").json)
        XCTAssertThrowsError(try HiveOp.from(name: "delete_comment", params: [:]))
    }

    func testExpirationRoundTripsAsUtc() {
        XCTAssertEqual(HiveTime.iso(expiration), "2026-10-28T12:00:00")
    }

    func testOutOfRangeNodeTimesAreRejectedNotCrashed() {
        XCTAssertEqual(HiveTime.parse("2026-10-28T12:00:00"), expiration)
        XCTAssertNil(HiveTime.parse("1969-12-31T23:59:59"))
        XCTAssertNil(HiveTime.parse("2200-01-01T00:00:00"))
        XCTAssertNil(HiveTime.parse("not a date"))
    }
}
