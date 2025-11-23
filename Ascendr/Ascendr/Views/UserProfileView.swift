//
//  UserProfileView.swift
//  Ascendr
//
//  Viewable user profile page (for other users)
//

import SwiftUI

struct UserProfileView: View {
    let userId: String
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var user: User?
    @State private var publicWorkouts: [Workout] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedWorkout: Workout?
    @State private var userStatus: UserStatus?
    
    private let databaseService = RealtimeDatabaseService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let user = user {
                    // Profile Header - Enhanced
                    VStack(spacing: 20) {
                        // Profile Image with online indicator
                        ZStack(alignment: .bottomTrailing) {
                            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 120, height: 120)
                            )
                            
                            // Online/Offline indicator - always show
                            if let status = userStatus {
                                Circle()
                                    .fill(status.isOnline ? Color.green : Color.red)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 3)
                                    )
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(user.username)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                    
                    // Stats - Enhanced
                    HStack(spacing: 20) {
                        StatCardView(
                            value: "\(publicWorkouts.count)",
                            label: "Public Workouts",
                            icon: "figure.strengthtraining.traditional",
                            color: .blue
                        )
                        
                        StatCardView(
                            value: "\(user.workoutCount)",
                            label: "Total Workouts",
                            icon: "chart.bar.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Public Workouts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Public Workouts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if publicWorkouts.isEmpty {
                            Text("No public workouts yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(publicWorkouts) { workout in
                                Button(action: {
                                    selectedWorkout = workout
                                }) {
                                    WorkoutHistoryCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ascendr")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
    
    private func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch user data
            let fetchedUser = try await databaseService.fetchUser(userId: userId)
            
            // Fetch public workouts
            let workouts = try await databaseService.fetchPublicWorkouts(userId: userId)
            
            // Fetch user status
            let status = try? await databaseService.getUserStatus(userId: userId)
            
            await MainActor.run {
                self.user = fetchedUser
                self.publicWorkouts = workouts
                self.userStatus = status
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

