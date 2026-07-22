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
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    var body: some View {
        TabView {
            HomeSummaryView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
            
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "square.grid.2x2")
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
                .environmentObject(healthKitManager)
        }
        .tint(appSettings.accentColor) // Orange color (#FF9E5A) for tab bar icons
        .onAppear {
            // Set tab bar appearance to match home screen theme
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.09, alpha: 1.0) // #0F1318
            appearance.shadowColor = .clear
            
            // Selected tab icon color (orange)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 1.0, green: 0.62, blue: 0.35, alpha: 1.0) // #FF9E5A
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 1.0, green: 0.62, blue: 0.35, alpha: 1.0)]
            
            // Unselected tab icon color (muted grey)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.6, green: 0.63, blue: 0.66, alpha: 1.0) // #98A0A9
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.6, green: 0.63, blue: 0.66, alpha: 1.0)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Load data
            if let userId = authViewModel.currentUser?.id {
                Task {
                    await feedViewModel.fetchPosts()
                    await profileViewModel.fetchUserData(userId: userId)
                }
            }
        }
    }
}

