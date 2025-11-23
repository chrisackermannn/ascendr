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
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}
