//
//  HiveCryptoTests.swift
//  ActifitHostedTests
//
//  Signing and memo decoding need secp256k1 (a pod), so these run inside the app, with the
//  signer sources compiled in (ci_scripts/add_hosted_test_target.rb). The keys are fixed test keys
//  (dhive PrivateKey.fromSeed("ios-test-sender-key" / "ios-test-receiver-key")), never used on
//  chain; the memo and signature vectors were produced with dhive.
//

import XCTest


final class HiveCryptoTests: XCTestCase {

    private let senderWif = "5J6BHAoG3K3xwo1BSFqRvVN9NcpvL2yaNbMA6gM1jxBrvvknqTd"
    private let senderPub = "STM5ov9Ho2K8HHCQH5vFVegS1bFQoY4smJ2pH9kaRGJz7ppwMVzFm"
    private let receiverWif = "5JcM6ypL32DHK1TxqPjs7xM3LB9hopi51nFJsLwout1voCMsxyw"
    private let receiverPub = "STM5ahfPed1uqrap7hQZr3Nuc1xh2ZvZJqgtdC13iyE8tsxpk1GC5"

    func testPublicKeyOfAWif() throws {
        XCTAssertEqual(try HiveCrypto.publicKeyString(wif: senderWif), senderPub)
        XCTAssertEqual(try HiveCrypto.publicKeyString(wif: receiverWif), receiverPub)
    }

    /// The real @actifit transaction's on-chain signature recovers @actifit's posting key of the
    /// time (from its 2026-02-02 account_update until the 2026-10-22 rotation).
    func testRealSignatureRecoversActifitsPostingKeyOfTheTime() throws {
        let tx = HiveTxTestVector.realActifitTx()
        let sig = HiveHex.decode("206f71b56c2ba3e9d445b38c1a9c1aad5f8236495eec7b6574236f9069d115c1"
                                 + "3117abeee1fb4f4d82f9cd9b32981778cba343da56559879a4f90fa32966d04f97")
        XCTAssertEqual(try tx.txId(), "5216f7ab940ad2771797a2c969802dcb23f116f2")
        XCTAssertEqual(HiveKeys.publicKeyString(try HiveCrypto.recoverPublicKey(digest: try tx.digest(), signature: sig)),
                       "STM6ctE1h71HcH89rJX1uPYhAYVg8h4Dwxf3niT9magiwxGoFSkUK")
    }

    func testDhiveSignatureRecoversItsKey() throws {
        let sig = HiveHex.decode("207b2fea408675a576ca4d399588378534547c5cbf7700ac4ec3a89e8263270e"
                                 + "f56a58770b02165dc748097a66908652617e64d115a1e3eab50425d43c00dec2d1")
        let pub = try HiveCrypto.recoverPublicKey(digest: HiveHash.sha256(Array("hello".utf8)), signature: sig)
        XCTAssertEqual(HiveKeys.publicKeyString(pub), senderPub)
    }

    func testOurSignaturesAreCanonicalAndRecoverOurKey() throws {
        for i in 0..<25 {
            var priv = [UInt8](repeating: 0, count: 32)
            XCTAssertEqual(SecRandomCopyBytes(kSecRandomDefault, 32, &priv), errSecSuccess)
            priv[0] = (priv[0] & 0x7F) | 0x01   // well below the curve order
            let digest = HiveHash.sha256(Array("message \(i)".utf8))
            let sig = try HiveCrypto.signCanonical(digest: digest, privateKey: priv)
            XCTAssertEqual(sig.count, 65)
            XCTAssertTrue(HiveCrypto.isCanonical(Array(sig[1...])))
            XCTAssertEqual(try HiveCrypto.recoverPublicKey(digest: digest, signature: sig), try HiveCrypto.publicKey(privateKey: priv))
        }
    }

    func testSigningATransactionWithAWif() throws {
        let tx = HiveTransaction(refBlockNum: 1, refBlockPrefix: 2, expiration: 1_800_000_000,
                                 operations: [.postingJson(account: "someone", id: "actifit_arena", json: "{\"op\":\"join\"}")])
        let sig = HiveHex.decode(try HiveCrypto.sign(tx, wif: senderWif))
        XCTAssertEqual(HiveKeys.publicKeyString(try HiveCrypto.recoverPublicKey(digest: try tx.digest(), signature: sig)), senderPub)
        XCTAssertThrowsError(try HiveCrypto.sign(tx, wif: senderPub))
    }

    func testMemoDecodesWithEitherPartysKey() throws {
        let memo = "#7712nPXVSVsP5MpPoVK1x2pVQ9ogTT7c9J8GmuzZXqYFp1KYeyV4SR6pTaH4zvRZcGVAsZXbHCn1yP6qfTnxACoLoujZx"
            + "RgdcPVSmPBAhszVWxMjGi2isioacxAdw7DnZzV7YzkArenSbwcVKu4fvY1"
        XCTAssertEqual(try HiveCrypto.decodeMemo(memo, wif: receiverWif), "#my-3speak-access-token-123")
        XCTAssertEqual(try HiveCrypto.decodeMemo(memo, wif: senderWif), "#my-3speak-access-token-123")
        XCTAssertEqual(try HiveCrypto.decodeMemo("plain text", wif: receiverWif), "plain text")
    }

    func testMemoRejectsAnUnrelatedKey() {
        let memo = "#7712nPXVSVsP5MpPoVK1x2pVQ9ogTT7c9J8GmuzZXqYFp1KYeyV4SR6pTaH4zvRZcGVAsZXbHCn1yP6qfTnxACoLoujZx"
            + "RgdcPVSmPBAhszVWxMjGi2isioacxAdw7DnZzV7YzkArenSbwcVKu4fvY1"
        // A third key (dhive PrivateKey.fromSeed("ios-test-unrelated-key")): valid, but neither party's.
        XCTAssertThrowsError(try HiveCrypto.decodeMemo(memo, wif: "5J2NZTLPVgTuagT41cGcQvQJPw1Pk4Po8GzYyPbEkymhdP6H165"))
    }
}

/// The real transaction vector, shared with HiveTxTests (which runs without the app).
enum HiveTxTestVector {
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
}
