//
//  ContentView.swift
//  Ascendr
//
//  Created by Chris Ackermann on 11/15/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        Group {
            if authViewModel.isInitializing {
                // Show launch screen while checking auth state
                ZStack {
                    // Home screen gradient background
                    appSettings.homeGradient
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Ascendr")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                appSettings.buttonGradient
                            )
                    }
                }
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(healthKitManager)
                    .onAppear {
                        // Request HealthKit authorization when user is authenticated
                        healthKitManager.requestAuthorization()
                    }
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
