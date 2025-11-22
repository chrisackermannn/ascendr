//
//  AuthenticationViewModel.swift
//  Ascendr
//
//  Authentication view model
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authService = AuthenticationService()
    
    init() {
        // Observe authentication state
        authService.$isAuthenticated.assign(to: &$isAuthenticated)
        authService.$currentUser.assign(to: &$currentUser)
    }
    
    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(email: email, password: password, username: username)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateUsername(_ newUsername: String) async throws {
        try await authService.updateUsername(newUsername)
    }
}

