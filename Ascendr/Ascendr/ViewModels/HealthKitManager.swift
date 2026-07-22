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
    @Published var heartRate: Int = 0
    @Published var isAuthorized: Bool = false
    
    private let healthStore = HKHealthStore()
    nonisolated(unsafe) private var refreshTimer: Timer?
    nonisolated(unsafe) private var heartRateQuery: HKQuery?
    nonisolated(unsafe) private var heartRateAnchoredQuery: HKAnchoredObjectQuery?
    nonisolated(unsafe) private var heartRateQueryAnchor: HKQueryAnchor?
    
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
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // If already authorized, just refresh the heart rate immediately without re-requesting
        let stepStatus = healthStore.authorizationStatus(for: stepType)
        if stepStatus == .sharingAuthorized && isAuthorized {
            // Already authorized - just refresh heart rate data immediately
            fetchMostRecentHeartRate()
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: [stepType, energyType, heartRateType]) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization granted.")
                    self?.isAuthorized = true
                    self?.fetchStepsToday()
                    self?.fetchCaloriesToday()
                    self?.startRefreshTimer()
                    self?.startHeartRateObserver()
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
        
        // Check if authorized (either sharingAuthorized or sharingDenied means we can read)
        isAuthorized = (stepStatus == .sharingAuthorized)
        
        if isAuthorized {
            fetchStepsToday()
            fetchCaloriesToday()
            startRefreshTimer()
            // Start heart rate observer immediately if authorized
            startHeartRateObserver()
            print("HealthKit authorized - starting live heart rate monitoring")
        } else {
            print("HealthKit not authorized yet - will start when user grants permission")
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
    
    // MARK: - Start Heart Rate Observer (Live Updates from Apple Watch)
    private func startHeartRateObserver() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Stop any existing queries
        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
        }
        if let existingAnchoredQuery = heartRateAnchoredQuery {
            healthStore.stop(existingAnchoredQuery)
        }
        
        // 🔥 HKObserverQuery - watches HealthKit and triggers when new data is added
        let observerQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("ObserverQuery error: \(error.localizedDescription)")
                    return
                }
                
                // When observer detects new data, run the anchored query
                print("🔄 ObserverQuery: New heart rate data detected")
                self.runHeartRateAnchoredQuery()
            }
        }
        
        heartRateQuery = observerQuery
        healthStore.execute(observerQuery)
        
        // 🔥 Run initial anchored query immediately
        runHeartRateAnchoredQuery()
        
        // Enable background delivery for heart rate
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for heart rate: \(error.localizedDescription)")
            } else if success {
                print("✅ Background delivery enabled for heart rate")
            }
        }
        
        print("✅ Heart rate live observer started - HKObserverQuery + HKAnchoredObjectQuery")
    }
    
    // MARK: - Run Heart Rate Anchored Query (Live Updates)
    private func runHeartRateAnchoredQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let anchoredQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: heartRateQueryAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samplesOrNil, deletedObjects, newAnchor, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("AnchoredQuery error: \(error.localizedDescription)")
                    return
                }
                
                self.heartRateQueryAnchor = newAnchor
                
                if let samples = samplesOrNil as? [HKQuantitySample] {
                    self.processHeartRate(samples)
                }
            }
        }
        
        // 🔥 LIVE UPDATE handler - fires whenever new samples are added
        anchoredQuery.updateHandler = { [weak self] _, samplesOrNil, deletedObjects, newAnchor, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("AnchoredQuery updateHandler error: \(error.localizedDescription)")
                    return
                }
                
                self.heartRateQueryAnchor = newAnchor
                
                if let samples = samplesOrNil as? [HKQuantitySample] {
                    self.processHeartRate(samples)
                }
            }
        }
        
        heartRateAnchoredQuery = anchoredQuery
        healthStore.execute(anchoredQuery)
    }
    
    // MARK: - Process Heart Rate Samples
    private func processHeartRate(_ samples: [HKQuantitySample]) {
        guard let sample = samples.last else { return }
        
        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        let newHeartRate = Int(bpm)
        
        // Always update to show latest reading
        if self.heartRate != newHeartRate {
            self.heartRate = newHeartRate
            let sampleAge = Date().timeIntervalSince(sample.endDate)
            print("✅ Heart rate updated (LIVE): \(self.heartRate) bpm (sample from \(String(format: "%.1f", sampleAge))s ago)")
        }
    }
    
    
    // MARK: - Fetch Most Recent Heart Rate (called by observer and timer)
    func fetchMostRecentHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Get the absolute most recent sample - no time restriction to ensure we get latest
        // Apple Watch syncs to HealthKit, so we want the most recent regardless of when it was recorded
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil, // No predicate - get most recent from all time
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching most recent heart rate: \(error.localizedDescription)")
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    // No sample found
                    print("No heart rate sample found")
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let rate = sample.quantity.doubleValue(for: heartRateUnit)
                let newHeartRate = Int(rate)
                
                // Calculate how recent this sample is
                let sampleAge = Date().timeIntervalSince(sample.endDate)
                
                // Always update to show the latest reading
                // This ensures the UI reflects the most recent measurement in real-time
                if self.heartRate != newHeartRate {
                    self.heartRate = newHeartRate
                    print("✅ Heart rate updated (live): \(self.heartRate) bpm (sample from \(String(format: "%.1f", sampleAge))s ago)")
                } else {
                    // Still log to confirm we're checking
                    print("Heart rate check: \(self.heartRate) bpm (sample from \(String(format: "%.1f", sampleAge))s ago)")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Stop Heart Rate Observer
    private func stopHeartRateObserver() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        if let anchoredQuery = heartRateAnchoredQuery {
            healthStore.stop(anchoredQuery)
            heartRateAnchoredQuery = nil
        }
    }
    
    nonisolated private func stopHeartRateObserverSync() {
        // This is called from deinit which is nonisolated
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        if let anchoredQuery = heartRateAnchoredQuery {
            healthStore.stop(anchoredQuery)
        }
    }
    
    // MARK: - Fetch Current Heart Rate (fallback method)
    func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Get the most recent heart rate sample
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType,
                                 predicate: nil,
                                 limit: 1,
                                 sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    self.heartRate = 0
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let rate = sample.quantity.doubleValue(for: heartRateUnit)
                self.heartRate = Int(rate)
                print("Heart rate: \(self.heartRate) bpm")
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
        stopHeartRateObserverSync()
    }
}
