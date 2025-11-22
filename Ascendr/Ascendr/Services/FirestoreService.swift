//
//  FirestoreService.swift
//  Ascendr
//
//  Mock Firestore database service (Firebase bypassed for demo)
//

import Foundation

class FirestoreService {
    // Mock data storage
    private var mockPosts: [Post] = []
    private var mockWorkouts: [String: [Workout]] = [:]
    private var mockPartnerSessions: [String: [String: Any]] = [:]
    
    init() {
        // Add some demo posts
        let demoWorkout = Workout(
            id: UUID().uuidString,
            userId: "demo-user-1",
            userName: "Demo User",
            exercises: [],
            date: Date().addingTimeInterval(-3600),
            duration: 3600
        )
        
        let demoPost1 = Post(
            id: UUID().uuidString,
            userId: "demo-user-1",
            userName: "Demo User",
            content: "Just finished an amazing workout! 💪",
            workout: demoWorkout,
            timestamp: Date().addingTimeInterval(-3600),
            likes: ["user2", "user3"]
        )
        mockPosts.append(demoPost1)
    }
    
    // MARK: - Posts
    func fetchPosts(limit: Int = 50) async throws -> [Post] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return Array(mockPosts.prefix(limit))
    }
    
    func createPost(_ post: Post) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        mockPosts.insert(post, at: 0)
    }
    
    func likePost(postId: String, userId: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        if let index = mockPosts.firstIndex(where: { $0.id == postId }) {
            if !mockPosts[index].likes.contains(userId) {
                mockPosts[index].likes.append(userId)
            }
        }
    }
    
    func unlikePost(postId: String, userId: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        if let index = mockPosts.firstIndex(where: { $0.id == postId }) {
            mockPosts[index].likes.removeAll { $0 == userId }
        }
    }
    
    // MARK: - Workouts
    func saveWorkout(_ workout: Workout) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if mockWorkouts[workout.userId] == nil {
            mockWorkouts[workout.userId] = []
        }
        mockWorkouts[workout.userId]?.append(workout)
    }
    
    func fetchUserWorkouts(userId: String) async throws -> [Workout] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return mockWorkouts[userId]?.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    // MARK: - Partner Workouts
    func createPartnerWorkoutSession(workoutId: String, userId: String, partnerId: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        mockPartnerSessions[workoutId] = [
            "workoutId": workoutId,
            "userId": userId,
            "partnerId": partnerId,
            "createdAt": Date()
        ]
    }
    
    func listenToPartnerWorkout(workoutId: String, completion: @escaping (Workout?) -> Void) {
        // For demo: just return nil or a mock workout
        // In a real app, this would set up a listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Return nil for now - can be enhanced with mock workout if needed
            completion(nil)
        }
    }
    
    // MARK: - User Profile
    func updateUserProfile(userId: String, profileImageURL: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        // Mock implementation - just succeeds
    }
}

