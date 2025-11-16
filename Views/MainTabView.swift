//
//  MainTabView.swift
//  Ascendr
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .environmentObject(feedViewModel)
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .environmentObject(workoutViewModel)
                .environmentObject(authViewModel)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(profileViewModel)
                .environmentObject(authViewModel)
        }
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

