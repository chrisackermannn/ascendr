//
//  ProfileViewModel.swift
//  Ascendr
//
//  Profile view model
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var workouts: [Workout] = []
    @Published var progressPics: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    
    func fetchUserData(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            workouts = try await firestoreService.fetchUserWorkouts(userId: userId)
            
            // Fetch progress pics (posts with progressPicURL)
            let allPosts = try await firestoreService.fetchPosts(limit: 100)
            progressPics = allPosts.filter { $0.userId == userId && $0.progressPicURL != nil }
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
            try await firestoreService.updateUserProfile(userId: userId, profileImageURL: imageURL)
            
            // Update local user object
            user?.profileImageURL = imageURL
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

