//
//  RewardViewModel.swift
//  Ascendr
//
//  View model for rewards, XP, and badges
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RewardViewModel: ObservableObject {
    @Published var currentXP: Int = 0
    @Published var badges: [Badge] = []
    @Published var pinnedBadge: Badge?
    @Published var currentChallenge: MonthlyChallenge?
    @Published var challengeProgress: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService = RealtimeDatabaseService()
    
    func loadUserRewards(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let user = try await databaseService.fetchUser(userId: userId) {
                currentXP = user.xp
                badges = user.badges
                
                // Load pinned badge
                if let pinnedBadgeId = user.pinnedBadgeId {
                    pinnedBadge = badges.first { $0.id == pinnedBadgeId }
                } else {
                    pinnedBadge = nil
                }
                
                // Load current challenge
                currentChallenge = databaseService.getCurrentMonthlyChallenge()
                
                // Calculate challenge progress
                await updateChallengeProgress(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateChallengeProgress(userId: String) async {
        guard let challenge = currentChallenge else { return }
        
        do {
            let workouts = try await databaseService.fetchUserWorkoutHistory(userId: userId)
            let calendar = Calendar.current
            let currentMonthWorkouts = workouts.filter { workout in
                calendar.component(.month, from: workout.date) == challenge.month &&
                calendar.component(.year, from: workout.date) == challenge.year
            }
            challengeProgress = currentMonthWorkouts.count
        } catch {
            print("Error updating challenge progress: \(error.localizedDescription)")
        }
    }
    
    func pinBadge(_ badge: Badge, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await databaseService.pinBadge(userId: userId, badgeId: badge.id)
            pinnedBadge = badge
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func unpinBadge(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await databaseService.pinBadge(userId: userId, badgeId: nil)
            pinnedBadge = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

