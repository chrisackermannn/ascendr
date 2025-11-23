//
//  LiveWorkoutViewModel.swift
//  Ascendr
//
//  Live workout view model
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class LiveWorkoutViewModel: ObservableObject {
    @Published var session: LiveWorkoutSession?
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?
    @Published var partnerId: String?
    @Published var partnerName: String?
    @Published var isUser1: Bool = false
    @Published var workoutStartTime: Date?
    
    private let databaseService = RealtimeDatabaseService()
    private var sessionHandle: DatabaseHandle?
    var currentUserName: String? // Will be set from view
    
    func startLiveWorkout(sessionId: String, currentUserId: String) {
        self.currentUserId = currentUserId
        self.workoutStartTime = Date()
        isLoading = true
        
        // Listen to session changes
        sessionHandle = databaseService.listenToLiveWorkout(sessionId: sessionId) { [weak self] session in
            Task { @MainActor in
                guard let session = session, session.status == "active" else {
                    self?.session = nil
                    self?.isLoading = false
                    return
                }
                
                self?.session = session
                // Update exercises - this will trigger UI refresh
                self?.exercises = session.exercises
                print("🔄 Exercises updated: \(session.exercises.count) exercises")
                for exercise in session.exercises {
                    print("   - \(exercise.name): \(exercise.sets.count) sets")
                }
                
                // Determine if current user is user1 or user2
                self?.isUser1 = session.userId1 == currentUserId
                self?.partnerId = self?.isUser1 == true ? session.userId2 : session.userId1
                self?.partnerName = self?.isUser1 == true ? session.userName2 : session.userName1
                
                // Set start time if not already set
                if self?.workoutStartTime == nil {
                    self?.workoutStartTime = Date()
                }
                
                self?.isLoading = false
            }
        }
    }
    
    func addExercise(_ exercise: Exercise) async {
        guard let session = session,
              !session.sessionId.isEmpty,
              let addedByUserId = exercise.addedByUserId,
              !addedByUserId.isEmpty else {
            print("❌ Cannot add exercise: Invalid session or exercise data")
            print("   sessionId: \(session?.sessionId ?? "nil")")
            print("   addedByUserId: \(exercise.addedByUserId ?? "nil")")
            errorMessage = "Cannot add exercise: Invalid session or exercise"
            return
        }
        
        let sessionId = session.sessionId
        
        // Validate Firebase path characters
        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        guard sessionId.rangeOfCharacter(from: invalidChars) == nil else {
            print("❌ Cannot add exercise: Invalid characters in sessionId")
            errorMessage = "Cannot add exercise: Invalid characters in path"
            return
        }
        
        do {
            print("📤 Adding exercise '\(exercise.name)' to session \(sessionId) for user \(addedByUserId)")
            try await databaseService.addExerciseToLiveWorkout(sessionId: sessionId, exercise: exercise, addedByUserId: addedByUserId)
            print("✅ Exercise added successfully")
            // The Firebase listener will update exercises automatically
        } catch {
            print("❌ Error adding exercise: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func addSet(to exerciseId: String, set: Set) async {
        guard let session = session,
              !session.sessionId.isEmpty,
              !exerciseId.isEmpty,
              let userId = currentUserId,
              !userId.isEmpty else {
            print("❌ Cannot add set: Invalid sessionId, exerciseId, or userId")
            print("   sessionId: \(session?.sessionId ?? "nil")")
            print("   exerciseId: \(exerciseId)")
            print("   userId: \(currentUserId ?? "nil")")
            errorMessage = "Cannot add set: Invalid session or exercise"
            return
        }
        
        let sessionId = session.sessionId
        
        // Validate Firebase path characters
        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        guard sessionId.rangeOfCharacter(from: invalidChars) == nil,
              exerciseId.rangeOfCharacter(from: invalidChars) == nil else {
            print("❌ Cannot add set: Invalid characters in sessionId or exerciseId")
            print("   sessionId: \(sessionId)")
            print("   exerciseId: \(exerciseId)")
            errorMessage = "Cannot add set: Invalid characters in path"
            return
        }
        
        do {
            print("📤 Adding set to exercise \(exerciseId) in session \(sessionId)")
            try await databaseService.addSetToLiveWorkoutExercise(sessionId: sessionId, exerciseId: exerciseId, set: set, addedByUserId: userId)
            print("✅ Set added successfully to exercise \(exerciseId)")
            // The Firebase listener will update exercises automatically
        } catch {
            print("❌ Error adding set: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func endWorkout(currentUserName: String) async {
        guard let session = session,
              !session.sessionId.isEmpty,
              let currentUserId = currentUserId else {
            print("❌ Cannot end workout: Invalid or empty sessionId")
            print("   session: \(session != nil ? "exists" : "nil")")
            print("   sessionId: \(session?.sessionId ?? "nil")")
            errorMessage = "Cannot end workout: Invalid session"
            cleanup()
            return
        }
        
        let sessionId = session.sessionId
        
        // Validate Firebase path characters
        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        guard sessionId.rangeOfCharacter(from: invalidChars) == nil else {
            print("❌ Cannot end workout: Invalid characters in sessionId: \(sessionId)")
            errorMessage = "Cannot end workout: Invalid characters in path"
            cleanup()
            return
        }
        
        do {
            print("🛑 Ending workout session: \(sessionId)")
            
            // Calculate duration
            let duration = workoutStartTime.map { Date().timeIntervalSince($0) } ?? 0
            
            // Create shared workout for both users (contains all exercises from both users)
            let sharedWorkout = Workout(
                id: sessionId,
                userId: session.userId1,
                userName: session.userName1,
                exercises: exercises,
                date: Date(),
                duration: duration,
                partnerId: session.userId2,
                partnerName: session.userName2
            )
            
            // Save shared workout to BOTH users' shared workouts folder
            print("💾 Saving shared workout for both users...")
            try await databaseService.saveSharedWorkout(
                userId1: session.userId1,
                userName1: session.userName1,
                userId2: session.userId2,
                userName2: session.userName2,
                workout: sharedWorkout
            )
            print("✅ Shared workout saved for both users")
            
            // Create personal workouts for each user (only their exercises)
            let user1Exercises = exercises.filter { $0.addedByUserId == session.userId1 }
            let user2Exercises = exercises.filter { $0.addedByUserId == session.userId2 }
            
            let user1Workout = Workout(
                id: "\(sessionId)_user1",
                userId: session.userId1,
                userName: session.userName1,
                exercises: user1Exercises,
                date: Date(),
                duration: duration,
                partnerId: session.userId2,
                partnerName: session.userName2
            )
            
            let user2Workout = Workout(
                id: "\(sessionId)_user2",
                userId: session.userId2,
                userName: session.userName2,
                exercises: user2Exercises,
                date: Date(),
                duration: duration,
                partnerId: session.userId1,
                partnerName: session.userName1
            )
            
            // Save personal workouts to EACH user's history
            print("💾 Saving personal workout for user1 (\(session.userName1))...")
            try await databaseService.saveWorkoutToHistory(userId: session.userId1, workout: user1Workout)
            print("✅ Personal workout saved for user1")
            
            print("💾 Saving personal workout for user2 (\(session.userName2))...")
            try await databaseService.saveWorkoutToHistory(userId: session.userId2, workout: user2Workout)
            print("✅ Personal workout saved for user2")
            
            // End the live workout session
            try await databaseService.endLiveWorkoutSession(sessionId: sessionId)
            
            print("✅ Workout ended and saved successfully for BOTH users (shared + personal)")
            cleanup()
        } catch {
            print("❌ Error ending workout: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            cleanup()
        }
    }
    
    func cleanup() {
        if let handle = sessionHandle, let sessionId = session?.sessionId, !sessionId.isEmpty {
            // Validate Firebase path characters before removing observer
            let invalidChars = CharacterSet(charactersIn: ".#$[]")
            if sessionId.rangeOfCharacter(from: invalidChars) == nil {
                Database.database().reference().child("liveWorkouts").child(sessionId).removeObserver(withHandle: handle)
            }
            sessionHandle = nil
        }
        session = nil
        exercises = []
        workoutStartTime = nil
    }
}

