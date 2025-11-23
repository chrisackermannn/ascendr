//
//  Message.swift
//  Ascendr
//
//  Message model for chat system
//

import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
    let isRead: Bool
    
    init(id: String = UUID().uuidString, senderId: String, receiverId: String, text: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    // Convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text,
            "timestamp": timestamp.timeIntervalSince1970,
            "isRead": isRead
        ]
    }
    
    // Initialize from Firebase snapshot
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let senderId = dictionary["senderId"] as? String,
              let receiverId = dictionary["receiverId"] as? String,
              let text = dictionary["text"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.isRead = dictionary["isRead"] as? Bool ?? false
    }
}

// Conversation model to group messages
struct Conversation: Identifiable {
    let id: String // This will be the other user's ID
    let otherUser: User
    let lastMessage: Message?
    let unreadCount: Int
    
    init(id: String, otherUser: User, lastMessage: Message?, unreadCount: Int = 0) {
        self.id = id
        self.otherUser = otherUser
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
}

