//
//  Workout.swift
//  Ascendr
//
//  Workout model
//

import Foundation

struct Workout: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var exercises: [Exercise]
    var date: Date
    var duration: TimeInterval // in seconds
    var partnerId: String? // For partner workouts
    var partnerName: String?
    
    init(id: String = UUID().uuidString, userId: String, userName: String, exercises: [Exercise] = [], date: Date = Date(), duration: TimeInterval = 0, partnerId: String? = nil, partnerName: String? = nil) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.exercises = exercises
        self.date = date
        self.duration = duration
        self.partnerId = partnerId
        self.partnerName = partnerName
    }
}

struct Exercise: Identifiable, Codable {
    var id: String
    var name: String
    var sets: [Set]
    
    init(id: String = UUID().uuidString, name: String, sets: [Set] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}

struct Set: Identifiable, Codable {
    var id: String
    var reps: Int
    var weight: Double // in lbs or kg
    var restTime: TimeInterval? // in seconds
    
    init(id: String = UUID().uuidString, reps: Int, weight: Double, restTime: TimeInterval? = nil) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
    }
}

