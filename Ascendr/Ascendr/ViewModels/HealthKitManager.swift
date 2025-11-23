//
//  HealthKitManager.swift
//  Ascendr
//
//  HealthKit manager for step and calorie tracking
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var stepCount: Int = 0
    @Published var activeEnergy: Double = 0
    @Published var isAuthorized: Bool = false
    
    private let healthStore = HKHealthStore()
    nonisolated(unsafe) private var refreshTimer: Timer?
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Request Permission
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available.")
            isAuthorized = false
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepType, energyType]) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization granted.")
                    self?.isAuthorized = true
                    self?.fetchStepsToday()
                    self?.fetchCaloriesToday()
                    self?.startRefreshTimer()
                } else {
                    print("Authorization failed: \(String(describing: error))")
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Check Authorization Status
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepStatus = healthStore.authorizationStatus(for: stepType)
        
        isAuthorized = (stepStatus == .sharingAuthorized)
        
        if isAuthorized {
            fetchStepsToday()
            fetchCaloriesToday()
            startRefreshTimer()
        }
    }
    
    // MARK: - Fetch Today's Step Count
    
    func fetchStepsToday() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let now = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                    return
                }
                
                guard let sum = result?.sumQuantity() else {
                    self.stepCount = 0
                    return
                }
                
                self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                print("Steps today: \(self.stepCount)")
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Today's Calories
    
    func fetchCaloriesToday() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let now = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: energyType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching calories: \(error.localizedDescription)")
                    return
                }
                
                guard let sum = result?.sumQuantity() else {
                    self.activeEnergy = 0
                    return
                }
                
                self.activeEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
                print("Calories today: \(Int(self.activeEnergy))")
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Refresh Timer
    
    private func startRefreshTimer() {
        stopRefreshTimer()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.fetchStepsToday()
            self?.fetchCaloriesToday()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    nonisolated private func stopRefreshTimerSync() {
        // This is called from deinit which is nonisolated
        if let timer = refreshTimer {
            timer.invalidate()
        }
    }
    
    deinit {
        stopRefreshTimerSync()
    }
}
