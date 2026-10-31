//
//  WorkoutService.swift
//  Actifit
//
//  Network calls for the AI Workout Wizard: the saved-workout routes on api.actifit.io
//  (Android WorkoutApiClient) and the Gemini request (Android AiService.generateWorkoutPlan).
//  Every completion runs on the main queue.
//

import Foundation

enum WorkoutService {

    typealias Done<T> = (Result<T, WorkoutServiceError>) -> Void

    private static let base = "https://api.actifit.io/"
    private static let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    // MARK: - Saved workouts

    static func fetch(user: String, done: @escaping Done<[WorkoutPlan]>) {
        call("GET", "workouts/?user=" + enc(user), body: nil) { result in
            done(result.flatMap { json in
                guard let list = json["data"] as? [[String: Any]] else { return .failure(.message(WorkoutText.badResponse)) }
                return .success(list.compactMap(WorkoutPlan.init(json:)))
            })
        }
    }

    static func save(user: String, plan: WorkoutPlan, done: @escaping Done<Void>) {
        let body: [String: Any] = [
            "userId": user,
            "workoutName": plan.workoutName,
            "description": plan.description,
            "explanation": plan.explanation,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "exercises": plan.exercisesJSON
        ]
        call("POST", "saveworkout/?user=" + enc(user), body: body) { done($0.map { _ in () }) }
    }

    static func update(user: String, plan: WorkoutPlan, done: @escaping Done<Void>) {
        guard let id = plan.id, !id.isEmpty else { return done(.failure(.message(WorkoutText.badResponse))) }
        let body: [String: Any] = [
            "workoutName": plan.workoutName,
            "description": plan.description,
            "explanation": plan.explanation,
            "exercises": plan.exercisesJSON
        ]
        call("PUT", "workouts/" + enc(id) + "?user=" + enc(user), body: body) { done($0.map { _ in () }) }
    }

    static func delete(user: String, id: String, done: @escaping Done<Void>) {
        call("DELETE", "workouts/" + enc(id) + "?user=" + enc(user), body: nil) { done($0.map { _ in () }) }
    }

    /// Sends one request with the session token. Success needs no "error" and success/status set.
    private static func call(_ method: String, _ path: String, body: [String: Any]?,
                             done: @escaping (Result<[String: Any], WorkoutServiceError>) -> Void) {
        guard !UserDefaults.standard.authToken.isEmpty else { return done(.failure(.session)) }
        guard let url = URL(string: base + path) else { return done(.failure(.message(WorkoutText.badResponse))) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = method
        request.addBroadCastHeaderWhenAfitSent()   // Content-Type and x-acti-token
        if let body = body { request.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        URLSession.shared.dataTask(with: request) { data, response, error in
            let json = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let result: Result<[String: Any], WorkoutServiceError>
            if let json = json, WorkoutReply.isSuccess(json) {
                result = .success(json)
            } else if status == 401 || status == 403 {
                result = .failure(.session)
            } else if let m = WorkoutReply.message(json) {
                result = .failure(.message(m))
            } else if let error = error {
                result = .failure(.message(error.localizedDescription))
            } else {
                result = .failure(.message(status > 0 ? WorkoutText.serverError(status) : WorkoutText.badResponse))
            }
            DispatchQueue.main.async { done(result) }
        }.resume()
    }

    // MARK: - AI

    /// Asks Gemini for a plan. A plan can take 45 s or more; 503 (overloaded) is retried twice.
    static func generate(_ request: WorkoutRequest, done: @escaping Done<(plan: WorkoutPlan, explanation: String)>) {
        generate(request, attempt: 0, done: done)
    }

    private static func generate(_ workout: WorkoutRequest, attempt: Int,
                                 done: @escaping Done<(plan: WorkoutPlan, explanation: String)>) {
        guard let url = URL(string: geminiURL) else { return done(.failure(.message(WorkoutText.badResponse))) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.geminiApiKey, forHTTPHeaderField: "x-goog-api-key")
        let body: [String: Any] = ["contents": [["parts": [["text": workout.prompt]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 503 && attempt < 2 {
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(attempt + 1) * 1.5) {
                    generate(workout, attempt: attempt + 1, done: done)
                }
                return
            }
            let result: Result<(plan: WorkoutPlan, explanation: String), WorkoutServiceError>
            if let error = error {
                result = .failure(.message(error.localizedDescription))
            } else if status != 200 || data == nil {
                result = .failure(.message(WorkoutText.serverError(status)))
            } else {
                do {
                    result = .success(try WorkoutAIParser.plan(from: data!))
                } catch WorkoutAIError.blocked {
                    result = .failure(.message(WorkoutText.blocked))
                } catch {
                    result = .failure(.message(WorkoutText.badPlan))
                }
            }
            DispatchQueue.main.async { done(result) }
        }.resume()
    }

    private static func enc(_ s: String) -> String { return HiveURL.component(s) }
}

enum WorkoutServiceError: Error {
    case session
    case message(String)

    var text: String {
        switch self {
        case .session: return GadgetText.sessionExpired
        case .message(let m): return m
        }
    }
}
