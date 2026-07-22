//
//  View+Keyboard.swift
//  Ascendr
//
//  Extension to dismiss keyboard on tap
//

import SwiftUI
import UIKit

/// Helper function to hide keyboard with smooth animation
func hideKeyboard() {
    // Find the first responder and resign it with animation
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.endEditing(true)
    } else {
        // Fallback to the standard method
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    /// Dismisses the keyboard when tapping outside text fields
    /// Uses simultaneousGesture to avoid interfering with other interactions
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

