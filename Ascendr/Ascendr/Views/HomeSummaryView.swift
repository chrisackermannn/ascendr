//
//  HomeSummaryView.swift
//  Ascendr
//
//  Fitness-themed home summary page
//

import SwiftUI
import UIKit
import HealthKit

struct HomeSummaryView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    @State private var distance: String = "0.0 km"
    @State private var workoutsToday: Int = 0
    @State private var lastWorkoutDuration: String = "0 min"
    @State private var weeklyStreak: Int = 0
    @State private var showingMessages = false
    @State private var showingProfile = false
    @State private var showingHealthPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced gradient background with multiple stops
                backgroundGradient
                    .ignoresSafeArea()
                
                // Mountain silhouette background
                MountainBackground()
                    .ignoresSafeArea()
                    .opacity(colorScheme == .dark ? 0.15 : 0.08)
                
                VStack(spacing: 0) {
                    // Compact Header
                    CompactHeaderView(showingProfile: $showingProfile)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    // Main Scroll Area
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Compact Stats Grid
                            CompactStatsGrid(
                                steps: $healthKitManager.stepCount,
                                distance: $distance,
                                calories: Binding(
                                    get: { "\(Int(healthKitManager.activeEnergy))" },
                                    set: { _ in }
                                ),
                                workoutsToday: $workoutsToday
                            )
                            .environmentObject(appSettings)
                            
                            // Quick Start Button
                            ModernQuickStartButton()
                                .environmentObject(appSettings)
                                .environmentObject(authViewModel)
                            
                            // Last Workout & Streak Row
                            HStack(spacing: 12) {
                                CompactLastWorkoutCard(duration: lastWorkoutDuration)
                                    .environmentObject(appSettings)
                                
                                CompactStreakCard(streak: weeklyStreak)
                                    .environmentObject(appSettings)
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMessages = true
                    }) {
                        ZStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(appSettings.primaryText)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            if messagingViewModel.totalUnreadCount > 0 {
                                Text("\(messagingViewModel.totalUnreadCount > 99 ? "99+" : "\(messagingViewModel.totalUnreadCount)")")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .padding(.horizontal, messagingViewModel.totalUnreadCount > 9 ? 5 : 4)
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
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 2)
                                    .position(x: 20, y: 4)
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                }
            }
            .sheet(isPresented: $showingMessages) {
                MessagesView()
                    .environmentObject(authViewModel)
                    .environmentObject(appSettings)
                    .environmentObject(messagingViewModel)
            }
            .sheet(isPresented: $showingProfile) {
                NavigationView {
                    ProfileView()
                        .environmentObject(profileViewModel)
                        .environmentObject(authViewModel)
                        .environmentObject(appSettings)
                }
            }
        }
        .onAppear {
            loadSummaryData()
        }
        .onDisappear {
            messagingViewModel.stopListeningForConversations()
        }
        .onChange(of: healthKitManager.stepCount) { newValue in
            let distanceKm = Double(newValue) * 0.0008
            distance = String(format: "%.1f km", distanceKm)
        }
        .alert("HealthKit Permission Required", isPresented: $showingHealthPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable HealthKit access in Settings to track your steps and calories.")
        }
    }
    
    // Enhanced gradient background
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: Deep blue to purple gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 12/255, green: 15/255, blue: 25/255), location: 0.0),
                        .init(color: Color(red: 20/255, green: 25/255, blue: 40/255), location: 0.3),
                        .init(color: Color(red: 30/255, green: 35/255, blue: 50/255), location: 0.6),
                        .init(color: Color(red: 25/255, green: 30/255, blue: 45/255), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Light mode: Soft blue to peach gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 240/255, green: 245/255, blue: 250/255), location: 0.0),
                        .init(color: Color(red: 230/255, green: 240/255, blue: 248/255), location: 0.3),
                        .init(color: Color(red: 250/255, green: 235/255, blue: 220/255), location: 0.6),
                        .init(color: Color(red: 255/255, green: 245/255, blue: 235/255), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private func loadSummaryData() {
        if let userId = authViewModel.currentUser?.id {
            Task {
                healthKitManager.requestAuthorization()
                
                let distanceKm = Double(healthKitManager.stepCount) * 0.0008
                distance = String(format: "%.1f km", distanceKm)
                
                await messagingViewModel.loadConversations(userId: userId)
                messagingViewModel.startListeningForConversations(userId: userId)
                
                await profileViewModel.fetchUserData(userId: userId)
                await loadWorkoutStats(userId: userId)
            }
        }
    }
    
    private func loadWorkoutStats(userId: String) async {
        let databaseService = RealtimeDatabaseService()
        do {
            let workouts = try await databaseService.fetchUserWorkoutHistory(userId: userId)
            let today = Calendar.current.startOfDay(for: Date())
            workoutsToday = workouts.filter { workout in
                Calendar.current.isDate(workout.date, inSameDayAs: today)
            }.count
            
            if let lastWorkout = workouts.first {
                let minutes = Int(lastWorkout.duration / 60)
                lastWorkoutDuration = "\(minutes) min"
            }
            
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            weeklyStreak = workouts.filter { $0.date >= weekAgo }.count
        } catch {
            print("Error loading workout stats: \(error)")
        }
    }
}

// MARK: - Mountain Background
fileprivate struct MountainBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multiple mountain layers for depth
                MountainLayer(offset: 0, height: 0.6, opacity: 0.4)
                MountainLayer(offset: 50, height: 0.5, opacity: 0.3)
                MountainLayer(offset: 100, height: 0.4, opacity: 0.2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

fileprivate struct MountainLayer: View {
    let offset: CGFloat
    let height: CGFloat
    let opacity: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Path { path in
            let width = UIScreen.main.bounds.width
            let mountainHeight = UIScreen.main.bounds.height * height
            
            path.move(to: CGPoint(x: -offset, y: UIScreen.main.bounds.height))
            path.addLine(to: CGPoint(x: width * 0.2 - offset, y: UIScreen.main.bounds.height - mountainHeight))
            path.addLine(to: CGPoint(x: width * 0.4 - offset, y: UIScreen.main.bounds.height - mountainHeight * 0.7))
            path.addLine(to: CGPoint(x: width * 0.6 - offset, y: UIScreen.main.bounds.height - mountainHeight * 0.9))
            path.addLine(to: CGPoint(x: width * 0.8 - offset, y: UIScreen.main.bounds.height - mountainHeight * 0.6))
            path.addLine(to: CGPoint(x: width + 100 - offset, y: UIScreen.main.bounds.height))
            path.closeSubpath()
        }
        .fill(colorScheme == .dark ? 
              LinearGradient(
                colors: [Color.white.opacity(opacity), Color.white.opacity(opacity * 0.5)],
                startPoint: .top,
                endPoint: .bottom
              ) :
              LinearGradient(
                colors: [Color.black.opacity(opacity), Color.black.opacity(opacity * 0.5)],
                startPoint: .top,
                endPoint: .bottom
              )
        )
    }
}

// MARK: - Compact Header
fileprivate struct CompactHeaderView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Binding var showingProfile: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ascendr")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(appSettings.primaryText)
                
                HStack(spacing: 4) {
                    Text("Welcome back,")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(appSettings.secondaryText)
                    if let userName = authViewModel.currentUser?.username {
                        Text(userName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(appSettings.accentColor)
                    }
                }
            }
            
            Spacer()
            
            // Compact profile button
            Button(action: {
                showingProfile = true
            }) {
                AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(appSettings.cardBackground)
                        .overlay(
                            Text(authViewModel.currentUser?.username.prefix(1).uppercased() ?? "A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(appSettings.primaryText)
                        )
                }
                .id(authViewModel.currentUser?.profileImageURL ?? UUID().uuidString) // Force refresh on URL change
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(appSettings.accentColor.opacity(0.3), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Compact Stats Grid
fileprivate struct CompactStatsGrid: View {
    @Binding var steps: Int
    @Binding var distance: String
    @Binding var calories: String
    @Binding var workoutsToday: Int
    
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                CompactStatCard(
                    title: "Steps",
                    value: formatNumber(steps),
                    icon: "figure.walk",
                    gradient: [Color.blue, Color.cyan]
                )
                CompactStatCard(
                    title: "Distance",
                    value: distance,
                    icon: "map",
                    gradient: [Color.purple, Color.pink]
                )
            }
            
            HStack(spacing: 10) {
                CompactStatCard(
                    title: "Calories",
                    value: calories,
                    icon: "flame.fill",
                    gradient: [Color.orange, Color.red]
                )
                CompactStatCard(
                    title: "Workouts",
                    value: "\(workoutsToday)",
                    icon: "figure.strengthtraining.traditional",
                    gradient: [Color.green, Color.mint]
                )
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

fileprivate struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(appSettings.primaryText)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(appSettings.secondaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: gradient.map { $0.opacity(0.15) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: gradient.map { $0.opacity(0.1) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: gradient.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: gradient.first?.opacity(0.2) ?? Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Modern Quick Start Button
fileprivate struct ModernQuickStartButton: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showingWorkout = false
    
    var body: some View {
        Button(action: {
            if let userId = authViewModel.currentUser?.id,
               let userName = authViewModel.currentUser?.username {
                workoutViewModel.startWorkout(userId: userId, userName: userName)
            }
            showingWorkout = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Workout")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text("Begin your fitness journey")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: appSettings.isDarkMode ? 
                                [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.2, blue: 0.8)] :
                                [Color(red: 0.3, green: 0.5, blue: 0.9), Color(red: 0.5, green: 0.3, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: appSettings.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutView()
                    .environmentObject(workoutViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(appSettings)
            }
        }
    }
}

// MARK: - Compact Last Workout Card
fileprivate struct CompactLastWorkoutCard: View {
    let duration: String
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Workout")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appSettings.secondaryText)
                Text(duration)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(appSettings.primaryText)
            }
            
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.7))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(appSettings.borderColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Compact Streak Card
fileprivate struct CompactStreakCard: View {
    let streak: Int
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Weekly Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appSettings.secondaryText)
                Text("\(streak) days")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(appSettings.primaryText)
            }
            
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.7))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(appSettings.borderColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}
