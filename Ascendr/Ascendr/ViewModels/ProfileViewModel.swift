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
    @Published var sharedWorkouts: [Workout] = []
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
            
            // Fetch shared workouts
            sharedWorkouts = try await databaseService.fetchSharedWorkouts(userId: userId)
            
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
        
        print("📸 Starting profile image upload for user: \(userId)")
        
        do {
            // Upload to Firebase Storage
            print("📤 Uploading image to Firebase Storage...")
            let imageURL = try await storageService.uploadProfileImage(image, userId: userId)
            print("✅ Image uploaded, URL: \(imageURL)")
            
            // Update Firebase Realtime Database
            print("💾 Saving profile image URL to database...")
            try await databaseService.updateUserProfile(userId: userId, updates: ["profileImageURL": imageURL])
            print("✅ Profile image URL saved to database")
            
            // Update local user object immediately
            user?.profileImageURL = imageURL
            
            // Refresh user data to ensure consistency
            await fetchUserData(userId: userId)
            print("✅ Profile image update complete")
        } catch {
            print("❌ Error updating profile image: \(error.localizedDescription)")
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

