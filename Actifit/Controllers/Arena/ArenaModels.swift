//
//  ArenaModels.swift
//  Actifit
//
//  Arena challenge docs as returned by `arena/challenges` (list) and `arena/challenges/:id`
//  (detail, which also carries participants). Parsed leniently: a missing or new field never
//  breaks a screen. Foundation only, so the parsing is covered by ActifitTests.
//

import Foundation

struct ArenaParticipant {
    var entity = ""
    var state = ""
    /// nil until the challenge is settled.
    var resultRank: Int?
    var rewardAfit: Double = 0
    var earnedBadges: [String] = []

    var isActive: Bool { return state != "left" }
}

struct ArenaStandingRow {
    var entity = ""
    var rank = 0
    /// Distance-scored challenges are fractional.
    var score: Double = 0
}

/// A badge a user earned, from `arena/badges/:user`.
struct ArenaBadge {
    var name = ""
    var challengeTitle = ""
    /// A badge name is free text chosen by a challenge creator; only official ones are unmarked.
    var official = false
}

struct ArenaChallenge {
    var id = ""
    var title = ""
    var type = ""
    var state = ""
    /// "official" for Actifit's own challenges; anything else was created by a user.
    var originTier = ""
    var art: String?
    var recurrence = ""
    var tagline = ""
    var howItWorks = ""
    var prizeSummary = ""
    var metric = ""
    /// Read from the doc every time; it has already changed between instances.
    var threshold: Double = 0
    var start: Date?
    var end: Date?
    var offeredBadges: [String] = []

    // Filled from the detail call only.
    var participantCount: Int?
    var serverJoined = false
    var participants: [ArenaParticipant] = []

    init() {}

    init(json o: [String: Any]) {
        id = str(o["id"])
        type = str(o["type"])
        state = str(o["state"])
        originTier = str(o["origin_tier"])
        title = str(o["title"])
        if title.isEmpty { title = id }
        let rawArt = str(o["art"])
        art = rawArt.isEmpty ? nil : rawArt
        recurrence = str(o["recurrence"])
        tagline = str(o["tagline"])
        howItWorks = str(o["how_it_works"])
        // Older docs may carry a single `description` instead of the split copy.
        let description = str(o["description"])
        if tagline.isEmpty { tagline = description }
        if howItWorks.isEmpty { howItWorks = description }
        prizeSummary = str(o["prize_summary"])

        if let window = o["window"] as? [String: Any] {
            start = ArenaLogic.parseDate(str(window["start"]))
            end = ArenaLogic.parseDate(str(window["end"]))
        }
        if let scoring = o["scoring"] as? [String: Any] {
            metric = str(scoring["metric"])
            threshold = num(scoring["threshold"])
        }
        if let rewards = o["rewards"] as? [String: Any] {
            let summary = str(rewards["summary"])
            if !summary.isEmpty { prizeSummary = summary }
            offeredBadges = strings(rewards["badges"])
        }
    }

    /// Parses the `{ challenge, participants }` detail envelope; nil if it has no challenge.
    static func fromDetail(_ envelope: [String: Any], viewer: String) -> ArenaChallenge? {
        guard let ch = envelope["challenge"] as? [String: Any] else { return nil }
        var c = ArenaChallenge(json: ch)
        for po in (envelope["participants"] as? [[String: Any]]) ?? [] {
            var p = ArenaParticipant()
            p.entity = str(po["entity"])
            p.state = str(po["state"])
            if let result = po["result"] as? [String: Any] {
                if let rank = result["rank"] as? NSNumber { p.resultRank = rank.intValue }
                if let reward = result["reward"] as? [String: Any] {
                    p.rewardAfit = num(reward["afit"])
                    p.earnedBadges = strings(reward["badges"])
                }
            }
            c.participants.append(p)
            if p.isActive && !viewer.isEmpty && p.entity == viewer { c.serverJoined = true }
        }
        c.participantCount = c.participants.filter { $0.isActive }.count
        return c
    }

    func participant(_ entity: String) -> ArenaParticipant? {
        return participants.first { $0.entity == entity }
    }

    static func standings(from doc: [String: Any]) -> [ArenaStandingRow] {
        var rows: [ArenaStandingRow] = []
        for (i, ro) in ((doc["rows"] as? [[String: Any]]) ?? []).enumerated() {
            var r = ArenaStandingRow()
            r.entity = str(ro["entity"])
            r.rank = (ro["rank"] as? NSNumber)?.intValue ?? i + 1
            r.score = num(ro["score"])
            if !r.entity.isEmpty { rows.append(r) }
        }
        return rows
    }

    static func badges(from doc: [String: Any]) -> [ArenaBadge] {
        return ((doc["badges"] as? [[String: Any]]) ?? []).compactMap { bo in
            var b = ArenaBadge()
            b.name = str(bo["badge"])
            b.challengeTitle = str(bo["title"])
            b.official = str(bo["origin_tier"]) == "official"
            return b.name.isEmpty ? nil : b
        }
    }
}

private func str(_ v: Any?) -> String {
    return (v as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

private func num(_ v: Any?) -> Double {
    if let n = v as? NSNumber { return n.doubleValue }
    if let s = v as? String { return Double(s) ?? 0 }
    return 0
}

private func strings(_ v: Any?) -> [String] {
    return ((v as? [Any]) ?? []).map { str($0) }.filter { !$0.isEmpty }
}
