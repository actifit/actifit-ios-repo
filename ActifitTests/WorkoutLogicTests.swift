//
//  WorkoutLogicTests.swift
//  ActifitTests
//
//  The Workout Wizard's prompt, Gemini reply parsing, exercise matching and the fee operation.
//

import XCTest

final class WorkoutLogicTests: XCTestCase {

    private func geminiReply(_ text: String, finish: String = "STOP") -> Data {
        let obj: [String: Any] = ["candidates": [["content": ["parts": [["text": text]]], "finishReason": finish]]]
        return try! JSONSerialization.data(withJSONObject: obj)
    }

    private let planJSON = """
    ```json
    {"workoutPlan": {"description": "Three full-body days", "exercises": [
      {"name": "Push-ups", "sets": "3", "reps": "12", "duration": "5 minutes", "days": ["Monday", "Friday"]},
      {"name": "Barbell Squat", "sets": 4, "reps": "8-10", "days": "Monday, Wednesday"}
    ]}, "explanation": "Builds strength."}
    ```
    """

    func testParsesAFencedPlanWithNumbersAndCommaDays() throws {
        let out = try WorkoutAIParser.plan(from: geminiReply(planJSON))
        XCTAssertEqual(out.explanation, "Builds strength.")
        XCTAssertEqual(out.plan.description, "Three full-body days")
        XCTAssertEqual(out.plan.exercises.count, 2)
        XCTAssertEqual(out.plan.exercises[0].days ?? [], ["Monday", "Friday"])
        XCTAssertEqual(out.plan.exercises[1].sets, "4")
        XCTAssertEqual(out.plan.exercises[1].days ?? [], ["Monday", "Wednesday"])
        XCTAssertNil(out.plan.exercises[1].duration)
    }

    func testRejectsPlansMissingFields() {
        let noDays = "{\"workoutPlan\": {\"description\": \"d\", \"exercises\": [{\"name\": \"A\", \"sets\": \"1\", \"reps\": \"2\"}]}, \"explanation\": \"e\"}"
        XCTAssertThrowsError(try WorkoutAIParser.plan(from: geminiReply(noDays)))
        let empty = "{\"workoutPlan\": {\"description\": \"d\", \"exercises\": []}, \"explanation\": \"e\"}"
        XCTAssertThrowsError(try WorkoutAIParser.plan(from: geminiReply(empty)))
        XCTAssertThrowsError(try WorkoutAIParser.plan(from: geminiReply("Sorry, I can't help with that.")))
    }

    func testBlockedRepliesAreReportedAsBlocked() {
        XCTAssertThrowsError(try WorkoutAIParser.plan(from: geminiReply("", finish: "SAFETY"))) { e in
            XCTAssertEqual(e as? WorkoutAIError, .blocked)
        }
        let feedback = try! JSONSerialization.data(withJSONObject: ["promptFeedback": ["blockReason": "OTHER"]])
        XCTAssertThrowsError(try WorkoutAIParser.text(from: feedback)) { e in
            XCTAssertEqual(e as? WorkoutAIError, .blocked)
        }
    }

    func testPromptMatchesAndroid() {
        var r = WorkoutRequest(fitnessGoal: "Build Muscle", experienceLevel: "Beginner", weeklyTime: "2–3 hours",
                               preferredWorkout: "Yoga", equipment: "No Equipment", limitations: "None",
                               otherLimitations: "", dailyFrequency: "3 days a week")
        XCTAssertTrue(r.prompt.hasPrefix("I am a user with the following fitness details. My fitness goal is to: Build Muscle. "))
        XCTAssertTrue(r.prompt.contains("I intend to work out 3 days a week per week. "))
        XCTAssertTrue(r.prompt.contains(". And my physical limitations are: None."))
        XCTAssertFalse(r.prompt.contains("details on limitations"))
        r.otherLimitations = "bad knee"
        XCTAssertTrue(r.prompt.contains(". with the following details on limitations: bad knee."))
    }

    func testMatchingPrefersExactThenWordOverlap() {
        let lib = ExerciseLibrary.decode(Data("""
        [{"name": "Pushups", "id": "Pushups", "images": ["Pushups/0.jpg"]},
         {"name": "Barbell Full Squat", "id": "Barbell_Full_Squat"},
         {"name": "Push-Up Wide", "id": "Push_Up_Wide"}]
        """.utf8))
        XCTAssertEqual(lib.count, 3)
        XCTAssertEqual(ExerciseLibrary.match("pushups ", in: lib)?.id, "Pushups")
        XCTAssertEqual(ExerciseLibrary.match("Barbell Squats", in: lib)?.id, "Barbell_Full_Squat")
        XCTAssertNil(ExerciseLibrary.match("Swimming", in: lib))
        let e = WorkoutExercise(name: "Pushups", sets: "3", reps: "10").enriched(from: lib[0])
        XCTAssertEqual(e.startImageURL?.absoluteString, WorkoutExercise.imageBaseURL + "Pushups/0.jpg")
        XCTAssertNil(e.endImageURL)
    }

    func testFilterCombinesSearchAndFilters() {
        let lib = ExerciseLibrary.decode(Data("""
        [{"name": "Plank", "level": "beginner", "primaryMuscles": ["abdominals"]},
         {"name": "Side Plank", "level": "intermediate", "primaryMuscles": ["abdominals"]},
         {"name": "Curl", "level": "beginner", "primaryMuscles": ["biceps"]}]
        """.utf8))
        XCTAssertEqual(ExerciseLibrary.filter(lib, text: "plank", level: nil, equipment: nil, category: nil, muscle: nil).count, 2)
        XCTAssertEqual(ExerciseLibrary.filter(lib, text: "", level: "beginner", equipment: nil, category: nil, muscle: "abdominals").map { $0.name }, ["Plank"])
        XCTAssertEqual(ExerciseLibrary.values(lib) { $0.primaryMuscles ?? [] }, ["abdominals", "biceps"])
    }

    func testSavedWorkoutsDecodeAndRoundTrip() throws {
        let json: [String: Any] = ["_id": "abc", "workoutName": "Legs", "description": "d", "explanation": "e",
                                   "timestamp": 1761900000000.0,
                                   "exercises": [["name": "Lunge", "sets": "3", "reps": "10", "days": ["Monday"]]]]
        let plan = try XCTUnwrap(WorkoutPlan(json: json))
        XCTAssertEqual(plan.id, "abc")
        XCTAssertEqual(plan.timestamp, Date(timeIntervalSince1970: 1761900000))
        let out = try XCTUnwrap(plan.exercisesJSON.first as? [String: Any])
        XCTAssertEqual(out["name"] as? String, "Lunge")
        XCTAssertNil(out["images"], "missing fields are left out, as Gson does")
        XCTAssertNotNil(WorkoutPlan.date("2026-10-31T10:00:00.000Z"))
    }

    func testSummarySkipsPlaceholders() {
        XCTAssertEqual(WorkoutExercise(name: "a", sets: "3", reps: "12").summary, "3 sets × 12 reps")
        XCTAssertEqual(WorkoutExercise(name: "a", sets: "1", reps: "N/A", duration: "30 seconds").summary, "1 set · 30 seconds")
        XCTAssertEqual(WorkoutExercise(name: "a", sets: "2", reps: "8-10 per leg", duration: "n/a").summary, "2 sets × 8-10 per leg")
        XCTAssertEqual(WorkoutExercise(name: "a").summary, "")
    }

    func testReplyChecks() {
        XCTAssertTrue(WorkoutReply.isSuccess(["success": true]))
        XCTAssertTrue(WorkoutReply.isSuccess(["status": "success"]))
        XCTAssertFalse(WorkoutReply.isSuccess(["success": true, "error": "x"]))
        XCTAssertFalse(WorkoutReply.isSuccess(["status": "error"]))
        XCTAssertEqual(WorkoutReply.message(["message": "m", "error": "e"]), "e")
    }

    func testFeeOperationMatchesAndroidByteForByte() {
        XCTAssertEqual(GadgetOps.generateWorkout(user: "mcfarhat").json,
                       HiveOp.postingJson(account: "mcfarhat", id: "actifit", json: "{\"transaction\": \"generate-workout-wizard\"}").json)
    }
}
