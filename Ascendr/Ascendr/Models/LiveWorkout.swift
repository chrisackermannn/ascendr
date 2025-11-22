//
//  LiveWorkout.swift
//  Ascendr
//
//  Live workout models
//

import Foundation

struct LiveWorkoutInvite: Identifiable {
    var id: String { inviteId }
    let inviteId: String
    let fromUserId: String
    let fromUserName: String
    let toUserId: String
    let status: String
    let timestamp: Date
}

struct LiveWorkoutSession: Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let userId1: String
    let userName1: String
    let userId2: String
    let userName2: String
    let status: String
    var exercises: [Exercise]
}

