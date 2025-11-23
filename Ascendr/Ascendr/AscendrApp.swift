//
//  AscendrApp.swift
//  Ascendr
//
//  Created by Chris Ackermann on 11/15/25.
//

import SwiftUI
import FirebaseCore

@main
struct AscendrApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    init() {
        FirebaseApp.configure()
        // Initialize step counter when app launches
        Task { @MainActor in
            StepCounterViewModel.shared.initialize()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
        }
    }
}
