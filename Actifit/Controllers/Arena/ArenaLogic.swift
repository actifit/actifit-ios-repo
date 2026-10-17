//
//  ArenaLogic.swift
//  Actifit
//
//  Pure Arena rules, ported from Android's ArenaLogic.java. Foundation only, so it is
//  unit-testable on its own (ActifitTests/ArenaLogicTests.swift mirrors ArenaLogicTest.java).
//  Anything user-facing comes back as a value or a kind; ArenaText turns those into copy.
//

import Foundation

enum ArenaLogic {

    static let artBaseURL = "https://actifit.io/img/arena/"

    /// How long an un-indexed join/leave stays optimistic before we stop trusting it.
    static let pendingTTL: TimeInterval = 5 * 60

    /// Fallback copy buckets for challenges that carry no tagline/how-it-works of their own.
    enum Kind { case league, daily, event, other }

    enum DurationUnit { case days, weeks, months }

    enum Membership {
        case notJoined, joined, pendingJoin, pendingLeave

        /// In the challenge as far as the viewer is concerned, counting an unconfirmed join.
        var isIn: Bool { return self == .joined || self == .pendingJoin }
    }

    enum Op: String { case join, leave }

    /// Only open/active challenges accept a join or leave; any unknown state is closed.
    static func isJoinable(_ state: String?) -> Bool {
        return state == "open" || state == "active"
    }

    static func kind(of type: String?) -> Kind {
        switch type {
        case "league_fixture": return .league
        case "daily_focus": return .daily
        case "liveops": return .event
        default: return .other
        }
    }

    /// The banner key: the challenge's own art, else a per-type default. A key that is not a
    /// plain slug is ignored, so it can never point outside the image folder.
    static func artKey(art: String?, type: String?) -> String {
        if let art = art, art.range(of: "^[a-z0-9-]{1,40}$", options: .regularExpression) != nil {
            return art
        }
        switch kind(of: type) {
        case .daily: return "daily-focus"
        case .event: return "monthly-event"
        default: return "step-league"
        }
    }

    static func artURL(art: String?, type: String?) -> URL? {
        return URL(string: artBaseURL + artKey(art: art, type: type) + ".webp")
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain = ISO8601DateFormatter()

    /// The API sends both "2026-09-23T13:06:26.509Z" and a zone-less "2026-09-23T13:06:30" (UTC).
    static func parseDate(_ iso: String?) -> Date? {
        guard let iso = iso, !iso.isEmpty else { return nil }
        for candidate in [iso, iso + "Z"] {
            if let d = isoFractional.date(from: candidate) ?? isoPlain.date(from: candidate) { return d }
        }
        return nil
    }

    /// Window length (e.g. 2 weeks), or nil for a missing or inverted window. Mirrors the
    /// web's formatDuration thresholds.
    static func duration(start: Date?, end: Date?) -> (unit: DurationUnit, count: Int)? {
        guard let start = start, let end = end, end > start else { return nil }
        let days = Int((end.timeIntervalSince(start) / 86400).rounded())
        if days <= 1 { return (.days, 1) }
        if days < 14 { return (.days, days) }
        if days < 28 { return (.weeks, Int((Double(days) / 7).rounded())) }
        return (.months, max(1, Int((Double(days) / 30).rounded())))
    }

    /// Time left; all zero once the window has closed or when it has no end.
    static func remaining(until end: Date?, now: Date) -> (days: Int, hours: Int, minutes: Int) {
        guard let end = end, end > now else { return (0, 0, 0) }
        let minutes = Int(end.timeIntervalSince(now) / 60)
        return (minutes / 1440, (minutes % 1440) / 60, minutes % 60)
    }

    /// Time left to the second, for a live countdown; all zero once closed or with no end.
    static func countdown(until end: Date?, now: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        guard let end = end, end > now else { return (0, 0, 0, 0) }
        let s = Int(end.timeIntervalSince(now))
        return (s / 86400, (s % 86400) / 3600, (s % 3600) / 60, s % 60)
    }

    static func hasEnded(_ end: Date?, now: Date) -> Bool {
        guard let end = end else { return false }
        return now >= end
    }

    /// A pending op the server now agrees with is confirmed and can be dropped.
    static func pendingConfirmed(serverJoined: Bool, op: Op) -> Bool {
        return (op == .join && serverJoined) || (op == .leave && !serverJoined)
    }

    /// A pending op the server still hasn't applied after the TTL: treat it as not landed.
    static func pendingExpired(serverJoined: Bool, op: Op?, at: Date, now: Date) -> Bool {
        guard let op = op, !pendingConfirmed(serverJoined: serverJoined, op: op) else { return false }
        return now.timeIntervalSince(at) >= pendingTTL
    }

    /// What to show for the viewer. The backend indexes a broadcast a few seconds later, so
    /// until then a fresh local join/leave overrides the server's (stale) answer.
    static func membership(serverJoined: Bool, op: Op?, at: Date, now: Date) -> Membership {
        if let op = op,
           !pendingConfirmed(serverJoined: serverJoined, op: op),
           !pendingExpired(serverJoined: serverJoined, op: op, at: at, now: now) {
            return op == .join ? .pendingJoin : .pendingLeave
        }
        return serverJoined ? .joined : .notJoined
    }

    /// The viewer's row and the nearest row with a BETTER rank (rows can tie, so the row
    /// directly above is not necessarily ahead). nil when the viewer is not on the board.
    static func standing(of user: String, in rows: [ArenaStandingRow]) -> (mine: ArenaStandingRow, ahead: ArenaStandingRow?)? {
        guard !user.isEmpty, let i = rows.firstIndex(where: { $0.entity == user }) else { return nil }
        let mine = rows[i]
        let ahead = rows[..<i].last(where: { $0.rank < mine.rank })
        return (mine, ahead)
    }

    /// The challenge id in an Arena notification link (https://actifit.io/arena/<id>), percent-
    /// decoded since rolled-over ids carry "@" as %40. nil for any other URL, an empty id, or the
    /// create page. Same rules as Android's ArenaLogic.challengeIdFromUrl.
    static func challengeId(fromURL url: String?) -> String? {
        guard let url = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              let m = arenaLink.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
              let r = Range(m.range(at: 1), in: url),
              let id = String(url[r]).removingPercentEncoding, !id.isEmpty, id != "create" else { return nil }
        return id
    }

    private static let arenaLink = try! NSRegularExpression(pattern: "^https?://(?:www\\.)?actifit\\.io/arena/([^/?#]+)/?(?:[?#].*)?$")

    /// Machine enum to readable label ("league_fixture" becomes "league fixture").
    static func humanize(_ s: String?) -> String {
        return (s ?? "").replacingOccurrences(of: "_", with: " ")
    }
}
