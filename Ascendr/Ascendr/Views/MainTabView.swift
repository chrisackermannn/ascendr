//
//  MainTabView.swift
//  Ascendr
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .environmentObject(feedViewModel)
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .environmentObject(workoutViewModel)
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(profileViewModel)
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
        }
        .tint(appSettings.accentColor)
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                Task {
                    await feedViewModel.fetchPosts()
                    await profileViewModel.fetchUserData(userId: userId)
                }
            }
        }
    }
}

