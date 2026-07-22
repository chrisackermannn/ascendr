//
//  HomeSummaryView.swift
//  Ascendr
//
//  Modern dark-themed fitness/health summary screen matching design spec
//

import SwiftUI
import HealthKit
import Combine

struct HomeSummaryView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var rewardViewModel = RewardViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    
    @State private var selectedMood: String = "Tired 😪"
    @State private var showingWorkout = false
    @State private var showingWeatherModal = false
    @State private var showingAIModal = false
    @State private var showingMessages = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Top bar
                        topBar
                            .padding(.top, 18)
                            .padding(.horizontal, 20)
                        
                        // Summary title
                        titleHeader
                        .padding(.horizontal, 20)
                        
                        // Metrics grid (2x2)
                        metricsGrid
                            .padding(.horizontal, 20)
                        
                        // Start Workout hero card
                        startWorkoutCard
                            .padding(.horizontal, 18)
                        
                        // XP Progress card
                        xpProgressCard
                            .padding(.horizontal, 20)
                        
                        // Mood pill
                        moodPill
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadData()
            weatherService.requestLocationAndWeather()
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutView()
                    .environmentObject(workoutViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(appSettings)
            }
        }
        .sheet(isPresented: $showingWeatherModal) {
            WeatherModalView()
                .environmentObject(weatherService)
        }
        .sheet(isPresented: $showingAIModal) {
            AIComingSoonModal()
        }
        .sheet(isPresented: $showingMessages) {
            MessagesView()
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
                .environmentObject(messagingViewModel)
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "0F1318"), location: 0.0),
                .init(color: Color(hex: "2B2E34"), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Messages icon with notification badge
                    Button(action: {
                        showingMessages = true
                    }) {
                        ZStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "F8F8FA"))
                        .frame(width: 26, height: 26)
                            
                            if messagingViewModel.totalUnreadCount > 0 {
                                Text("\(messagingViewModel.totalUnreadCount > 99 ? "99+" : "\(messagingViewModel.totalUnreadCount)")")
                            .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(.horizontal, messagingViewModel.totalUnreadCount > 9 ? 4 : 3)
                                    .padding(.vertical, 2)
                                    .background(
                                        ZStack {
                                            Color.red
                                            LinearGradient(
                                                colors: [Color.red, Color(red: 0.9, green: 0, blue: 0)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        }
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .shadow(color: Color.red.opacity(0.5), radius: 3, x: 0, y: 2)
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Avatar + welcome
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Welcome back")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(Color(hex: "98A0A9"))
                    if let userName = authViewModel.currentUser?.username {
                        Text(userName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(hex: "F8F8FA"))
                    }
                }
                
                AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "0B0C10"))
                        .overlay(
                            Text(authViewModel.currentUser?.username.prefix(1).uppercased() ?? "A")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "F8F8FA"))
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Title Header
    private var titleHeader: some View {
        HStack {
            Text("Summary")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "F7F7FB"))
            
            Spacer()
        }
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Steps card
                metricCard(
                    icon: "figure.walk",
                    label: "T Steps",
                    value: "\(healthKitManager.stepCount)",
                    isAccent: false
                )
                
                // Heartbeat card
                Button(action: {}) {
                    metricCard(
                        icon: "heart.fill",
                        label: "Heartbeat",
                        value: healthKitManager.heartRate > 0 ? "\(healthKitManager.heartRate) bpm" : "-- bpm",
                        isAccent: false
                    )
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                // AI Coming Soon card (accent)
                Button(action: {
                    showingAIModal = true
                }) {
                    metricCard(
                        icon: "sparkles",
                        label: "AI Coach",
                        value: "Coming Soon",
                        isAccent: true
                    )
                }
                .buttonStyle(.plain)
                
                // Weather card
                Button(action: {
                    showingWeatherModal = true
                }) {
                    weatherCard
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func metricCard(icon: String, label: String, value: String, isAccent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isAccent ? .white : Color(hex: "98A0A9"))
                Spacer()
                if !isAccent {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "98A0A9"))
                }
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isAccent ? .white : Color(hex: "F8F8FA"))
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isAccent ? .white.opacity(0.8) : Color(hex: "98A0A9"))
                .textCase(.uppercase)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isAccent ? Color(hex: "F39F66") : Color(hex: "0E0F12"))
        )
    }
    
    private var weatherCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "98A0A9"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(weatherService.condition)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "98A0A9"))
                Text(weatherService.temperatureRange)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "F8F8FA"))
            }
            
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "0E0F12"))
        )
    }
    
    // MARK: - Start Workout Card
    private var startWorkoutCard: some View {
        Button(action: {
            if let userId = authViewModel.currentUser?.id,
               let userName = authViewModel.currentUser?.username {
                workoutViewModel.startWorkout(userId: userId, userName: userName)
            }
            showingWorkout = true
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                            Text("Start Workout")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                    Text("Begin your fitness journey")
                        .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                    // Play button
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "2F3040"),
                                Color(hex: "E6C9AF")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - XP Progress Card
    private var xpProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LEVEL PROGRESS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "98A0A9"))
                        .textCase(.uppercase)
                    Text(getLevelName())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "F8F8FA"))
                }
                
                Spacer()
                
                Text("\(rewardViewModel.currentXP) XP")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "F8F8FA"))
            }
            
            // XP Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "1A1B1D"))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF9E5A"), Color(hex: "F6A267")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * xpProgress,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(getCurrentLevelXP()) / \(getNextLevelXP()) XP")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(hex: "98A0A9"))
                    Spacer()
                    Text("\(Int(xpProgress * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "FF9E5A"))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "0A0B0D"))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private func getLevelName() -> String {
        let xp = rewardViewModel.currentXP
        if xp < 500 { return "Beginner" }
        if xp < 2000 { return "Intermediate" }
        if xp < 5000 { return "Advanced" }
        return "Expert"
    }
    
    private func getCurrentLevelXP() -> Int {
        let xp = rewardViewModel.currentXP
        if xp < 500 { return xp }
        if xp < 2000 { return xp - 500 }
        if xp < 5000 { return xp - 2000 }
        return xp - 5000
    }
    
    private func getNextLevelXP() -> Int {
        let xp = rewardViewModel.currentXP
        if xp < 500 { return 500 }
        if xp < 2000 { return 1500 }
        if xp < 5000 { return 3000 }
        return 5000
    }
    
    private var xpProgress: CGFloat {
        let current = getCurrentLevelXP()
        let next = getNextLevelXP()
        return next > 0 ? min(CGFloat(current) / CGFloat(next), 1.0) : 0
    }
    
    // MARK: - Mood Pill
    private var moodPill: some View {
        Button(action: {
            // Cycle through moods
            let moods = ["Tired 😪", "Energized ⚡", "Focused 🎯", "Relaxed 😌", "Motivated 💪"]
            if let currentIndex = moods.firstIndex(of: selectedMood) {
                let nextIndex = (currentIndex + 1) % moods.count
                selectedMood = moods[nextIndex]
            } else {
                selectedMood = moods[0]
            }
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Text("Mood")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "98A0A9"))
                Text(selectedMood)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "F8F8FA"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(hex: "1A1B1D"))
            )
        }
    }
    
    // MARK: - Helper Functions
    private func loadData() {
        if let userId = authViewModel.currentUser?.id {
            Task {
                await rewardViewModel.loadUserRewards(userId: userId)
                await messagingViewModel.loadConversations(userId: userId)
                messagingViewModel.startListeningForConversations(userId: userId)
                healthKitManager.requestAuthorization()
            }
        }
    }
    
}

// MARK: - Weather Modal View
struct WeatherModalView: View {
    @EnvironmentObject var weatherService: WeatherService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                    LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "0F1318"), location: 0.0),
                        .init(color: Color(hex: "2B2E34"), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Weather icon
                    Image(systemName: weatherIcon)
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "FF9E5A"))
                        .padding(.top, 40)
                    
                    // Temperature
                    Text(weatherService.temperature)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(Color(hex: "F8F8FA"))
                    
                    // Condition
                    Text(weatherService.condition)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "98A0A9"))
                    
                    // Temperature range
                    Text(weatherService.temperatureRange)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(hex: "98A0A9"))
            
            Spacer()
        }
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "FF9E5A"))
                }
            }
        }
    }
    
    private var weatherIcon: String {
        let condition = weatherService.condition.lowercased()
        if condition.contains("cloud") {
            return "cloud.fill"
        } else if condition.contains("rain") {
            return "cloud.rain.fill"
        } else if condition.contains("sun") || condition.contains("clear") {
            return "sun.max.fill"
        } else if condition.contains("snow") {
            return "snow"
        } else {
            return "cloud.fill"
        }
    }
}

// MARK: - AI Coming Soon Modal
struct AIComingSoonModal: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "0F1318"), location: 0.0),
                        .init(color: Color(hex: "2B2E34"), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // AI Icon
                    ZStack {
                        Circle()
                            .fill(
                    LinearGradient(
                                    colors: [Color(hex: "FF9E5A"), Color(hex: "F6A267")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    Text("AI Coach")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "F8F8FA"))
                    
                    Text("Coming Soon")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "FF9E5A"))
                    
                    Text("Our AI-powered fitness coach is being developed to provide personalized workout recommendations, form analysis, and real-time guidance.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "98A0A9"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
            
            Spacer()
        }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "FF9E5A"))
                }
            }
        }
    }
}
