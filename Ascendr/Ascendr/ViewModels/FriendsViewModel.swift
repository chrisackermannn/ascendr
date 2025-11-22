//
//  FriendsViewModel.swift
//  Ascendr
//
//  Friends view model
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchResults: [User] = []
    @Published var userStatuses: [String: UserStatus] = [:]
    @Published var liveWorkoutInvite: LiveWorkoutInvite?
    @Published var pendingSessionId: String? // Session ID waiting for partner to accept
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService = RealtimeDatabaseService()
    private var statusHandles: [String: DatabaseHandle] = [:]
    private var inviteHandle: DatabaseHandle?
    
    func fetchFriends(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let friendIds = try await databaseService.getFriends(userId: userId)
            var fetchedFriends: [User] = []
            
            for friendId in friendIds {
                if let friend = try await databaseService.fetchUser(userId: friendId) {
                    fetchedFriends.append(friend)
                    // Start listening to friend's status
                    listenToFriendStatus(friendId: friendId)
                }
            }
            
            friends = fetchedFriends
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchFriendRequests(userId: String) async {
        do {
            friendRequests = try await databaseService.getFriendRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchUsers(query: String, currentUserId: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await databaseService.searchUsers(query: query, currentUserId: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func sendFriendRequest(from userId: String, to friendId: String) async {
        do {
            try await databaseService.sendFriendRequest(from: userId, to: friendId)
            await fetchFriendRequests(userId: friendId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(from userId: String, to currentUserId: String) async {
        do {
            try await databaseService.acceptFriendRequest(from: userId, to: currentUserId)
            await fetchFriendRequests(userId: currentUserId)
            await fetchFriends(userId: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func rejectFriendRequest(from userId: String, to currentUserId: String) async {
        do {
            try await databaseService.rejectFriendRequest(from: userId, to: currentUserId)
            await fetchFriendRequests(userId: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(userId: String, friendId: String) async {
        do {
            try await databaseService.removeFriend(userId: userId, friendId: friendId)
            await fetchFriends(userId: userId)
            // Stop listening to removed friend's status
            if let handle = statusHandles[friendId] {
                Database.database().reference().child("userStatus").child(friendId).removeObserver(withHandle: handle)
                statusHandles.removeValue(forKey: friendId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func listenToFriendStatus(friendId: String) {
        // Remove existing listener if any
        if let existingHandle = statusHandles[friendId] {
            Database.database().reference().child("userStatus").child(friendId).removeObserver(withHandle: existingHandle)
        }
        
        let handle = databaseService.listenToUserStatus(userId: friendId) { [weak self] status in
            Task { @MainActor in
                if let status = status {
                    self?.userStatuses[friendId] = status
                } else {
                    self?.userStatuses.removeValue(forKey: friendId)
                }
            }
        }
        
        statusHandles[friendId] = handle
    }
    
    func getStatus(for userId: String) -> UserStatus? {
        return userStatuses[userId]
    }
    
    func startListeningForInvites(userId: String) {
        // Remove existing listener if any
        if let existingHandle = inviteHandle {
            Database.database().reference().child("liveWorkoutInvites").child(userId).removeObserver(withHandle: existingHandle)
        }
        
        inviteHandle = databaseService.listenToLiveWorkoutInvites(userId: userId) { [weak self] invite in
            Task { @MainActor in
                self?.liveWorkoutInvite = invite
            }
        }
        
        // Also listen for session notifications (when someone accepts your invite)
        let notificationsRef = Database.database().reference().child("liveWorkoutNotifications").child(userId)
        notificationsRef.observe(.childAdded) { [weak self] snapshot, _ in
            guard let sessionData = snapshot.value as? [String: Any],
                  let sessionId = sessionData["sessionId"] as? String else { return }
            
            Task { @MainActor in
                self?.pendingSessionId = sessionId
                // Remove notification after reading
                snapshot.ref.removeValue()
            }
        }
    }
    
    func stopListeningForInvites(userId: String) {
        if let handle = inviteHandle {
            Database.database().reference().child("liveWorkoutInvites").child(userId).removeObserver(withHandle: handle)
            inviteHandle = nil
        }
    }
    
    func cleanup() {
        // Remove all status listeners
        for (friendId, handle) in statusHandles {
            Database.database().reference().child("userStatus").child(friendId).removeObserver(withHandle: handle)
        }
        statusHandles.removeAll()
        
        // Remove invite listener
        if let userId = friends.first?.id, let handle = inviteHandle {
            Database.database().reference().child("liveWorkoutInvites").child(userId).removeObserver(withHandle: handle)
            inviteHandle = nil
        }
    }
}

