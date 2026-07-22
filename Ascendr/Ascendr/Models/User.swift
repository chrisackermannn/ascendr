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
    var xp: Int // Experience points
    var badges: [Badge] // Earned badges
    var pinnedBadgeId: String? // Badge ID pinned to profile
    
    init(id: String, email: String, username: String, profileImageURL: String? = nil, createdAt: Date = Date(), bio: String? = nil, workoutCount: Int = 0, totalWorkoutTime: TimeInterval = 0, xp: Int = 0, badges: [Badge] = [], pinnedBadgeId: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.bio = bio
        self.workoutCount = workoutCount
        self.totalWorkoutTime = totalWorkoutTime
        self.xp = xp
        self.badges = badges
        self.pinnedBadgeId = pinnedBadgeId
    }
    
    // Custom encoding for Realtime Database (dates as timestamps)
    enum CodingKeys: String, CodingKey {
        case id, email, username, profileImageURL, bio, workoutCount, totalWorkoutTime, xp, badges, pinnedBadgeId
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
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        badges = try container.decodeIfPresent([Badge].self, forKey: .badges) ?? []
        pinnedBadgeId = try container.decodeIfPresent(String.self, forKey: .pinnedBadgeId)
        
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
        try container.encode(xp, forKey: .xp)
        try container.encode(badges, forKey: .badges)
        try container.encodeIfPresent(pinnedBadgeId, forKey: .pinnedBadgeId)
        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
    }
}

