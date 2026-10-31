//
//  WorkoutLogic.swift
//  Actifit
//
//  The AI Workout Wizard's models and rules, ported from Android (Exercise, WorkoutPlan,
//  WorkoutRequest, AiService's prompt and parser, Utils.findMatchingExercise). Foundation only,
//  so ActifitTests can cover it.
//

import Foundation

/// One exercise, as the AI returns it, as the backend stores it, and as the bundled exercise
/// library (exercises.json, from yuhonas/free-exercise-db) describes it. Every field but the
/// name is optional; the encoded form skips missing fields, as Android's Gson does.
struct WorkoutExercise: Codable, Equatable, Hashable {
    var name: String
    var sets: String?
    var reps: String?
    var duration: String?
    var images: [String]?
    var days: [String]?
    var bodyPart: String?
    var equipment: String?
    var id: String?
    var target: String?
    var primaryMuscles: [String]?
    var secondaryMuscles: [String]?
    var instructions: [String]?
    var level: String?
    var category: String?
    var force: String?
    var mechanic: String?

    static let imageBaseURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"

    init(name: String, sets: String? = nil, reps: String? = nil, duration: String? = nil, days: [String]? = nil) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.days = days
    }

    private enum CodingKeys: String, CodingKey {
        case name, sets, reps, duration, images, days, bodyPart, equipment, id, target,
             primaryMuscles, secondaryMuscles, instructions, level, category, force, mechanic
    }

    /// Lenient: the AI and older saved workouts sometimes send numbers where strings are
    /// expected, or the days as one comma-separated string.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.flexString(.name) ?? ""
        sets = c.flexString(.sets)
        reps = c.flexString(.reps)
        duration = c.flexString(.duration)
        images = c.flexList(.images)
        days = c.flexList(.days)
        bodyPart = c.flexString(.bodyPart)
        equipment = c.flexString(.equipment)
        id = c.flexString(.id)
        target = c.flexString(.target)
        primaryMuscles = c.flexList(.primaryMuscles)
        secondaryMuscles = c.flexList(.secondaryMuscles)
        instructions = c.flexList(.instructions)
        level = c.flexString(.level)
        category = c.flexString(.category)
        force = c.flexString(.force)
        mechanic = c.flexString(.mechanic)
    }

    var startImageURL: URL? { return imageURL(0) }
    var endImageURL: URL? { return imageURL(1) }

    private func imageURL(_ i: Int) -> URL? {
        guard let images = images, images.count > i, !images[i].isEmpty else { return nil }
        if images[i].hasPrefix("http") { return URL(string: images[i]) }
        return URL(string: WorkoutExercise.imageBaseURL + images[i])
    }

    /// "3 sets × 10 reps · 30 seconds"; empty parts are left out.
    var summary: String {
        var parts: [String] = []
        if let s = WorkoutExercise.shown(sets) { parts.append(s.wkIsNumber ? s + (s == "1" ? " set" : " sets") : s) }
        if let r = WorkoutExercise.shown(reps) { parts.append(r.wkIsNumber ? r + (r == "1" ? " rep" : " reps") : r) }
        var line = parts.joined(separator: " × ")
        if let d = WorkoutExercise.shown(duration) {
            line += line.isEmpty ? d : " · " + d
        }
        return line
    }

    /// nil for blanks and the model's placeholders ("N/A", "-").
    private static func shown(_ value: String?) -> String? {
        guard let v = value?.wkTrimmed, !v.isEmpty, !["n/a", "na", "-", "none", "0"].contains(v.lowercased()) else { return nil }
        return v
    }

    /// Fills in the pictures, muscles and instructions from the library entry.
    func enriched(from model: WorkoutExercise?) -> WorkoutExercise {
        guard let m = model else { return self }
        var e = self
        e.images = m.images
        e.bodyPart = m.bodyPart
        e.equipment = m.equipment
        e.target = m.target
        e.primaryMuscles = m.primaryMuscles
        e.secondaryMuscles = m.secondaryMuscles
        e.instructions = m.instructions
        return e
    }
}

/// A saved or freshly generated workout.
struct WorkoutPlan: Equatable {
    var id: String?
    var workoutName: String
    var description: String
    var explanation: String
    var exercises: [WorkoutExercise]
    var timestamp: Date?

    /// One entry of GET /workouts. nil when it has no exercises list.
    init?(json: [String: Any]) {
        guard let list = json["exercises"] as? [Any],
              let data = try? JSONSerialization.data(withJSONObject: list),
              let exercises = try? JSONDecoder().decode([WorkoutExercise].self, from: data) else { return nil }
        id = json["_id"] as? String
        workoutName = json["workoutName"] as? String ?? ""
        description = json["description"] as? String ?? ""
        explanation = json["explanation"] as? String ?? ""
        self.exercises = exercises.filter { !$0.name.isEmpty }
        timestamp = WorkoutPlan.date(json["timestamp"])
    }

    init(id: String? = nil, workoutName: String, description: String, explanation: String,
         exercises: [WorkoutExercise], timestamp: Date? = nil) {
        self.id = id
        self.workoutName = workoutName
        self.description = description
        self.explanation = explanation
        self.exercises = exercises
        self.timestamp = timestamp
    }

    /// The exercises as JSON objects, for the save and update bodies.
    var exercisesJSON: [Any] {
        guard let data = try? JSONEncoder().encode(exercises),
              let list = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else { return [] }
        return list
    }

    /// The backend stores milliseconds; Mongo may hand back an ISO date instead.
    static func date(_ value: Any?) -> Date? {
        if let n = value as? Double { return Date(timeIntervalSince1970: n > 1e11 ? n / 1000 : n) }
        if let n = value as? Int { return date(Double(n)) }
        guard let s = value as? String else { return nil }
        if let n = Double(s) { return date(n) }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: s)
    }
}

/// What the user picked in the wizard. The values go into the prompt in English (as on Android).
struct WorkoutRequest: Equatable {
    var fitnessGoal: String
    var experienceLevel: String
    var weeklyTime: String
    var preferredWorkout: String
    var equipment: String
    var limitations: String
    var otherLimitations: String
    var dailyFrequency: String

    /// Android's prompt, word for word, so both apps get the same kind of plan.
    var prompt: String {
        var p = "I am a user with the following fitness details. My fitness goal is to: " + fitnessGoal
            + ". I would describe my current experience level as: " + experienceLevel
            + ". I can allocate " + weeklyTime + " to workouts each week. "
            + "I intend to work out " + dailyFrequency + " per week. "
            + "I generally prefer " + preferredWorkout + " style workouts. "
            + "I have the following equipment: " + equipment
        if !limitations.isEmpty { p += ". And my physical limitations are: " + limitations }
        if !otherLimitations.isEmpty { p += ". with the following details on limitations: " + otherLimitations }
        p += ". Based on this information can you give me a detailed workout plan and a brief explanation for it."
            + "Response should be in JSON format with the fields workoutPlan and explanation. "
            + "workoutPlan should have description and a list of exercises each with name, reps, sets, "
            + "duration, "
            + "and a field days, specifying a list of days the exercise is to be performed on. "
            + "Ensure that all string values for name, sets, reps, duration, and days should be wrapped in double quotes."
        return p
    }
}

/// The wizard's choices (Android's string arrays; English only there too).
enum WorkoutOptions {
    static let fitnessGoals = ["Lose Weight", "Build Muscle", "Improve Cardiovascular Health", "Increase Strength",
                               "Enhance Flexibility", "Improve Endurance", "General Fitness", "Reduce Stress"]
    static let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    static let weeklyTimes = ["1–2 hours", "2–3 hours", "3–4 hours", "4–5 hours", "5–6 hours", "6–7 hours", "7+ hours"]
    static let dailyFrequencies = ["1 day a week", "2 days a week", "3 days a week", "4 days a week",
                                   "5 days a week", "6 days a week", "Every day"]
    static let defaultFrequency = "3 days a week"
    static let workoutStyles = ["Cardio", "Strength Training", "Yoga", "Pilates", "High Intensity Interval Training (HIIT)",
                                "Flexibility and Stretching", "Bodyweight Exercises", "Mix of all", "Running", "Swimming"]
    static let equipment = ["Full Gym Access", "Home Equipment (Dumbbells, resistance bands etc)",
                            "Limited Home Equipment", "No Equipment"]
    static let limitations = ["None", "Joint Pain", "Back Pain", "Limited mobility", "Other"]
    static let other = "Other"

    /// Generating a plan costs this much AFIT (Android Constants.MIN_AFIT_PER_WORKOUT).
    static let feeAfit = 300
}

enum WorkoutAIError: Error, Equatable {
    case blocked
    case badFormat(String)
}

/// Reads Gemini's generateContent reply.
enum WorkoutAIParser {

    /// The text of the first candidate. Throws .blocked when Google refused the prompt or reply.
    static func text(from data: Data) throws -> String {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw WorkoutAIError.badFormat("Not JSON")
        }
        if let feedback = root["promptFeedback"] as? [String: Any], feedback["blockReason"] != nil {
            throw WorkoutAIError.blocked
        }
        guard let candidate = (root["candidates"] as? [[String: Any]])?.first else {
            throw WorkoutAIError.badFormat("No candidates present in response")
        }
        if let reason = candidate["finishReason"] as? String, reason == "SAFETY" || reason == "PROHIBITED_CONTENT" {
            throw WorkoutAIError.blocked
        }
        guard let parts = (candidate["content"] as? [String: Any])?["parts"] as? [[String: Any]],
              let text = parts.compactMap({ $0["text"] as? String }).first else {
            throw WorkoutAIError.badFormat("No parts in response")
        }
        return text
    }

    /// The model wraps its JSON in a ```json fence more often than not.
    static func stripFence(_ content: String) -> String {
        var s = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            s = String(s.dropFirst(3))
            if s.lowercased().hasPrefix("json") { s = String(s.dropFirst(4)) }
        }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The plan (unnamed) and the explanation from a generateContent reply.
    static func plan(from data: Data) throws -> (plan: WorkoutPlan, explanation: String) {
        let content = stripFence(try text(from: data))
        guard let obj = (try? JSONSerialization.jsonObject(with: Data(content.utf8))) as? [String: Any],
              let planObj = obj["workoutPlan"] as? [String: Any],
              let explanation = obj["explanation"] as? String else {
            throw WorkoutAIError.badFormat("Invalid content format, missing workoutPlan or explanation")
        }
        guard let description = planObj["description"] as? String,
              let list = planObj["exercises"] as? [[String: Any]], !list.isEmpty else {
            throw WorkoutAIError.badFormat("Invalid workoutPlan format, missing description or exercises")
        }
        var exercises: [WorkoutExercise] = []
        for item in list {
            guard let data = try? JSONSerialization.data(withJSONObject: item),
                  let e = try? JSONDecoder().decode(WorkoutExercise.self, from: data),
                  !e.name.isEmpty, e.sets != nil, e.reps != nil, item["days"] != nil else {
                throw WorkoutAIError.badFormat("Invalid exercise format, missing name, sets, reps, or days")
            }
            // The library supplies pictures; whatever the model invented is dropped (as on Android).
            exercises.append(WorkoutExercise(name: e.name, sets: e.sets, reps: e.reps, duration: e.duration, days: e.days ?? []))
        }
        return (WorkoutPlan(workoutName: "", description: description, explanation: explanation, exercises: exercises), explanation)
    }
}

/// The bundled exercise library and the name matching used to illustrate AI exercises.
enum ExerciseLibrary {

    static func decode(_ data: Data) -> [WorkoutExercise] {
        return ((try? JSONDecoder().decode([WorkoutExercise].self, from: data)) ?? []).filter { !$0.name.isEmpty }
    }

    private static let stopWords: Set<String> = ["the", "a", "an", "with", "of", "and"]

    private static func normalize(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func words(_ s: String) -> Set<String> {
        return Set(s.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }).map(String.init)).subtracting(stopWords)
    }

    /// The library entry for an AI exercise name: the exact name, else the one sharing the most
    /// words (a plural counts as the same word). Ties go to the first in library order.
    static func match(_ name: String, in library: [WorkoutExercise]) -> WorkoutExercise? {
        let target = normalize(name)
        guard !target.isEmpty else { return nil }
        if let exact = library.first(where: { normalize($0.name) == target }) { return exact }
        let aiWords = words(target)
        var best: WorkoutExercise?
        var bestScore = 0
        for entry in library {
            let dbWords = words(normalize(entry.name))
            var score = 0
            for a in aiWords {
                for d in dbWords where d == a || d == a + "s" || a == d + "s" { score += 1 }
            }
            if score > bestScore {
                bestScore = score
                best = entry
            }
        }
        return best
    }

    /// Distinct non-empty values, sorted, for a filter menu.
    static func values(_ library: [WorkoutExercise], _ pick: (WorkoutExercise) -> [String]) -> [String] {
        return Array(Set(library.flatMap(pick).filter { !$0.isEmpty })).sorted()
    }

    /// Name search plus the filters (nil means any).
    static func filter(_ library: [WorkoutExercise], text: String, level: String?, equipment: String?,
                       category: String?, muscle: String?) -> [WorkoutExercise] {
        let q = normalize(text)
        return library.filter { e in
            (q.isEmpty || e.name.lowercased().contains(q))
                && (level == nil || e.level == level)
                && (equipment == nil || e.equipment == equipment)
                && (category == nil || e.category == category)
                && (muscle == nil || (e.primaryMuscles ?? []).contains(muscle!))
        }
    }
}

/// Backend reply checks (WorkoutApiClient).
enum WorkoutReply {
    /// Save, list and update: no "error" field, and success true or status "success".
    static func isSuccess(_ json: [String: Any]) -> Bool {
        if let err = json["error"], !(err is NSNull) { return false }
        return (json["success"] as? Bool) == true || (json["status"] as? String) == "success"
    }

    static func message(_ json: [String: Any]?) -> String? {
        guard let json = json else { return nil }
        if let e = json["error"] as? String, !e.isEmpty { return e }
        if let m = json["message"] as? String, !m.isEmpty { return m }
        return nil
    }
}

private extension KeyedDecodingContainer {
    func flexString(_ key: Key) -> String? {
        if let s = (try? decodeIfPresent(String.self, forKey: key)) ?? nil { return s }
        if let i = (try? decodeIfPresent(Int.self, forKey: key)) ?? nil { return String(i) }
        if let d = (try? decodeIfPresent(Double.self, forKey: key)) ?? nil { return String(d) }
        return nil
    }

    func flexList(_ key: Key) -> [String]? {
        if let list = (try? decodeIfPresent([String].self, forKey: key)) ?? nil { return list }
        if let s = (try? decodeIfPresent(String.self, forKey: key)) ?? nil {
            return s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        return nil
    }
}

private extension String {
    var wkTrimmed: String { return trimmingCharacters(in: .whitespacesAndNewlines) }
    var wkIsNumber: Bool { return !isEmpty && allSatisfy { $0.isNumber } }
}
