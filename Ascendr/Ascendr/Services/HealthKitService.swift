//
//  HealthKitService.swift
//  Ascendr
//
//  HealthKit service for Apple Health integration
//

import Foundation
import HealthKit

class HealthKitService {
    private let healthStore = HKHealthStore()
    
    // Request authorization for step count
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"])
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let typesToRead: Swift.Set<HKObjectType> = [stepCountType, activeEnergyType]
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "HealthKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit authorization denied"]))
                }
            }
        }
    }
    
    // Get step count for today
    func getTodayStepCount() async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            return 0
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Check authorization
        let status = healthStore.authorizationStatus(for: stepCountType)
        guard status == .sharingAuthorized else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // Get active energy burned for today (calories)
    func getTodayActiveEnergy() async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            return 0
        }
        
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Check authorization
        let status = healthStore.authorizationStatus(for: energyType)
        guard status == .sharingAuthorized else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    continuation.resume(returning: calories)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            healthStore.execute(query)
        }
    }
}

