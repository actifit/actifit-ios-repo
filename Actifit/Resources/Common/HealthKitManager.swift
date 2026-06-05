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

        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepsCount]) { (success, error) in
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
}
