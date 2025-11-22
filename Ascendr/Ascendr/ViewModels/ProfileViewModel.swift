//
//  ProfileViewModel.swift
//  Ascendr
//
//  Profile view model
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var workouts: [Workout] = []
    @Published var progressPics: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService = RealtimeDatabaseService()
    private let storageService = StorageService()
    
    func fetchUserData(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch user profile
            user = try await databaseService.fetchUser(userId: userId)
            
            // Fetch workout history
            workouts = try await databaseService.fetchUserWorkoutHistory(userId: userId)
            
            // Progress pics can be fetched from posts if needed
            // For now, we'll keep it empty or fetch from a posts collection if you add one
            progressPics = []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateProfileImage(_ image: UIImage, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let imageURL = try await storageService.uploadProfileImage(image, userId: userId)
            try await databaseService.updateUserProfile(userId: userId, updates: ["profileImageURL": imageURL])
            
            // Update local user object
            user?.profileImageURL = imageURL
            
            // Refresh user data to get updated profile
            await fetchUserData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateBio(_ bio: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await databaseService.updateUserProfile(userId: userId, updates: ["bio": bio])
            user?.bio = bio
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

