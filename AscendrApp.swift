//
//  AscendrApp.swift
//  Ascendr
//
//  Created on iOS
//

import SwiftUI
import FirebaseCore

@main
struct AscendrApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

