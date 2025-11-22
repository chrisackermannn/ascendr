//
//  WorkoutViewModel.swift
//  Ascendr
//
//  Workout view model
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var exercises: [Exercise] = []
    @Published var isPartnerMode = false
    @Published var partnerId: String?
    @Published var partnerName: String?
    @Published var workoutStartTime: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var templates: [(id: String, name: String, workout: Workout)] = []
    
    private let databaseService = RealtimeDatabaseService()
    private let authService = AuthenticationService()
    
    func startWorkout(userId: String, userName: String, partnerId: String? = nil, partnerName: String? = nil) {
        isPartnerMode = partnerId != nil
        self.partnerId = partnerId
        self.partnerName = partnerName
        workoutStartTime = Date()
        
        // Clear any existing exercises
        exercises = []
        
        currentWorkout = Workout(
            userId: userId,
            userName: userName,
            exercises: [],
            date: Date(),
            partnerId: partnerId,
            partnerName: partnerName
        )
    }
    
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        currentWorkout?.exercises.append(exercise)
    }
    
    func addSet(to exerciseId: String, set: Set) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].sets.append(set)
            if let workoutIndex = currentWorkout?.exercises.firstIndex(where: { $0.id == exerciseId }) {
                currentWorkout?.exercises[workoutIndex].sets.append(set)
            }
        }
        
        // If in partner mode, sync to Realtime Database
        if isPartnerMode, let workout = currentWorkout {
            Task {
                await syncWorkoutToPartner(workout)
            }
        }
    }
    
    var canFinishWorkout: Bool {
        guard !exercises.isEmpty else { return false }
        
        // Check if all exercises have at least one set
        for exercise in exercises {
            if exercise.sets.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    func finishWorkout(shouldPostToFeed: Bool = false) async {
        guard var workout = currentWorkout else { return }
        
        // Validate workout before finishing
        guard canFinishWorkout else {
            errorMessage = "Please add at least one set to each exercise before finishing."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if let startTime = workoutStartTime {
            workout.duration = Date().timeIntervalSince(startTime)
        }
        
        do {
            // Save workout to user's workout history in Realtime Database
            try await databaseService.saveWorkoutToHistory(userId: workout.userId, workout: workout)
            
            // Post to feed if requested
            if shouldPostToFeed {
                let post = Post(
                    userId: workout.userId,
                    userName: workout.userName,
                    userProfileImageURL: nil, // Can be updated later
                    content: "Just finished an amazing workout! 💪",
                    workout: workout,
                    timestamp: Date()
                )
                try await databaseService.createPost(post)
            }
            
            // Reset state
            currentWorkout = nil
            exercises = []
            isPartnerMode = false
            partnerId = nil
            partnerName = nil
            workoutStartTime = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchTemplates(userId: String) async {
        do {
            templates = try await databaseService.fetchTemplates(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func importTemplate(_ template: Workout, userId: String, userName: String) {
        // Create a new workout from template
        var newWorkout = template
        newWorkout.id = UUID().uuidString
        newWorkout.userId = userId
        newWorkout.userName = userName
        newWorkout.date = Date()
        newWorkout.duration = 0
        newWorkout.partnerId = nil
        newWorkout.partnerName = nil
        
        // Clear sets - user will add their own
        for i in 0..<newWorkout.exercises.count {
            newWorkout.exercises[i].sets = []
        }
        
        // Start the workout
        currentWorkout = newWorkout
        exercises = newWorkout.exercises
        workoutStartTime = Date()
    }
    
    private func syncWorkoutToPartner(_ workout: Workout) async {
        do {
            // Sync workout to both users' histories if in partner mode
            try await databaseService.saveWorkoutToHistory(userId: workout.userId, workout: workout)
            if let partnerId = workout.partnerId {
                var partnerWorkout = workout
                partnerWorkout.userId = partnerId
                partnerWorkout.userName = workout.partnerName ?? "Partner"
                try await databaseService.saveWorkoutToHistory(userId: partnerId, workout: partnerWorkout)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

