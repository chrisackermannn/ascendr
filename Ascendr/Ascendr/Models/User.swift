//
//  User.swift
//  Ascendr
//
//  User model for Firebase Realtime Database
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var username: String
    var profileImageURL: String?
    var createdAt: Date
    var bio: String?
    var workoutCount: Int
    var totalWorkoutTime: TimeInterval // in seconds
    
    init(id: String, email: String, username: String, profileImageURL: String? = nil, createdAt: Date = Date(), bio: String? = nil, workoutCount: Int = 0, totalWorkoutTime: TimeInterval = 0) {
        self.id = id
        self.email = email
        self.username = username
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.bio = bio
        self.workoutCount = workoutCount
        self.totalWorkoutTime = totalWorkoutTime
    }
    
    // Custom encoding for Realtime Database (dates as timestamps)
    enum CodingKeys: String, CodingKey {
        case id, email, username, profileImageURL, bio, workoutCount, totalWorkoutTime
        case createdAt = "createdAtTimestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        workoutCount = try container.decodeIfPresent(Int.self, forKey: .workoutCount) ?? 0
        totalWorkoutTime = try container.decodeIfPresent(TimeInterval.self, forKey: .totalWorkoutTime) ?? 0
        
        // Decode timestamp as Date
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(workoutCount, forKey: .workoutCount)
        try container.encode(totalWorkoutTime, forKey: .totalWorkoutTime)
        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
    }
}

