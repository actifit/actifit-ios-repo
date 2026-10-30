//
//  HiveCrypto.swift
//  Actifit
//
//  secp256k1 for Hive: canonical recoverable signatures, public-key recovery, and decoding
//  encrypted memos (the 3Speak login token), all on the device. Uses bitcoin-core's
//  libsecp256k1 through the secp256k1.swift pod. Ported from Android's HiveTx.java; the memo
//  format follows dhive's memo.js / aes.js.
//

import Foundation
import CommonCrypto
import secp256k1

enum HiveCrypto {

    // The library's flag macros are composites Swift can't import, so their values are spelled
    // out (SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY, SECP256K1_EC_COMPRESSED, ...).
    private static let contextSignVerify: UInt32 = 0x301
    private static let compressed: UInt32 = 0x102
    private static let uncompressed: UInt32 = 0x002

    private static let context: OpaquePointer = secp256k1_context_create(contextSignVerify)!

    /// Signs a transaction with a WIF key; returns the 65-byte compact signature as hex.
    static func sign(_ tx: HiveTransaction, wif: String) throws -> String {
        return HiveHex.encode(try signCanonical(digest: try tx.digest(), privateKey: try HiveKeys.decodeWif(wif)))
    }

    /// The 33-byte compressed public key for a 32-byte secret.
    static func publicKey(privateKey: [UInt8]) throws -> [UInt8] {
        var pub = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(context, &pub, privateKey) == 1 else { throw HiveError.invalidKey }
        return try serialize(&pub, flags: compressed, length: 33)
    }

    /// "STM…" for a WIF key, e.g. to check a stored key belongs to the account.
    static func publicKeyString(wif: String) throws -> String {
        return HiveKeys.publicKeyString(try publicKey(privateKey: try HiveKeys.decodeWif(wif)))
    }

    /// A 65-byte compact recoverable signature that hived accepts: low-S (libsecp256k1 always
    /// produces it) and "fc canonical" (neither r nor s may have its top bit set or be
    /// zero-padded). RFC 6979 nonces with a counter as extra entropy are tried until the result
    /// is canonical, which about half the attempts are.
    static func signCanonical(digest: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        guard digest.count == 32, privateKey.count == 32 else { throw HiveError.signingFailed }
        for attempt in 0..<1000 {
            var extra = [UInt8](repeating: 0, count: 32)
            extra[0] = UInt8(attempt & 0xFF)
            extra[1] = UInt8((attempt >> 8) & 0xFF)
            var sig = secp256k1_ecdsa_recoverable_signature()
            let ok = secp256k1_ecdsa_sign_recoverable(context, &sig, digest, privateKey,
                                                      secp256k1_nonce_function_rfc6979, extra)
            guard ok == 1 else { throw HiveError.signingFailed }
            var compact = [UInt8](repeating: 0, count: 64)
            var recid: Int32 = 0
            _ = secp256k1_ecdsa_recoverable_signature_serialize_compact(context, &compact, &recid, &sig)
            if isCanonical(compact) { return [UInt8(31 + recid)] + compact }
        }
        throw HiveError.signingFailed
    }

    static func isCanonical(_ compact: [UInt8]) -> Bool {
        guard compact.count == 64 else { return false }
        let r0 = compact[0], r1 = compact[1], s0 = compact[32], s1 = compact[33]
        return r0 & 0x80 == 0 && !(r0 == 0 && r1 & 0x80 == 0)
            && s0 & 0x80 == 0 && !(s0 == 0 && s1 & 0x80 == 0)
    }

    /// The compressed public key that produced a 65-byte compact signature over a digest.
    static func recoverPublicKey(digest: [UInt8], signature: [UInt8]) throws -> [UInt8] {
        guard signature.count == 65, digest.count == 32 else { throw HiveError.signingFailed }
        let recid = Int32(signature[0]) - 31
        guard (0...3).contains(recid) else { throw HiveError.signingFailed }
        var sig = secp256k1_ecdsa_recoverable_signature()
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(context, &sig, Array(signature[1...]), recid) == 1 else {
            throw HiveError.signingFailed
        }
        var pub = secp256k1_pubkey()
        guard secp256k1_ecdsa_recover(context, &pub, &sig, digest) == 1 else { throw HiveError.signingFailed }
        return try serialize(&pub, flags: compressed, length: 33)
    }

    /// Signs a message's sha256 with a WIF key (the signed-challenge login), as hex.
    static func signMessage(_ message: String, wif: String) throws -> String {
        return HiveHex.encode(try signCanonical(digest: HiveHash.sha256(Array(message.utf8)), privateKey: try HiveKeys.decodeWif(wif)))
    }

    // MARK: - Encrypted memos

    /// Decrypts a Hive memo ("#…") with the private key of either party. Returns it with its
    /// leading "#", as dhive's Memo.decode does; a memo without "#" is returned as is.
    static func decodeMemo(_ memo: String, wif: String) throws -> String {
        guard memo.hasPrefix("#") else { return memo }
        guard let raw = HiveBase58.decode(String(memo.dropFirst())), raw.count > 33 + 33 + 8 + 4 + 1 else {
            throw HiveError.invalidMemo
        }
        let priv = try HiveKeys.decodeWif(wif)
        let from = Array(raw[0..<33]), to = Array(raw[33..<66])
        var nonce: UInt64 = 0
        for i in 0..<8 { nonce |= UInt64(raw[66 + i]) << (8 * UInt64(i)) }
        var check: UInt32 = 0
        for i in 0..<4 { check |= UInt32(raw[74 + i]) << (8 * UInt32(i)) }
        var reader = HiveReader(bytes: Array(raw[78...]))
        guard let encrypted = reader.varBytes() else { throw HiveError.invalidMemo }

        let mine = try publicKey(privateKey: priv)
        let other = mine == from ? to : from

        // Shared secret: sha512 of the x coordinate of other * priv.
        var point = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(context, &point, other, 33) == 1,
              secp256k1_ec_pubkey_tweak_mul(context, &point, priv) == 1 else { throw HiveError.invalidMemo }
        let full = try serialize(&point, flags: uncompressed, length: 65)
        let shared = HiveHash.sha512(Array(full[1..<33]))

        var w = HiveWriter()
        w.uint64(nonce)
        let encryptionKey = HiveHash.sha512(w.bytes + shared)
        let checkBytes = HiveHash.sha256(encryptionKey)
        let expected = UInt32(checkBytes[0]) | UInt32(checkBytes[1]) << 8 | UInt32(checkBytes[2]) << 16 | UInt32(checkBytes[3]) << 24
        guard expected == check else { throw HiveError.invalidKey }   // not this memo's key

        let plain = try aes256CbcDecrypt(encrypted, key: Array(encryptionKey[0..<32]), iv: Array(encryptionKey[32..<48]))
        // The plaintext is normally length-prefixed; a sender may also have written it bare.
        var body = HiveReader(bytes: plain)
        if let text = body.varBytes(), body.atEnd, let s = String(bytes: text, encoding: .utf8) { return "#" + s }
        return "#" + (String(bytes: plain, encoding: .utf8) ?? "")
    }

    // MARK: - Helpers

    private static func serialize(_ pub: inout secp256k1_pubkey, flags: UInt32, length: Int) throws -> [UInt8] {
        var out = [UInt8](repeating: 0, count: length)
        var len = length
        guard secp256k1_ec_pubkey_serialize(context, &out, &len, &pub, flags) == 1, len == length else {
            throw HiveError.invalidKey
        }
        return out
    }

    private static func aes256CbcDecrypt(_ data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        var out = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        var moved = 0
        let status = CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                             key, key.count, iv, data, data.count, &out, out.count, &moved)
        guard status == kCCSuccess else { throw HiveError.invalidMemo }
        return Array(out[0..<moved])
    }
}

/// Reads hived's varint-prefixed buffers.
struct HiveReader {
    let bytes: [UInt8]
    private var offset = 0

    init(bytes: [UInt8]) { self.bytes = bytes }

    var atEnd: Bool { return offset == bytes.count }

    mutating func varint() -> UInt64? {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        while offset < bytes.count && shift < 64 {
            let b = bytes[offset]
            offset += 1
            value |= UInt64(b & 0x7F) << shift
            if b & 0x80 == 0 { return value }
            shift += 7
        }
        return nil
    }

    mutating func varBytes() -> [UInt8]? {
        guard let n = varint(), n <= UInt64(bytes.count - offset) else { return nil }
        let out = Array(bytes[offset..<offset + Int(n)])
        offset += Int(n)
        return out
    }
}
