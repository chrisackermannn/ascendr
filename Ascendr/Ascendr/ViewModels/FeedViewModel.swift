//
//  FeedViewModel.swift
//  Ascendr
//
//  Feed view model
//

import Foundation
import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService = RealtimeDatabaseService()
    
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts = try await databaseService.fetchPosts()
            posts = fetchedPosts
            print("✅ Successfully fetched \(fetchedPosts.count) posts")
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            print("❌ Error fetching posts: \(errorMsg)")
            print("Error details: \(error)")
        }
        
        isLoading = false
    }
    
    func likePost(_ post: Post, userId: String) async {
        do {
            if post.likes.contains(userId) {
                try await databaseService.unlikePost(postId: post.id, userId: userId)
            } else {
                try await databaseService.likePost(postId: post.id, userId: userId)
            }
            // Refresh posts
            await fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func copyTemplate(from post: Post, userId: String, templateName: String) async throws {
        guard let workout = post.workout else {
            throw NSError(domain: "FeedViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No workout in post"])
        }
        
        // Create a new workout for the template
        var templateWorkout = workout
        templateWorkout.id = UUID().uuidString
        templateWorkout.date = Date()
        templateWorkout.duration = 0
        templateWorkout.partnerId = nil
        templateWorkout.partnerName = nil
        
        // Store original sets as referenceSets, then clear sets (user will add their own)
        for i in 0..<templateWorkout.exercises.count {
            templateWorkout.exercises[i].referenceSets = templateWorkout.exercises[i].sets
            templateWorkout.exercises[i].sets = []
        }
        
        try await databaseService.saveTemplate(userId: userId, template: templateWorkout, templateName: templateName)
    }
}

