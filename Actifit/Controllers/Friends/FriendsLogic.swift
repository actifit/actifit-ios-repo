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
        if let a = row.afit { parts.append(FriendsText.afit(compact(a))) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// Friends copy under Android's friends_* / profile_friend_* keys, so the translations are shared
/// (see Copy in ArenaText.swift); untranslated keys fall back to the English here.
enum FriendsText {
    static var title: String { return Copy.text("friends_title", "Friends") }
    static var tabFriends: String { return Copy.text("friends_tab_friends", "Friends") }
    static var tabRequests: String { return Copy.text("friends_tab_requests", "Requests") }
    static var tabSuggested: String { return Copy.text("friends_tab_suggested", "Suggested") }
    static var received: String { return Copy.text("friends_received", "RECEIVED") }
    static var sent: String { return Copy.text("friends_sent", "SENT") }
    static var accept: String { return Copy.text("friends_action_accept", "Accept") }
    static var add: String { return Copy.text("friends_action_add", "Add") }
    static var cancel: String { return Copy.text("friends_action_cancel", "Cancel") }
    static var unfriend: String { return Copy.text("friends_action_unfriend", "Unfriend") }
    static var requestSentShort: String { return Copy.text("friends_request_sent_short", "Request sent") }
    static var searchHint: String { return Copy.text("friends_search_hint", "Search a username to add…") }
    static var searchInvalid: String { return Copy.text("friends_search_invalid", "Enter a valid Actifit username") }
    static var searchSelf: String { return Copy.text("friends_search_self", "That's you!") }
    static var emptyFriends: String { return Copy.text("friends_empty_friends", "You don't have any friends yet. Search a username above, or open an Actifitter's profile and send a request!") }
    static var emptyRequests: String { return Copy.text("friends_empty_requests", "No pending friend requests.") }
    static var emptySuggested: String { return Copy.text("friends_empty_suggested", "No suggestions right now. Try searching for a username above!") }
    static var loadError: String { return Copy.text("friends_load_error", "Couldn't load your friends. Pull down to try again.") }
    static var loginNeeded: String { return Copy.text("friends_error_login", "Please log in to manage friends") }
    static var statsLoading: String { return Copy.text("friends_stats_loading", "Loading details…") }
    static var loadingMore: String { return Copy.text("friends_loading_more", "Loading more…") }
    static var done: String { return Copy.text("friends_action_done", "Done") }
    static var requestSent: String { return Copy.text("friends_request_sent", "Friend request sent") }
    static var failed: String { return Copy.text("friends_action_failed", "Something went wrong, please try again") }
    static var stateUnknown: String { return Copy.text("friends_state_unknown", "Couldn't load · tap to retry") }
    static var close: String { return Copy.text("close_button", "Close") }

    static var profileAdd: String { return Copy.text("profile_friend_add", "Add Friend") }
    static var profilePending: String { return Copy.text("profile_friend_pending", "Request sent · tap to cancel") }
    static var profileAccept: String { return Copy.text("profile_friend_accept", "Accept friend request") }
    static var profileFriends: String { return Copy.text("profile_friend_friends", "Friends ✓") }

    static func confirmUnfriend(_ user: String) -> String {
        return Copy.format("friends_confirm_unfriend", "Remove @%1$@ from your friends?", user)
    }
    static func requestsTab(_ pending: Int) -> String { return pending > 0 ? "\(tabRequests) (\(pending))" : tabRequests }
    static func reports(_ n: Int) -> String {
        return Copy.plural("friends_stat_reports", n, one: "%1$@ report", other: "%1$@ reports", FriendsLogic.compact(Double(n)))
    }
    static func afit(_ amount: String) -> String { return Copy.format("friends_stat_afit", "%1$@ AFIT", amount) }
    static func mutual(_ n: Int) -> String {
        return Copy.plural("friends_stat_mutual", n, one: "%1$ld mutual friend", other: "%1$ld mutual friends", n)
    }
    static func pendingBadge(_ n: Int) -> String {
        return Copy.plural("friends_pending_badge_desc", n, one: "%1$ld pending friend request", other: "%1$ld pending friend requests", n)
    }
}
