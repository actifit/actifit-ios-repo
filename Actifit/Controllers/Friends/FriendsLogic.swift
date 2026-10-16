//
//  FriendsLogic.swift
//  Actifit
//
//  Pure rules and copy for the Friends feature, ported from Android (FriendsActivity,
//  FriendEntryAdapter, FriendAccountAdapter). Foundation only, so it is covered by
//  ActifitTests/FriendsLogicTests.swift.
//

import Foundation

/// One row on the Friends screen. The kind decides the action it offers.
struct FriendRow {
    enum Kind { case friend, received, sent, suggested }

    let username: String
    var kind: Kind

    // Suggested rows only: filled by the enrichment calls; nil means not loaded (or failed).
    var reports: Int?
    var afit: Double?
    var mutual: Int?
    var enriched = false
    /// A suggestion the user just sent a request to: shown as "Request sent", no action.
    var requestSent = false
}

/// What the viewer's relationship to another user is, for the profile's friend button.
enum FriendState {
    case none, friends, sent, received
}

enum FriendsLogic {

    /// Lower-cased, without a leading "@", trimmed.
    static func normalize(_ handle: String) -> String {
        var h = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while h.hasPrefix("@") { h.removeFirst() }
        return h
    }

    /// Hive usernames: 3 to 16 characters, start with a letter, end with a letter or digit, and
    /// only letters, digits, dots and dashes between.
    static func isValidUsername(_ handle: String) -> Bool {
        return handle.range(of: "^[a-z][a-z0-9.\\-]{1,14}[a-z0-9]$", options: .regularExpression) != nil
    }

    /// Only characters that can appear in a Hive name; also keeps the RPC body safe.
    static func searchPrefix(_ text: String) -> String {
        return normalize(text).filter { "abcdefghijklmnopqrstuvwxyz0123456789.-".contains($0) }
    }

    /// 1303 becomes "1.3K", 44573 "44.6K", 100000 "100K", 2100000 "2.1M".
    static func compact(_ n: Double) -> String {
        guard n >= 1000 else { return String(Int(n.rounded())) }
        let units = ["K", "M", "B"]
        var v = n
        var u = -1
        while v >= 1000 && u < units.count - 1 { v /= 1000; u += 1 }
        let rounded = (v * 10).rounded() / 10
        let text = rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
        return text + units[u]
    }

    static func friends(from json: Any?) -> [String] {
        return ((json as? [[String: Any]]) ?? []).compactMap { $0["friend"] as? String }.filter { !$0.isEmpty }
    }

    static func requests(from json: Any?) -> (received: [String], sent: [String]) {
        let doc = json as? [String: Any] ?? [:]
        let received = ((doc["received_pending"] as? [[String: Any]]) ?? []).compactMap { $0["initiator"] as? String }
        let sent = ((doc["sent_pending"] as? [[String: Any]]) ?? []).compactMap { $0["target"] as? String }
        return (received.filter { !$0.isEmpty }, sent.filter { !$0.isEmpty })
    }

    static func state(of user: String, friends: [String], received: [String], sent: [String]) -> FriendState {
        let same: (String) -> Bool = { $0.caseInsensitiveCompare(user) == .orderedSame }
        if friends.contains(where: same) { return .friends }
        if received.contains(where: same) { return .received }
        if sent.contains(where: same) { return .sent }
        return .none
    }

    /// Candidates from one suggestion source, deduped and without anyone excluded (self,
    /// friends, pending requests either way), in the source's activity order.
    static func usableCandidates(_ authors: [String], excluding exclude: Set<String>) -> [String] {
        var seen = Set<String>()
        return authors.filter { !$0.isEmpty && !exclude.contains($0) && seen.insert($0).inserted }
    }

    static func mutualFriends(mine: [String], theirs: [String]) -> [String] {
        let set = Set(mine)
        var seen = Set<String>()
        return theirs.filter { set.contains($0) && seen.insert($0).inserted }
    }

    /// Line 1 of a suggestion ("44.6K reports · 1.2K AFIT"), built only from the parts that
    /// loaded, so a failed call is left out rather than shown as a wrong zero.
    static func primaryStats(_ row: FriendRow) -> String? {
        var parts: [String] = []
        if let r = row.reports { parts.append(FriendsText.reports(r)) }
        if let a = row.afit { parts.append(compact(a) + " AFIT") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

enum FriendsText {
    static let title = "Friends"
    static let tabFriends = "Friends"
    static let tabRequests = "Requests"
    static let tabSuggested = "Suggested"
    static let received = "RECEIVED"
    static let sent = "SENT"
    static let accept = "Accept"
    static let add = "Add"
    static let cancel = "Cancel"
    static let unfriend = "Unfriend"
    static let requestSentShort = "Request sent"
    static let searchHint = "Search a username to add…"
    static let searchInvalid = "Enter a valid Actifit username"
    static let searchSelf = "That's you!"
    static let emptyFriends = "You don't have any friends yet. Search a username above, or open an Actifitter's profile and send a request!"
    static let emptyRequests = "No pending friend requests."
    static let emptySuggested = "No suggestions right now. Try searching for a username above!"
    static let loadError = "Couldn't load your friends. Pull down to try again."
    static let loginNeeded = "Please log in to manage friends"
    static let statsLoading = "Loading details…"
    static let loadingMore = "Loading more…"
    static let done = "Done"
    static let requestSent = "Friend request sent"
    static let failed = "Something went wrong, please try again"
    static let stateUnknown = "Couldn't load · tap to retry"
    static let close = "Close"

    static let profileAdd = "Add Friend"
    static let profilePending = "Request sent · tap to cancel"
    static let profileAccept = "Accept friend request"
    static let profileFriends = "Friends ✓"

    static func confirmUnfriend(_ user: String) -> String { return "Remove @\(user) from your friends?" }
    static func requestsTab(_ pending: Int) -> String { return pending > 0 ? "\(tabRequests) (\(pending))" : tabRequests }
    static func reports(_ n: Int) -> String {
        return n == 1 ? "1 report" : "\(FriendsLogic.compact(Double(n))) reports"
    }
    static func mutual(_ n: Int) -> String { return n == 1 ? "1 mutual friend" : "\(n) mutual friends" }
}
