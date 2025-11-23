//
//  StepCounterView.swift
//  Ascendr
//
//  Step counter using HKStatisticsCollectionQuery for live updates
//

import SwiftUI
import HealthKit
import Combine

class StepCounterManager: ObservableObject {
    static let shared = StepCounterManager()
    
    @Published var stepCount: Int = 0
    
    private let healthStore = HKHealthStore()
    private var statisticsCollectionQuery: HKStatisticsCollectionQuery?
    
    private init() {
        requestAuthorization()
    }
    
    // MARK: - HealthKit Authorization
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.startLiveStepQuery()
                }
            } else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Live Step Query
    private func startLiveStepQuery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        // Use daily interval to get today's total
        let interval = DateComponents(day: 1)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfDay,
            intervalComponents: interval
        )
        
        // Initial value
        query.initialResultsHandler = { [weak self] _, results, _ in
            self?.updateSteps(from: results)
        }
        
        // Live updates
        query.statisticsUpdateHandler = { [weak self] _, _, results, _ in
            self?.updateSteps(from: results)
        }
        
        statisticsCollectionQuery = query
        healthStore.execute(query)
    }
    
    private func updateSteps(from results: HKStatisticsCollection?) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        var totalSteps = 0
        
        results?.enumerateStatistics(from: startOfDay, to: now) { stats, _ in
            if let quantity = stats.sumQuantity() {
                let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                totalSteps += steps
            }
        }
        
        DispatchQueue.main.async {
            self.stepCount = totalSteps
            print("✅ Steps updated: \(totalSteps)")
        }
    }
    
    func stopQuery() {
        if let query = statisticsCollectionQuery {
            healthStore.stop(query)
            statisticsCollectionQuery = nil
        }
    }
    
    deinit {
        stopQuery()
    }
}

struct StepCounterView: View {
    @StateObject private var manager = StepCounterManager.shared
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    appSettings.buttonGradient
                )
            
            Text("\(manager.stepCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            appSettings.buttonGradient.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
        )
        .allowsHitTesting(false)
    }
}
