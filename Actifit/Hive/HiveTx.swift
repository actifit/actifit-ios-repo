//
//  HiveTx.swift
//  Actifit
//
//  Builds and serializes Hive transactions so they can be signed on the device. Since the
//  backend's 2026-10-22 security lockdown it no longer signs for the apps (/performTrx and
//  /performTrxPost are gone), so every on-chain write is signed here with the user's own key
//  and broadcast straight to a Hive node (HiveBroadcaster).
//
//  Ported from Android's HiveTx.java. The binary format follows hived's serializer:
//  little-endian integers, varint-prefixed strings and arrays, and assets with the LEGACY
//  symbols ("STEEM" for HIVE, "SBD" for HBD). The expected bytes in ActifitTests/HiveTxTests
//  come from condenser_api.get_transaction_hex and a real on-chain transaction.
//
//  Foundation and CommonCrypto only (signing, which needs secp256k1, is in HiveCrypto), so
//  the unit tests can compile it without the app's pods.
//

import Foundation
import CommonCrypto

enum HiveError: Error, Equatable {
    case invalidAsset(String)
    case invalidKey
    case invalidWeight
    case signingFailed
    case invalidMemo
}

/// One operation: its binary form (for signing) and its condenser JSON form (for broadcast and
/// for the backend's ?operation= confirm parameter).
enum HiveOp {
    case vote(voter: String, author: String, permlink: String, weight: Int)
    case comment(parentAuthor: String, parentPermlink: String, author: String, permlink: String,
                 title: String, body: String, jsonMetadata: String)
    case transfer(from: String, to: String, amount: String, memo: String)
    case transferToVesting(from: String, to: String, amount: String)
    case withdrawVesting(account: String, vestingShares: String)
    case customJson(requiredAuths: [String], requiredPostingAuths: [String], id: String, json: String)
    case claimRewardBalance(account: String, rewardHive: String, rewardHbd: String, rewardVests: String)

    /// The common case: a posting-auth custom_json signed by one account.
    static func postingJson(account: String, id: String, json: String) -> HiveOp {
        return .customJson(requiredAuths: [], requiredPostingAuths: [account], id: id, json: json)
    }

    /// An active-auth custom_json (Hive-Engine token operations).
    static func activeJson(account: String, id: String, json: String) -> HiveOp {
        return .customJson(requiredAuths: [account], requiredPostingAuths: [], id: id, json: json)
    }

    fileprivate func write(_ w: inout HiveWriter) throws {
        switch self {
        case let .vote(voter, author, permlink, weight):
            guard (-10000...10000).contains(weight) else { throw HiveError.invalidWeight }
            w.varint(0); w.string(voter); w.string(author); w.string(permlink)
            w.uint16(UInt16(bitPattern: Int16(weight)))   // int16, two's complement
        case let .comment(pa, pp, author, permlink, title, body, meta):
            w.varint(1); w.string(pa); w.string(pp); w.string(author); w.string(permlink)
            w.string(title); w.string(body); w.string(meta)
        case let .transfer(from, to, amount, memo):
            w.varint(2); w.string(from); w.string(to); try w.asset(amount); w.string(memo)
        case let .transferToVesting(from, to, amount):
            w.varint(3); w.string(from); w.string(to); try w.asset(amount)
        case let .withdrawVesting(account, shares):
            w.varint(4); w.string(account); try w.asset(shares)
        case let .customJson(auths, postingAuths, id, json):
            w.varint(18); w.strings(auths); w.strings(postingAuths); w.string(id); w.string(json)
        case let .claimRewardBalance(account, hive, hbd, vests):
            w.varint(39); w.string(account); try w.asset(hive); try w.asset(hbd); try w.asset(vests)
        }
    }

    /// e.g. ["custom_json",{...}]: the exact shape the chain returns for the op.
    var json: String {
        let j = HiveJSON.string
        switch self {
        case let .vote(voter, author, permlink, weight):
            return "[\"vote\",{\"voter\":\(j(voter)),\"author\":\(j(author)),\"permlink\":\(j(permlink)),\"weight\":\(weight)}]"
        case let .comment(pa, pp, author, permlink, title, body, meta):
            return "[\"comment\",{\"parent_author\":\(j(pa)),\"parent_permlink\":\(j(pp)),\"author\":\(j(author))"
                + ",\"permlink\":\(j(permlink)),\"title\":\(j(title)),\"body\":\(j(body)),\"json_metadata\":\(j(meta))}]"
        case let .transfer(from, to, amount, memo):
            return "[\"transfer\",{\"from\":\(j(from)),\"to\":\(j(to)),\"amount\":\(j(amount)),\"memo\":\(j(memo))}]"
        case let .transferToVesting(from, to, amount):
            return "[\"transfer_to_vesting\",{\"from\":\(j(from)),\"to\":\(j(to)),\"amount\":\(j(amount))}]"
        case let .withdrawVesting(account, shares):
            return "[\"withdraw_vesting\",{\"account\":\(j(account)),\"vesting_shares\":\(j(shares))}]"
        case let .customJson(auths, postingAuths, id, json):
            return "[\"custom_json\",{\"required_auths\":\(HiveJSON.array(auths)),\"required_posting_auths\":"
                + "\(HiveJSON.array(postingAuths)),\"id\":\(j(id)),\"json\":\(j(json))}]"
        case let .claimRewardBalance(account, hive, hbd, vests):
            return "[\"claim_reward_balance\",{\"account\":\(j(account)),\"reward_hive\":\(j(hive)),\"reward_hbd\":"
                + "\(j(hbd)),\"reward_vests\":\(j(vests))}]"
        }
    }
}

extension HiveOp {

    /// Builds an op from the (name, params) pairs the app's screens already assemble. Supports
    /// exactly what the app broadcasts: vote, comment, transfer, transfer_to_vesting,
    /// withdraw_vesting and custom_json. Ported from Android's HiveOpsJson.
    static func from(name: String, params p: [String: Any]) throws -> HiveOp {
        func s(_ key: String) -> String {
            guard let v = p[key], !(v is NSNull) else { return "" }
            return v as? String ?? "\(v)"
        }
        func strings(_ key: String) -> [String] {
            if let a = p[key] as? [Any] { return a.map { $0 as? String ?? "\($0)" } }
            if let one = p[key] as? String, !one.isEmpty, one != "[]" { return [one] }
            return []
        }
        switch name {
        case "vote":
            // A missing weight must not silently become 0, which is an unvote.
            guard let w = p["weight"] as? NSNumber else { throw HiveError.invalidWeight }
            return .vote(voter: s("voter"), author: s("author"), permlink: s("permlink"), weight: w.intValue)
        case "comment":
            return .comment(parentAuthor: s("parent_author"), parentPermlink: s("parent_permlink"), author: s("author"),
                            permlink: s("permlink"), title: s("title"), body: s("body"), jsonMetadata: s("json_metadata"))
        case "transfer":
            return .transfer(from: s("from"), to: s("to"), amount: HiveAmount.normalize(s("amount")), memo: s("memo"))
        case "transfer_to_vesting":
            let to = s("to")
            return .transferToVesting(from: s("from"), to: to.isEmpty ? s("from") : to, amount: HiveAmount.normalize(s("amount")))
        case "withdraw_vesting":
            return .withdrawVesting(account: s("account"), vestingShares: HiveAmount.normalize(s("vesting_shares")))
        case "custom_json":
            return .customJson(requiredAuths: strings("required_auths"), requiredPostingAuths: strings("required_posting_auths"),
                               id: s("id"), json: s("json"))
        default:
            throw HiveError.invalidAsset("unsupported operation: \(name)")
        }
    }
}

/// A transaction ready to sign: header fields and operations.
struct HiveTransaction {

    /// Hive mainnet chain id.
    static let chainId = "beeab0de00000000000000000000000000000000000000000000000000000000"

    let refBlockNum: UInt16
    let refBlockPrefix: UInt32
    /// Unix seconds, UTC.
    let expiration: UInt32
    let operations: [HiveOp]

    init(refBlockNum: UInt16, refBlockPrefix: UInt32, expiration: UInt32, operations: [HiveOp]) {
        self.refBlockNum = refBlockNum
        self.refBlockPrefix = refBlockPrefix
        self.expiration = expiration
        self.operations = operations
    }

    /// Header fields from the head block, as hived expects them (TaPoS): the low 16 bits of the
    /// block number, and bytes 4..<8 of its id read little-endian.
    init(headBlockNumber: UInt64, headBlockId: String, expiration: UInt32, operations: [HiveOp]) {
        let id = HiveHex.decode(headBlockId)
        var prefix: UInt32 = 0
        if id.count >= 8 {
            prefix = UInt32(id[4]) | UInt32(id[5]) << 8 | UInt32(id[6]) << 16 | UInt32(id[7]) << 24
        }
        self.init(refBlockNum: UInt16(truncatingIfNeeded: headBlockNumber), refBlockPrefix: prefix,
                  expiration: expiration, operations: operations)
    }

    /// The signed bytes: everything but the signatures.
    func serialize() throws -> [UInt8] {
        var w = HiveWriter()
        w.uint16(refBlockNum)
        w.uint32(refBlockPrefix)
        w.uint32(expiration)
        w.varint(UInt64(operations.count))
        for op in operations { try op.write(&w) }
        w.varint(0)   // extensions
        return w.bytes
    }

    /// Hive's transaction id: the first 20 bytes of sha256(serialized tx), hex.
    func txId() throws -> String {
        return HiveHex.encode(Array(HiveHash.sha256(try serialize()).prefix(20)))
    }

    /// What gets signed: sha256(chain id + serialized tx).
    func digest() throws -> [UInt8] {
        return HiveHash.sha256(HiveHex.decode(HiveTransaction.chainId) + (try serialize()))
    }

    /// The ops array alone, e.g. for the backend's ?operation= confirm parameter.
    var operationsJson: String {
        return "[" + operations.map { $0.json }.joined(separator: ",") + "]"
    }

    /// The condenser_api.broadcast_transaction payload.
    func json(signature: String?) -> String {
        let sigs = signature.map { "[" + HiveJSON.string($0) + "]" } ?? "[]"
        return "{\"ref_block_num\":\(refBlockNum),\"ref_block_prefix\":\(refBlockPrefix),\"expiration\":"
            + HiveJSON.string(HiveTime.iso(expiration)) + ",\"operations\":\(operationsJson),\"extensions\":[],"
            + "\"signatures\":\(sigs)}"
    }
}

// MARK: - Amounts

enum HiveAmount {

    /// 12.3 -> "12.300 HIVE": the chain wants exactly 3 decimals for HIVE and HBD.
    static func format(_ value: Double, symbol: String) throws -> String {
        guard symbol == "HIVE" || symbol == "HBD", value > 0, value.isFinite else { throw HiveError.invalidAsset("\(value) \(symbol)") }
        let rounded = NSDecimalNumber(value: value).rounding(accordingToBehavior:
            NSDecimalNumberHandler(roundingMode: .plain, scale: 3, raiseOnExactness: false, raiseOnOverflow: false,
                                   raiseOnUnderflow: false, raiseOnDivideByZero: false))
        return String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), rounded.doubleValue) + " " + symbol
    }

    /// "1,000 HIVE" -> "1.000 HIVE": a comma-decimal locale may have formatted the amount. Only a
    /// single comma followed by exactly 3 (or 6 for VESTS) digits is treated as the decimal
    /// separator; anything else is left as it is, to be rejected rather than misread.
    static func normalize(_ asset: String) -> String {
        let s = asset.trimmingCharacters(in: .whitespaces)
        guard let space = s.firstIndex(of: " ") else { return s }
        var num = String(s[..<space])
        let unit = String(s[space...])
        let commas = num.filter { $0 == "," }.count
        if !num.contains("."), commas == 1, let comma = num.firstIndex(of: ","), comma != num.startIndex {
            let decimals = num.distance(from: comma, to: num.endIndex) - 1
            if decimals == 3 || (decimals == 6 && unit == " VESTS") { num = num.replacingOccurrences(of: ",", with: ".") }
        }
        return num + unit
    }
}

// MARK: - Keys

enum HiveKeys {

    /// The 32-byte secret in a WIF private key; throws for anything that isn't one (including a
    /// public "STM…" key, or a typo caught by the checksum).
    static func decodeWif(_ wif: String) throws -> [UInt8] {
        guard let raw = HiveBase58.decode(wif.trimmingCharacters(in: .whitespacesAndNewlines)),
              raw.count == 37, raw[0] == 0x80 else { throw HiveError.invalidKey }
        let check = HiveHash.sha256(HiveHash.sha256(Array(raw[0..<33])))
        guard Array(check[0..<4]) == Array(raw[33..<37]) else { throw HiveError.invalidKey }
        return Array(raw[1..<33])
    }

    /// "STM…" for a 33-byte compressed public key.
    static func publicKeyString(_ compressed: [UInt8]) -> String {
        let check = HiveRipemd160.hash(compressed)
        return "STM" + HiveBase58.encode(compressed + Array(check[0..<4]))
    }

    /// The 33-byte compressed key in an "STM…" string, checksum verified.
    static func decodePublicKey(_ key: String) -> [UInt8]? {
        guard key.hasPrefix("STM"), let raw = HiveBase58.decode(String(key.dropFirst(3))), raw.count == 37 else { return nil }
        let pub = Array(raw[0..<33])
        guard Array(HiveRipemd160.hash(pub)[0..<4]) == Array(raw[33..<37]) else { return nil }
        return pub
    }
}

// MARK: - Serialization primitives

struct HiveWriter {
    private(set) var bytes: [UInt8] = []

    mutating func varint(_ value: UInt64) {
        var v = value
        while v >= 0x80 {
            bytes.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        bytes.append(UInt8(v))
    }

    mutating func uint16(_ v: UInt16) {
        bytes.append(UInt8(v & 0xFF)); bytes.append(UInt8(v >> 8))
    }

    mutating func uint32(_ v: UInt32) {
        for i in 0..<4 { bytes.append(UInt8((v >> (8 * UInt32(i))) & 0xFF)) }
    }

    mutating func uint64(_ v: UInt64) {
        for i in 0..<8 { bytes.append(UInt8((v >> (8 * UInt64(i))) & 0xFF)) }
    }

    mutating func string(_ s: String) {
        let b = Array(HiveJSON.clean(s).utf8)
        varint(UInt64(b.count))
        bytes += b
    }

    mutating func strings(_ items: [String]) {
        varint(UInt64(items.count))
        items.forEach { string($0) }
    }

    /// "12.345 HIVE" -> int64 amount, precision byte, 7-byte legacy symbol (VESTS: 6 decimals).
    mutating func asset(_ asset: String) throws {
        let parts = asset.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        guard parts.count == 2 else { throw HiveError.invalidAsset(asset) }
        let num = parts[0]
        // ASCII digits only: Arabic and Persian locales write numbers with other digits, which
        // must never reach the chain.
        guard num.range(of: "^[0-9]+\\.[0-9]+$", options: .regularExpression) != nil,
              let dot = num.firstIndex(of: ".") else { throw HiveError.invalidAsset(asset) }
        let precision = num.distance(from: dot, to: num.endIndex) - 1
        let symbol: String
        let expected: Int
        switch parts[1] {
        case "HIVE": symbol = "STEEM"; expected = 3
        case "HBD": symbol = "SBD"; expected = 3
        case "VESTS": symbol = "VESTS"; expected = 6
        default: throw HiveError.invalidAsset(asset)
        }
        guard precision == expected, let amount = Int64(num.replacingOccurrences(of: ".", with: "")) else {
            throw HiveError.invalidAsset(asset)
        }
        uint64(UInt64(bitPattern: amount))
        bytes.append(UInt8(precision))
        let sym = Array(symbol.utf8)
        bytes += sym + [UInt8](repeating: 0, count: 7 - sym.count)
    }
}

enum HiveJSON {

    /// Control characters other than tab, newline and CR don't survive the node's JSON path
    /// byte for byte, so what the node re-serializes would differ from what was signed. Both the
    /// binary and the JSON forms drop them.
    static func clean(_ s: String) -> String {
        guard s.unicodeScalars.contains(where: { $0.value < 0x20 && !["\t", "\n", "\r"].contains($0) }) else { return s }
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars where !(u.value < 0x20 && !["\t", "\n", "\r"].contains(u)) { out.append(u) }
        return String(out)
    }

    static func string(_ raw: String) -> String {
        var out = "\""
        for u in clean(raw).unicodeScalars {
            switch u {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.unicodeScalars.append(u)
            }
        }
        return out + "\""
    }

    static func array(_ items: [String]) -> String {
        return "[" + items.map { string($0) }.joined(separator: ",") + "]"
    }
}

enum HiveTime {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    static func iso(_ seconds: UInt32) -> String {
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
    }

    static func parse(_ iso: String) -> UInt32? {
        // A node or proxy could send any date: out of range must not crash the conversion.
        return formatter.date(from: iso).flatMap { UInt32(exactly: $0.timeIntervalSince1970.rounded(.down)) }
    }
}

enum HiveURL {
    /// Strict percent-encoding for a URL path segment or query value: only ASCII letters, digits
    /// and -._~ pass through ("@" in rolled-over ids, "&" or "/" in user input never do).
    static func component(_ s: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}

enum HiveHex {
    static func encode(_ bytes: [UInt8]) -> String {
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func decode(_ hex: String) -> [UInt8] {
        var out: [UInt8] = []
        var chars = Array(hex.utf8)
        if chars.count % 2 == 1 { chars.insert(UInt8(ascii: "0"), at: 0) }
        var i = 0
        while i < chars.count {
            guard let b = UInt8(String(bytes: chars[i..<i + 2], encoding: .ascii) ?? "", radix: 16) else { return [] }
            out.append(b)
            i += 2
        }
        return out
    }
}

enum HiveHash {
    static func sha256(_ data: [UInt8]) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBufferPointer { p in _ = CC_SHA256(p.baseAddress, CC_LONG(data.count), &out) }
        return out
    }

    static func sha512(_ data: [UInt8]) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBufferPointer { p in _ = CC_SHA512(p.baseAddress, CC_LONG(data.count), &out) }
        return out
    }
}

enum HiveBase58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)

    static func encode(_ bytes: [UInt8]) -> String {
        var zeros = 0
        while zeros < bytes.count && bytes[zeros] == 0 { zeros += 1 }
        var digits: [UInt8] = []   // base-58, little-endian
        for b in bytes {
            var carry = Int(b)
            for i in 0..<digits.count {
                carry += Int(digits[i]) << 8
                digits[i] = UInt8(carry % 58)
                carry /= 58
            }
            while carry > 0 { digits.append(UInt8(carry % 58)); carry /= 58 }
        }
        let chars = [UInt8](repeating: alphabet[0], count: zeros) + digits.reversed().map { alphabet[Int($0)] }
        return String(bytes: chars, encoding: .ascii) ?? ""
    }

    static func decode(_ string: String) -> [UInt8]? {
        var bytes: [UInt8] = []   // base-256, little-endian
        var zeros = 0
        var leading = true
        for c in string.utf8 {
            guard let value = alphabet.firstIndex(of: c) else { return nil }
            if leading && value == 0 { zeros += 1; continue }
            leading = false
            var carry = value
            for i in 0..<bytes.count {
                carry += Int(bytes[i]) * 58
                bytes[i] = UInt8(carry & 0xFF)
                carry >>= 8
            }
            while carry > 0 { bytes.append(UInt8(carry & 0xFF)); carry >>= 8 }
        }
        return [UInt8](repeating: 0, count: zeros) + bytes.reversed()
    }
}

/// RIPEMD-160, for the checksum in "STM…" public keys (CommonCrypto doesn't provide it).
enum HiveRipemd160 {

    static func hash(_ message: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
        var msg = message
        let bitLength = UInt64(message.count) * 8
        msg.append(0x80)
        while msg.count % 64 != 56 { msg.append(0) }
        for i in 0..<8 { msg.append(UInt8((bitLength >> (8 * UInt64(i))) & 0xFF)) }

        for chunk in stride(from: 0, to: msg.count, by: 64) {
            var x = [UInt32](repeating: 0, count: 16)
            for i in 0..<16 {
                let o = chunk + i * 4
                x[i] = UInt32(msg[o]) | UInt32(msg[o + 1]) << 8 | UInt32(msg[o + 2]) << 16 | UInt32(msg[o + 3]) << 24
            }
            var al = h[0], bl = h[1], cl = h[2], dl = h[3], el = h[4]
            var ar = h[0], br = h[1], cr = h[2], dr = h[3], er = h[4]
            for j in 0..<80 {
                var t = rotl(al &+ f(j, bl, cl, dl) &+ x[rl[j]] &+ kl[j / 16], sl[j]) &+ el
                al = el; el = dl; dl = rotl(cl, 10); cl = bl; bl = t
                t = rotl(ar &+ f(79 - j, br, cr, dr) &+ x[rr[j]] &+ kr[j / 16], sr[j]) &+ er
                ar = er; er = dr; dr = rotl(cr, 10); cr = br; br = t
            }
            let t = h[1] &+ cl &+ dr
            h[1] = h[2] &+ dl &+ er
            h[2] = h[3] &+ el &+ ar
            h[3] = h[4] &+ al &+ br
            h[4] = h[0] &+ bl &+ cr
            h[0] = t
        }
        var out: [UInt8] = []
        for v in h { for i in 0..<4 { out.append(UInt8((v >> (8 * UInt32(i))) & 0xFF)) } }
        return out
    }

    private static func rotl(_ x: UInt32, _ n: Int) -> UInt32 {
        return (x << UInt32(n)) | (x >> UInt32(32 - n))
    }

    private static func f(_ j: Int, _ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 {
        switch j {
        case 0..<16: return x ^ y ^ z
        case 16..<32: return (x & y) | (~x & z)
        case 32..<48: return (x | ~y) ^ z
        case 48..<64: return (x & z) | (y & ~z)
        default: return x ^ (y | ~z)
        }
    }

    private static let kl: [UInt32] = [0x00000000, 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xA953FD4E]
    private static let kr: [UInt32] = [0x50A28BE6, 0x5C4DD124, 0x6D703EF3, 0x7A6D76E9, 0x00000000]
    private static let rl: [Int] = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
        3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12, 1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
        4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13]
    private static let rr: [Int] = [
        5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12, 6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
        15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13, 8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
        12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11]
    private static let sl: [Int] = [
        11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8, 7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
        11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5, 11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
        9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6]
    private static let sr: [Int] = [
        8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6, 9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
        9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5, 15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
        8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11]
}
