//
//  WorkoutStatsView.swift
//  Ascendr
//
//  Workout stats component with timer and HealthKit data
//

import SwiftUI

struct WorkoutStatsView: View {
    let startTime: Date?
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var timerStartTime: Date?
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact horizontal layout
            HStack(spacing: 10) {
                // Timer - Compact
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(appSettings.buttonGradient)
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(appSettings.primaryText)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appSettings.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(appSettings.buttonGradient, lineWidth: 1.5)
                        )
                )
                
                // Steps - Compact
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(healthKitManager.stepCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(appSettings.primaryText)
                        Text("Steps")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appSettings.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Calories - Compact
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(healthKitManager.activeEnergy))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(appSettings.primaryText)
                        Text("Cal")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appSettings.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            if startTime != nil {
                startTimer()
            }
            // Request HealthKit access if needed
            if !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: startTime) { oldValue, newValue in
            stopTimer()
            if newValue != nil {
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        guard let startTime = startTime else { return }
        
        timerStartTime = startTime
        elapsedTime = Date().timeIntervalSince(startTime)
        stopTimer()
        
        let capturedStartTime = startTime
        
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


// Compact version for live workouts
struct CompactWorkoutStatsView: View {
    let startTime: Date?
    @EnvironmentObject var appSettings: AppSettings
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var timerStartTime: Date?
    
    var body: some View {
        HStack(spacing: 12) {
            // Timer - Compact
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTime(elapsedTime))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(appSettings.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [appSettings.accentColor.opacity(0.2), appSettings.accentColorSecondary.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .onAppear {
            if startTime != nil {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: startTime) { oldValue, newValue in
            stopTimer()
            if newValue != nil {
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        guard let startTime = startTime else { return }
        
        timerStartTime = startTime
        elapsedTime = Date().timeIntervalSince(startTime)
        stopTimer()
        
        let capturedStartTime = startTime
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

#Preview {
    WorkoutStatsView(startTime: Date().addingTimeInterval(-3600))
        .padding()
}

