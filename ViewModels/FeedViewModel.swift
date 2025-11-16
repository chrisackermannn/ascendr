//
//  FeedViewModel.swift
//  Ascendr
//
//  Feed view model
//

import Foundation
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            posts = try await firestoreService.fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func likePost(_ post: Post, userId: String) async {
        do {
            if post.likes.contains(userId) {
                try await firestoreService.unlikePost(postId: post.id, userId: userId)
            } else {
                try await firestoreService.likePost(postId: post.id, userId: userId)
            }
            // Refresh posts
            await fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

