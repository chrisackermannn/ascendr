//
//  AuthenticationService.swift
//  Ascendr
//
//  Firebase Authentication service with Realtime Database
//

import Foundation
import Combine
import FirebaseAuth

class AuthenticationService: ObservableObject {
    private let auth = Auth.auth()
    private let databaseService = RealtimeDatabaseService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    init() {
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // Fetch user data from Realtime Database
                    await self?.fetchUserData(userId: firebaseUser.uid)
                    self?.isAuthenticated = true
                    // Set user online
                    self?.databaseService.setUserOnline(userId: firebaseUser.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        // User data will be fetched by the state listener
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        // Validate username
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username cannot be empty"])
        }
        
        // Check if username is available
        let isAvailable = try await databaseService.isUsernameAvailable(trimmedUsername)
        guard isAvailable else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
        }
        
        // Create Firebase Auth user
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Create user object for Realtime Database
        let user = User(
            id: result.user.uid,
            email: email,
            username: trimmedUsername,
            createdAt: Date()
        )
        
        // Save user to Realtime Database
        try await databaseService.saveUser(user)
        
        // Set current user
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    func updateUsername(_ newUsername: String) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Validate username
        let trimmedUsername = newUsername.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username cannot be empty"])
        }
        
        // Check if username is available (excluding current user)
        let isAvailable = try await databaseService.isUsernameAvailable(trimmedUsername, excludingUserId: currentUser.id)
        guard isAvailable else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
        }
        
        // Update username in database
        try await databaseService.updateUserProfile(userId: currentUser.id, updates: ["username": trimmedUsername])
        
        // Update local user object
        await MainActor.run {
            self.currentUser?.username = trimmedUsername
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        // State will be updated by the listener
    }
    
    private func fetchUserData(userId: String) async {
        do {
            let user = try await databaseService.fetchUser(userId: userId)
            await MainActor.run {
                currentUser = user
            }
        } catch {
            print("Error fetching user data: \(error)")
            // If user doesn't exist in database, create a basic user record
            if let firebaseUser = auth.currentUser {
                let newUser = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    username: firebaseUser.email?.components(separatedBy: "@").first ?? "User",
                    createdAt: Date()
                )
                try? await databaseService.saveUser(newUser)
                await MainActor.run {
                    currentUser = newUser
                }
            }
        }
    }
}

