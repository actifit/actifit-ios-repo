//
//  ArenaText.swift
//  Actifit
//
//  Every piece of Arena copy, taken from Android's arena_* strings (which follow the web's
//  Arena_* keys). Kept in one file so ArenaLogicTests can scan it for wagering language:
//  entry is free, and the copy must never read like gambling.
//

import Foundation

enum ArenaText {

    static let title = "Arena"
    static let screenTitle = "The Arena"
    static let subtitle = "Fitness challenges, leagues and seasons. Earn rewards for staying active."
    static let tabOpen = "Open"
    static let tabMine = "Mine"
    static let tabResults = "Results"
    static let emptyOpen = "No open challenges right now. Check back soon."
    static let emptyMine = "You haven't joined a challenge yet. Pick one from Open."
    static let emptyMineLogin = "Log in to see your challenges."
    static let emptyResults = "No finished challenges yet."
    static let loadError = "Couldn't load the Arena. Pull down to try again."
    static let notFound = "Challenge not found."
    static let detailLoadError = "Couldn't load this challenge. Tap to try again."
    static let challenge = "Challenge"

    static let join = "Join Challenge"
    static let leave = "Leave"
    static let joined = "You are in!"
    static let joinedShort = "Joined"
    static let loginToJoin = "Log in to join this challenge"
    static let working = "Sending…"
    static let joinPending = "Recording on-chain. It may take a minute to appear on the board."
    static let leavePending = "Leaving. It may take a minute to update."
    static let actionFailed = "Something went wrong. Please try again."
    static let pendingExpired = "We couldn't confirm your last request. Please try again."
    static let closed = "This challenge has ended."

    static let length = "Length"
    static let starts = "Starts"
    static let ends = "Ends"
    static let scoredBy = "Scored by"
    static let howItWorks = "How it works"
    static let prizes = "Prizes"
    static let badgeAward = "Winners earn the badge:"
    static let fairPlay = "Rewards are earned AFIT and collectible badges. Free to enter, decided by verified activity, never pay-to-win."
    static let reportNote = "Only posted reports count. Post your daily report so today's activity scores here."
    static let standings = "Standings"
    static let noStandings = "No standings yet. Join and be the first on the board."
    static let myLeading = "You are in the lead."
    static let myUnranked = "You are not on the board yet."
    static let reportCounts = "This report counts toward your Arena challenges once it is verified."

    static let homeNoScore = "No score yet. Post today's report to get on the board."
    static let homeJoinTitle = "Join a challenge"

    static let badgesHeader = "Arena badges"
    static let community = "Community"

    // Fallback copy for challenges that carry none of their own.
    static func recurrence(_ kind: ArenaLogic.Kind) -> String {
        switch kind {
        case .league: return "League"
        case .daily: return "Daily"
        case .event, .other: return "Event"
        }
    }

    static func tagline(_ kind: ArenaLogic.Kind) -> String {
        switch kind {
        case .league: return "Compete on the leaderboard and climb the table."
        case .daily: return "Hit the daily goal and keep your streak going."
        case .event: return "A limited-time event. Join before it ends."
        case .other: return "Join the challenge and stay active."
        }
    }

    static func howItWorks(_ kind: ArenaLogic.Kind) -> String {
        switch kind {
        case .league: return "Your verified activity is ranked against everyone else in the league."
        case .daily: return "Reach the target each day to clear the challenge."
        case .event: return "A special event with its own goal and window. Take part before it closes."
        case .other: return "Take part by logging your activity before the challenge window closes."
        }
    }

    static func prize(_ kind: ArenaLogic.Kind) -> String {
        switch kind {
        case .league: return "Earn AFIT based on where you finish."
        case .daily: return "Earn AFIT for every goal you reach."
        case .event: return "Earn AFIT and event rewards."
        case .other: return "Earn AFIT for taking part."
        }
    }

    static func endsIn(days: Int, hours: Int) -> String { return "Ends in \(days)d \(hours)h" }
    static func endsIn(hours: Int, minutes: Int) -> String { return "Ends in \(hours)h \(minutes)m" }
    static func endsIn(minutes: Int) -> String { return "Ends in \(minutes)m" }
    static let ended = "Ended"
    static func ended(on date: String) -> String { return "Ended \(date)" }

    static func participants(_ n: Int) -> String { return n == 1 ? "1 participant" : "\(n) participants" }
    static func openCount(_ n: Int) -> String {
        return n == 1 ? "1 challenge is open. Free to enter." : "\(n) challenges are open. Free to enter."
    }

    static func duration(_ unit: ArenaLogic.DurationUnit, _ n: Int) -> String {
        switch unit {
        case .days: return n == 1 ? "1 day" : "\(n) days"
        case .weeks: return n == 1 ? "1 week" : "\(n) weeks"
        case .months: return n == 1 ? "1 month" : "\(n) months"
        }
    }

    static let metricActivity = "Total activity"
    static let metricGoal = "Daily goal hits"
    static func metricGoal(target: String) -> String { return "Daily goal hits (\(target))" }
    static let metricSteps = "Step count"
    static let metricDistance = "Distance"

    static func standingsUpdated(_ ago: String) -> String { return "Updated \(ago)" }
    static func rank(_ r: Int) -> String { return "#\(r)" }
    static func rewardAfit(_ amount: String) -> String { return "+\(amount) AFIT" }
    static func yourResult(rank: Int) -> String { return "You finished #\(rank)" }
    static func yourResult(rank: Int, afit: String) -> String { return "You finished #\(rank) · \(afit) AFIT earned" }
    static func homeRank(_ rank: Int, score: String) -> String { return "Rank #\(rank) · \(score)" }
    static func myRank(_ rank: Int, score: String) -> String { return "You are #\(rank) · \(score)" }
    static func myGap(_ gap: String, behind rank: Int) -> String { return "\(gap) behind #\(rank)" }
    static func todaySteps(_ steps: String) -> String {
        return "Today on this phone: \(steps) steps. They only count once you post your report."
    }
    static func todayGoal(_ steps: String, of target: String) -> String {
        return "Today on this phone: \(steps) of \(target) steps. They only count once you post your report."
    }
    static func badgeRow(_ badge: String, _ challenge: String, community: Bool) -> String {
        return community ? "\(badge) · \(challenge) · \(ArenaText.community)" : "\(badge) · \(challenge)"
    }
}

// MARK: - Display helpers shared by the Arena screens and the dashboard card

extension ArenaChallenge {

    private var kind: ArenaLogic.Kind { return ArenaLogic.kind(of: type) }

    var recurrenceText: String { return recurrence.isEmpty ? ArenaText.recurrence(kind) : recurrence }
    var taglineText: String { return tagline.isEmpty ? ArenaText.tagline(kind) : tagline }
    var howItWorksText: String { return howItWorks.isEmpty ? ArenaText.howItWorks(kind) : howItWorks }
    var prizeText: String { return prizeSummary.isEmpty ? ArenaText.prize(kind) : prizeSummary }
    var artURL: URL? { return ArenaLogic.artURL(art: art, type: type) }

    /// Open for a join or leave right now: the state allows it and the window has not closed.
    var acceptsMembershipChanges: Bool {
        return ArenaLogic.isJoinable(state) && !ArenaLogic.hasEnded(end, now: Date())
    }

    /// "Ends in 5h 12m" while running; "Ended 30 Sep 2026" once closed.
    var timeText: String {
        let now = Date()
        if !ArenaLogic.isJoinable(state) || ArenaLogic.hasEnded(end, now: now) {
            let date = ArenaFormat.date(end)
            return date.isEmpty ? ArenaText.ended : ArenaText.ended(on: date)
        }
        guard end != nil else { return "" }
        let left = ArenaLogic.remaining(until: end, now: now)
        if left.days > 0 { return ArenaText.endsIn(days: left.days, hours: left.hours) }
        if left.hours > 0 { return ArenaText.endsIn(hours: left.hours, minutes: left.minutes) }
        return ArenaText.endsIn(minutes: max(1, left.minutes))
    }

    /// The last day of a running challenge, shown in an urgent style.
    var endsWithinADay: Bool {
        guard ArenaLogic.isJoinable(state), let end = end else { return false }
        let left = end.timeIntervalSinceNow
        return left > 0 && left < 86400
    }

    var durationText: String {
        guard let d = ArenaLogic.duration(start: start, end: end) else { return "" }
        return ArenaText.duration(d.unit, d.count)
    }

    var scoredByText: String {
        switch metric {
        case "activity_count": return ArenaText.metricActivity
        case "steps": return ArenaText.metricSteps
        case "distance": return ArenaText.metricDistance
        case "goal_hit":
            // The target moves between instances, so it always comes from the challenge.
            return threshold > 0 ? ArenaText.metricGoal(target: ArenaFormat.number(threshold)) : ArenaText.metricGoal
        default: return ArenaLogic.humanize(metric)
        }
    }
}

enum ArenaFormat {

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Thousands separators, and up to two decimals so distance scores are not truncated.
    static func number(_ n: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    static func date(_ d: Date?) -> String {
        guard let d = d else { return "" }
        return dateFormatter.string(from: d)
    }

    static func relative(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: d, relativeTo: Date())
    }
}
