//
//  FriendRequest.swift
//  Ascendr
//
//  Friend request model
//

import Foundation

struct FriendRequest: Identifiable {
    var id: String { fromUserId }
    let fromUserId: String
    let toUserId: String
    let status: String // "pending", "accepted", "rejected"
    let timestamp: Date
}

struct UserStatus: Identifiable {
    var id: String { userId }
    let userId: String
    let status: Bool // true = online, false = offline
    let lastSeen: Date
    
    // Check if user is actually online (status is true AND last seen within 2 minutes)
    var isOnline: Bool {
        guard status else { return false }
        let timeSinceLastSeen = Date().timeIntervalSince(lastSeen)
        return timeSinceLastSeen <= 120 // 2 minutes = 120 seconds
    }
}

