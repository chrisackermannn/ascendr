//
//  Badge.swift
//  Ascendr
//
//  Badge model for rewards system
//

import Foundation

struct Badge: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var iconName: String // SF Symbol name
    var category: BadgeCategory
    var earnedDate: Date?
    var challengeId: String? // If earned from a challenge
    
    init(id: String = UUID().uuidString, name: String, description: String, iconName: String, category: BadgeCategory, earnedDate: Date? = nil, challengeId: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.earnedDate = earnedDate
        self.challengeId = challengeId
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, iconName, category, challengeId
        case earnedDate = "earnedDateTimestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        iconName = try container.decode(String.self, forKey: .iconName)
        category = try container.decode(BadgeCategory.self, forKey: .category)
        challengeId = try container.decodeIfPresent(String.self, forKey: .challengeId)
        
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .earnedDate) {
            earnedDate = Date(timeIntervalSince1970: timestamp)
        } else {
            earnedDate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(challengeId, forKey: .challengeId)
        if let earnedDate = earnedDate {
            try container.encode(earnedDate.timeIntervalSince1970, forKey: .earnedDate)
        }
    }
}

enum BadgeCategory: String, Codable, CaseIterable {
    case monthlyChallenge = "Monthly Challenge"
    case workoutMilestone = "Workout Milestone"
    case xpMilestone = "XP Milestone"
    case streak = "Streak"
    case special = "Special"
}

struct MonthlyChallenge: Identifiable, Codable {
    var id: String
    var month: Int // 1-12
    var year: Int
    var name: String
    var description: String
    var targetWorkouts: Int
    var badge: Badge
    var startDate: Date
    var endDate: Date
    
    init(id: String = UUID().uuidString, month: Int, year: Int, name: String, description: String, targetWorkouts: Int, badge: Badge, startDate: Date, endDate: Date) {
        self.id = id
        self.month = month
        self.year = year
        self.name = name
        self.description = description
        self.targetWorkouts = targetWorkouts
        self.badge = badge
        self.startDate = startDate
        self.endDate = endDate
    }
    
    enum CodingKeys: String, CodingKey {
        case id, month, year, name, description, targetWorkouts, badge
        case startDate = "startDateTimestamp"
        case endDate = "endDateTimestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        targetWorkouts = try container.decode(Int.self, forKey: .targetWorkouts)
        badge = try container.decode(Badge.self, forKey: .badge)
        
        let startTimestamp = try container.decode(TimeInterval.self, forKey: .startDate)
        startDate = Date(timeIntervalSince1970: startTimestamp)
        
        let endTimestamp = try container.decode(TimeInterval.self, forKey: .endDate)
        endDate = Date(timeIntervalSince1970: endTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(targetWorkouts, forKey: .targetWorkouts)
        try container.encode(badge, forKey: .badge)
        try container.encode(startDate.timeIntervalSince1970, forKey: .startDate)
        try container.encode(endDate.timeIntervalSince1970, forKey: .endDate)
    }
}

