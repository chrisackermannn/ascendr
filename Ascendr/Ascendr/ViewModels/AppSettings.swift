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
    
    // Home screen theme: Dark grey gradient + Orange accents
    // Dark mode: Dark grey gradient (#0F1318 to #2B2E34) with Orange (#FF9E5A)
    // Light mode: Light version with orange accents
    
    var cardBackground: Color {
        isDarkMode ? Color(hex: "0E0F12") : Color.white
    }
    
    var primaryBackground: Color {
        isDarkMode ? Color(hex: "0F1318") : Color.white
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color(hex: "1A1B1D") : Color(hex: "F5F5F7")
    }
    
    var tertiaryBackground: Color {
        isDarkMode ? Color(hex: "2B2E34") : Color(hex: "E8E8EA")
    }
    
    var primaryText: Color {
        isDarkMode ? Color(hex: "F8F8FA") : Color.black
    }
    
    var secondaryText: Color {
        isDarkMode ? Color(hex: "98A0A9") : Color.black.opacity(0.6)
    }
    
    // Orange accent colors (matching home screen)
    var accentColor: Color {
        Color(hex: "FF9E5A") // Primary orange
    }
    
    var accentColorSecondary: Color {
        Color(hex: "F6A267") // Secondary orange
    }
    
    var accentColorLight: Color {
        Color(hex: "FFB07A") // Light orange
    }
    
    var borderColor: Color {
        isDarkMode ? Color(hex: "FF9E5A").opacity(0.2) : Color(hex: "FF9E5A").opacity(0.3)
    }
    
    // Home screen gradient background
    var homeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "0F1318"), location: 0.0),
                .init(color: Color(hex: "2B2E34"), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Gradient for buttons and highlights (orange)
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF9E5A"), Color(hex: "F6A267")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Subtle gradient for cards (dark grey)
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode ?
                [Color(hex: "0E0F12"), Color(hex: "1A1B1D")] :
                [Color.white, Color(hex: "F5F5F7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var shadowColor: Color {
        accentColor.opacity(0.15)
    }
    
    // Liquid glass effect modifier
    func liquidGlassEffect() -> some View {
        EmptyView()
    }
}
