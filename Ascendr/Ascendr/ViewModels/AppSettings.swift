//
//  AppSettings.swift
//  Ascendr
//
//  App-wide settings including color scheme
//

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    private init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        // Default to dark mode if not set
        if !UserDefaults.standard.bool(forKey: "isDarkModeSet") {
            self.isDarkMode = true
            UserDefaults.standard.set(true, forKey: "isDarkModeSet")
        }
    }
    
    // Adaptive colors based on mode
    // Dark mode: Black and Light Blue
    // Light mode: White and Purple
    
    var cardBackground: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.white
    }
    
    var primaryBackground: Color {
        isDarkMode ? Color.black : Color.white
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color(red: 0.98, green: 0.97, blue: 1.0)
    }
    
    var tertiaryBackground: Color {
        isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color(red: 0.95, green: 0.94, blue: 0.98)
    }
    
    var primaryText: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    // Accent colors
    var accentColor: Color {
        isDarkMode ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color(red: 0.6, green: 0.3, blue: 0.9)
    }
    
    var accentColorSecondary: Color {
        isDarkMode ? Color(red: 0.3, green: 0.7, blue: 0.95) : Color(red: 0.7, green: 0.4, blue: 0.95)
    }
    
    var accentColorLight: Color {
        isDarkMode ? Color(red: 0.5, green: 0.85, blue: 1.0) : Color(red: 0.8, green: 0.5, blue: 1.0)
    }
    
    var borderColor: Color {
        isDarkMode ? Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.2) : Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.2)
    }
    
    // Gradient for buttons and highlights
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode ? 
                [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 0.95)] :
                [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.7, green: 0.4, blue: 0.95)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Subtle gradient for cards
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode ?
                [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.15, green: 0.15, blue: 0.18)] :
                [Color.white, Color(red: 0.98, green: 0.97, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var shadowColor: Color {
        isDarkMode ? accentColor.opacity(0.15) : accentColor.opacity(0.1)
    }
}
