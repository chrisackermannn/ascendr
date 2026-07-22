//
//  AscendrApp.swift
//  Ascendr
//
//  Created by Chris Ackermann on 11/15/25.
//

import SwiftUI
import FirebaseCore
import HealthKit

@main
struct AscendrApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
                .environmentObject(healthKitManager)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
                .onOpenURL { url in
                    // Handle Spotify authorization callback
                    if url.scheme == "ascendr" {
                        SpotifyManager.shared.handleAuthorizationCallback(url: url)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    Task { @MainActor in
                        SpotifyManager.shared.disconnect()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task { @MainActor in
                        if !SpotifyManager.shared.isConnected && SpotifyManager.shared.isAuthorized {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                SpotifyManager.shared.connect()
                            }
                        }
                    }
                }
        }
    }
}
