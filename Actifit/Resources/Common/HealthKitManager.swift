//
//  HealthKitManager.swift
//  Actifit
//
//  Created by Ali Jaber on 11/07/2024.
//

import HealthKit
import UIKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.example.HealthKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "HealthKit is unavailable"]))
            return
        }

        // Read steps plus walking/running distance and active energy so the dashboard can
        // show real distance/calories (not just a step estimate) when Health has the data.
        var read: Set<HKObjectType> = []
        [HKQuantityTypeIdentifier.stepCount,
         .distanceWalkingRunning,
         .activeEnergyBurned].forEach {
            if let t = HKObjectType.quantityType(forIdentifier: $0) { read.insert(t) }
        }
        healthStore.requestAuthorization(toShare: [], read: read) { (success, error) in
            completion(success, error)
        }
    }

    func retrieveStepCount(completion: @escaping (Double) -> Void) {
        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepsCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount = 0.0

            guard let result = result else {
                print("Failed to fetch steps = \(String(describing: error?.localizedDescription))")
                completion(resultCount)
                return
            }

            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
            }

            completion(resultCount)
        }

        healthStore.execute(query)
    }

    /// Today's steps plus real distance (metres) and active calories (kcal) from Health.
    /// distanceMeters / kcal come back as `-1` when Health has no data source for that
    /// metric today, so callers can fall back to a step-derived estimate (Android parity).
    func retrieveTodayMetrics(completion: @escaping (_ steps: Double, _ distanceMeters: Double, _ kcal: Double) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        var steps = 0.0, distanceMeters = -1.0, kcal = -1.0
        let group = DispatchGroup()

        func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, assign: @escaping (Double) -> Void) {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { return }
            group.enter()
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let s = result?.sumQuantity() { assign(s.doubleValue(for: unit)) }
                group.leave()
            }
            healthStore.execute(query)
        }

        sum(.stepCount, unit: .count()) { steps = $0 }
        sum(.distanceWalkingRunning, unit: .meter()) { distanceMeters = $0 }
        sum(.activeEnergyBurned, unit: .kilocalorie()) { kcal = $0 }

        group.notify(queue: .main) { completion(steps, distanceMeters, kcal) }
    }
}
