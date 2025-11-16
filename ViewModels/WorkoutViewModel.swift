//
//  WorkoutViewModel.swift
//  Ascendr
//
//  Workout view model
//

import Foundation
import SwiftUI

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
    
    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()
    
    func startWorkout(userId: String, userName: String, partnerId: String? = nil, partnerName: String? = nil) {
        isPartnerMode = partnerId != nil
        self.partnerId = partnerId
        self.partnerName = partnerName
        workoutStartTime = Date()
        
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
        
        // If in partner mode, sync to Firebase
        if isPartnerMode, let workout = currentWorkout {
            Task {
                await syncWorkoutToPartner(workout)
            }
        }
    }
    
    func finishWorkout() async {
        guard var workout = currentWorkout else { return }
        
        isLoading = true
        errorMessage = nil
        
        if let startTime = workoutStartTime {
            workout.duration = Date().timeIntervalSince(startTime)
        }
        
        do {
            try await firestoreService.saveWorkout(workout)
            
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
    
    private func syncWorkoutToPartner(_ workout: Workout) async {
        do {
            try await firestoreService.saveWorkout(workout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func listenToPartnerWorkout(workoutId: String) {
        firestoreService.listenToPartnerWorkout(workoutId: workoutId) { [weak self] workout in
            Task { @MainActor in
                self?.currentWorkout = workout
                self?.exercises = workout?.exercises ?? []
            }
        }
    }
}

