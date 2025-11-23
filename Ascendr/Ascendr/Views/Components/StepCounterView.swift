//
//  StepCounterView.swift
//  Ascendr
//
//  Live step counter component from Apple Health
//

import SwiftUI
import Combine

@MainActor
class StepCounterViewModel: ObservableObject {
    static let shared = StepCounterViewModel()
    
    @Published var stepCount: Int = 0
    private var updateTimer: Timer?
    private var hasRequestedAuth = false
    private var isInitialized = false
    private let healthKitService = HealthKitService()
    
    private init() {
        // Private initializer for singleton
    }
    
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        Task {
            await requestHealthKitAccessIfNeeded()
            await loadSteps()
            startUpdating()
        }
    }
    
    func refresh() {
        // Always refresh when called
        Task {
            await loadSteps()
        }
    }
    
    private func requestHealthKitAccessIfNeeded() async {
        guard !hasRequestedAuth else { return }
        hasRequestedAuth = true
        
        do {
            try await healthKitService.requestAuthorization()
            print("✅ HealthKit authorization requested successfully")
        } catch {
            print("❌ HealthKit authorization error: \(error.localizedDescription)")
        }
        
        // Try loading steps immediately after authorization
        await loadSteps()
        
        // Retry after a short delay to ensure data is available
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await loadSteps()
    }
    
    private func loadSteps() async {
        do {
            let steps = try await healthKitService.getTodayStepCount()
            await MainActor.run {
                let oldCount = self.stepCount
                self.stepCount = steps
                if oldCount != steps {
                    print("📊 Step count updated: \(oldCount) → \(steps)")
                }
            }
        } catch {
            print("❌ Error loading steps: \(error.localizedDescription)")
        }
    }
    
    private func startUpdating() {
        // Stop any existing timer first
        stopUpdating()
        
        // Load immediately
        Task {
            await loadSteps()
        }
        
        // Update every 2 seconds for live updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadSteps()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
        print("🔄 Step counter timer started (updates every 2 seconds)")
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // Note: deinit is not needed since this is a singleton that lives for the app's lifetime
}

struct StepCounterView: View {
    @StateObject private var viewModel = StepCounterViewModel.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.caption)
                .foregroundColor(.primary)
            Text("\(viewModel.stepCount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .monospacedDigit() // Prevents number jumping when digits change
        }
        .task {
            // Initialize on first appearance
            viewModel.initialize()
        }
        .onAppear {
            // Always refresh when view appears (every page navigation)
            viewModel.refresh()
        }
    }
}

