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
                    print("HealthKit authorization error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    // Success can be true even if user hasn't granted permission yet
                    // The actual permission status is checked when querying
                    print("HealthKit authorization request completed, success: \(success)")
                    continuation.resume()
                }
            }
        }
    }
    
    // Get step count for today
    func getTodayStepCount() async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return 0
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Check authorization status
        let status = healthStore.authorizationStatus(for: stepCountType)
        print("HealthKit step count authorization status: \(status.rawValue) (0=notDetermined, 1=sharingDenied, 2=sharingAuthorized)")
        
        // If explicitly denied, return 0
        if status == .sharingDenied {
            print("HealthKit step count access denied by user")
            return 0
        }
        
        // For .notDetermined or .sharingAuthorized, try to query
        // HealthKit will handle authorization if needed
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Don't use .strictStartDate - use .none to get all samples that overlap with the time range
        // This ensures we get steps from all sources (iPhone, Apple Watch, etc.)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    let nsError = error as NSError
                    // Don't fail on authorization errors - just return 0
                    if nsError.domain == "com.apple.healthkit" && nsError.code == 4 {
                        print("HealthKit authorization required - user needs to grant permission")
                        continuation.resume(returning: 0)
                    } else {
                        print("HealthKit query error: \(error.localizedDescription), code: \(nsError.code)")
                        continuation.resume(throwing: error)
                    }
                } else if let result = result {
                    if let sum = result.sumQuantity() {
                        let steps = Int(sum.doubleValue(for: HKUnit.count()))
                        print("HealthKit steps retrieved successfully: \(steps)")
                        continuation.resume(returning: steps)
                    } else {
                        print("HealthKit query completed but no step data available (may be 0 steps today)")
                        continuation.resume(returning: 0)
                    }
                } else {
                    print("HealthKit query returned nil result")
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

