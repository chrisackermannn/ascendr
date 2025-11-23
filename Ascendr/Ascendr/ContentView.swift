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
    @State private var isLaunching = true
    
    var body: some View {
        Group {
            if isLaunching {
                // Launch screen
                ZStack {
                    appSettings.primaryBackground
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Ascendr")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(appSettings.primaryText)
                    }
                }
                .onAppear {
                    // Show launch screen briefly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLaunching = false
                    }
                }
            } else if authViewModel.isAuthenticated {
                MainTabView()
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
