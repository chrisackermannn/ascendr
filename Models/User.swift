//
//  User.swift
//  Ascendr
//
//  User model for Firebase
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var username: String
    var profileImageURL: String?
    var createdAt: Date
    
    init(id: String, email: String, username: String, profileImageURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.username = username
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
    }
}

