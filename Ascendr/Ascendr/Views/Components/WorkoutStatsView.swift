//
//  WorkoutStatsView.swift
//  Ascendr
//
//  Workout stats component with timer and HealthKit data
//

import SwiftUI

struct WorkoutStatsView: View {
    let startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var stepCount: Int = 0
    @State private var calories: Double = 0
    @State private var timer: Timer?
    @State private var timerStartTime: Date?
    
    private let healthKitService = HealthKitService()
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer - Large and prominent
            VStack(spacing: 8) {
                Text("Workout Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(formatTime(elapsedTime))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // HealthKit stats
            HStack(spacing: 16) {
                // Steps
                StatCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(stepCount)",
                    color: .primary
                )
                
                // Calories
                StatCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(Int(calories))",
                    color: .primary
                )
            }
        }
        .padding()
        .onAppear {
            if startTime != nil {
                startTimer()
            }
            requestHealthKitAccess()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: startTime) { oldValue, newValue in
            // Restart timer when startTime changes
            stopTimer()
            if newValue != nil {
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        guard let startTime = startTime else { return }
        
        // Store the start time in state so we can access it from the timer
        timerStartTime = startTime
        
        // Update immediately
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Stop any existing timer first
        stopTimer()
        
        // Capture the start time in the closure
        let capturedStartTime = startTime
        
        // Update every second - timer runs on main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await MainActor.run {
                    elapsedTime = Date().timeIntervalSince(capturedStartTime)
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func requestHealthKitAccess() {
        Task {
            do {
                try await healthKitService.requestAuthorization()
                await loadHealthData()
            } catch {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    private func loadHealthData() async {
        // Load steps
        if let steps = try? await healthKitService.getTodayStepCount() {
            await MainActor.run {
                stepCount = steps
            }
        }
        
        // Load calories
        if let cals = try? await healthKitService.getTodayActiveEnergy() {
            await MainActor.run {
                calories = cals
            }
        }
        
        // Update periodically
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                if let steps = try? await healthKitService.getTodayStepCount() {
                    await MainActor.run {
                        stepCount = steps
                    }
                }
                if let cals = try? await healthKitService.getTodayActiveEnergy() {
                    await MainActor.run {
                        calories = cals
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    WorkoutStatsView(startTime: Date().addingTimeInterval(-3600))
        .padding()
}

