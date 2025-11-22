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
    
    private let databaseService = RealtimeDatabaseService()
    private var sessionHandle: DatabaseHandle?
    
    func startLiveWorkout(sessionId: String, currentUserId: String) {
        self.currentUserId = currentUserId
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
                self?.exercises = session.exercises
                
                // Determine if current user is user1 or user2
                self?.isUser1 = session.userId1 == currentUserId
                self?.partnerId = self?.isUser1 == true ? session.userId2 : session.userId1
                self?.partnerName = self?.isUser1 == true ? session.userName2 : session.userName1
                
                self?.isLoading = false
            }
        }
    }
    
    func addExercise(_ exercise: Exercise) async {
        guard let sessionId = session?.sessionId,
              let userId = currentUserId else { return }
        
        do {
            try await databaseService.addExerciseToLiveWorkout(sessionId: sessionId, exercise: exercise, addedByUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addSet(to exerciseId: String, set: Set) async {
        guard let sessionId = session?.sessionId,
              let userId = currentUserId else { return }
        
        do {
            try await databaseService.addSetToLiveWorkoutExercise(sessionId: sessionId, exerciseId: exerciseId, set: set, addedByUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func endWorkout() async {
        guard let sessionId = session?.sessionId else { return }
        
        do {
            try await databaseService.endLiveWorkoutSession(sessionId: sessionId)
            cleanup()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cleanup() {
        if let handle = sessionHandle {
            Database.database().reference().child("liveWorkouts").child(session?.sessionId ?? "").removeObserver(withHandle: handle)
            sessionHandle = nil
        }
        session = nil
        exercises = []
    }
}

