//
//  CompanionUtil.swift
//  Actifit
//
//  Port of the Android CompanionUtil + AuraView animal tables. Drives the
//  AuraView companion (tier from streak, animal from user pick / sport / name).
//

import UIKit

enum CompanionUtil {

    static let PREF_COMPANION = "auraCompanion"
    static let PREF_COMPANION_AUTO = "auraCompanionAuto"
    static let ACTIVE_THRESHOLD = 5000

    private static func rgb(_ v: Int) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255.0,
                green: CGFloat((v >> 8) & 0xFF) / 255.0,
                blue: CGFloat(v & 0xFF) / 255.0, alpha: 1)
    }

    // 20 animals — index-aligned parallel arrays (must match Android AuraView).
    static let names = ["Wolf","Rabbit","Mustang","Dolphin","Gorilla","Tiger","Flamingo","Eagle","Lion","Bear","Shark","Kangaroo","Fox","Panda","Turtle","Dog","Penguin","Owl","Dragon","Unicorn"]
    static let emojis = ["🐺","🐇","🐎","🐬","🦍","🐅","🦩","🦅","🦁","🐻","🦈","🦘","🦊","🐼","🐢","🐕","🐧","🦉","🐉","🦄"]
    static let lottieAssets = ["1f43a","1f407","1f40e","1f42c","1f98d","1f405","1f9a9","1f985","1f981","1f43b","1f988","1f998","1f98a","1f43c","1f422","1f415","1f427","1f989","1f409","1f984"]
    static let colors: [UIColor] = [
        rgb(0x607D8B), rgb(0xFF9800), rgb(0x8D6E63), rgb(0x00B8D4), rgb(0x5D4037),
        rgb(0xFF5722), rgb(0xEC407A), rgb(0x3F51B5), rgb(0xF9A825), rgb(0x795548),
        rgb(0x546E7A), rgb(0xA1887F), rgb(0xEF6C00), rgb(0x455A64), rgb(0x388E3C),
        rgb(0xB08968), rgb(0x37474F), rgb(0x6D4C41), rgb(0x00897B), rgb(0xAB47BC)
    ]
    static let tierNames = ["Couch","Active","Fit","Athlete","Elite","Champion"]

    static var companionCount: Int { names.count } // 20

    private static func clampIndex(_ i: Int) -> Int { min(max(i, 0), companionCount - 1) }
    static func color(_ i: Int) -> UIColor { colors[clampIndex(i)] }
    static func emoji(_ i: Int) -> String { emojis[clampIndex(i)] }
    static func lottieAsset(_ i: Int) -> String { lottieAssets[clampIndex(i)] }
    static func name(_ i: Int) -> String { names[clampIndex(i)] }
    static func tierName(_ level: Int) -> String { tierNames[min(max(level, 0), tierNames.count - 1)] }

    /// Sport → animal index (used by the profile auto-cache).
    static func animalForActivity(_ activityType: String?) -> Int {
        guard let a = activityType?.lowercased() else { return 7 } // EAGLE
        func has(_ ks: [String]) -> Bool { ks.contains { a.contains($0) } }
        if has(["run","jog","sprint","marathon"]) { return 1 }               // RABBIT
        if has(["walk","hik","trek","step"]) { return 0 }                    // WOLF
        if has(["cycl","bike","bik","spin"]) { return 2 }                    // MUSTANG
        if has(["swim","dive","aqua"]) { return 3 }                          // DOLPHIN
        if has(["weight","strength","lift","crossfit","gym","box","mma","martial","karate","judo","bootcamp"]) { return 4 } // GORILLA
        if has(["yoga","pilates","stretch","balance","medit","barre"]) { return 6 } // FLAMINGO
        if has(["basket","foot","soccer","tennis","cricket","sport","hiit","aerobic","cardio","dance","zumba","badminton"]) { return 5 } // TIGER
        return 7 // EAGLE
    }

    static func isWilting(streak: Int, todaySteps: Int, hourOfDay: Int) -> Bool {
        return streak >= 1 && todaySteps < ACTIVE_THRESHOLD && hourOfDay >= 16
    }

    /// Deterministic name hash → 0..count-1 (matches Java 32-bit String.hashCode).
    static func companionForName(_ name: String?) -> Int {
        guard let name = name, !name.isEmpty else { return 0 }
        var h: Int32 = 0
        for u in name.utf16 { h = h &* 31 &+ Int32(u) }
        return Int(abs(Int64(h))) % companionCount
    }

    /// explicit pick → sport auto-cache → name-hash fallback.
    static func resolveCompanion(username: String, isSelf: Bool) -> Int {
        let fallback = companionForName(username)
        let d = UserDefaults.standard
        if isSelf {
            if d.object(forKey: PREF_COMPANION) != nil { return clampIndex(d.integer(forKey: PREF_COMPANION)) }
            if d.object(forKey: PREF_COMPANION_AUTO) != nil { return clampIndex(d.integer(forKey: PREF_COMPANION_AUTO)) }
        }
        return fallback
    }

    /// Tier (0..5) from streak — drives aura size/glow.
    static func levelFromStreak(_ streak: Int) -> Int {
        if streak <= 0 { return 0 }   // Couch
        if streak <= 2 { return 1 }   // Active
        if streak <= 6 { return 2 }   // Fit
        if streak <= 29 { return 3 }  // Athlete
        if streak <= 99 { return 4 }  // Elite
        return 5                      // Champion
    }

    /// Tier (0..5) from rank string (for other users).
    static func levelFromRank(_ rankStr: String) -> Int {
        guard let rank = Float(rankStr) else { return 0 }
        if rank < 20 { return 0 }
        if rank < 60 { return 1 }
        if rank < 150 { return 2 }
        if rank < 400 { return 3 }
        if rank < 1000 { return 4 }
        return 5
    }
}
