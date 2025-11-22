//
//  Post.swift
//  Ascendr
//
//  Post model for feed
//

import Foundation

struct Post: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var userProfileImageURL: String?
    var content: String? // Optional text caption
    var workout: Workout? // Optional workout data
    var progressPicURL: String? // Optional progress picture
    var timestamp: Date
    var likes: [String] // Array of user IDs who liked
    
    init(id: String = UUID().uuidString, userId: String, userName: String, userProfileImageURL: String? = nil, content: String? = nil, workout: Workout? = nil, progressPicURL: String? = nil, timestamp: Date = Date(), likes: [String] = []) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userProfileImageURL = userProfileImageURL
        self.content = content
        self.workout = workout
        self.progressPicURL = progressPicURL
        self.timestamp = timestamp
        self.likes = likes
    }
}

