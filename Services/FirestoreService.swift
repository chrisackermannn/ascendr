//
//  FirestoreService.swift
//  Ascendr
//
//  Firestore database service
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - Posts
    func fetchPosts(limit: Int = 50) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Post.self)
        }
    }
    
    func createPost(_ post: Post) async throws {
        try db.collection("posts").document(post.id).setData(from: post)
    }
    
    func likePost(postId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData([
            "likes": FieldValue.arrayUnion([userId])
        ])
    }
    
    func unlikePost(postId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData([
            "likes": FieldValue.arrayRemove([userId])
        ])
    }
    
    // MARK: - Workouts
    func saveWorkout(_ workout: Workout) async throws {
        try db.collection("workouts").document(workout.id).setData(from: workout)
    }
    
    func fetchUserWorkouts(userId: String) async throws -> [Workout] {
        let snapshot = try await db.collection("workouts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Workout.self)
        }
    }
    
    // MARK: - Partner Workouts
    func createPartnerWorkoutSession(workoutId: String, userId: String, partnerId: String) async throws {
        let session: [String: Any] = [
            "workoutId": workoutId,
            "userId": userId,
            "partnerId": partnerId,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("partnerWorkoutSessions").document(workoutId).setData(session)
    }
    
    func listenToPartnerWorkout(workoutId: String, completion: @escaping (Workout?) -> Void) {
        db.collection("workouts").document(workoutId).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let workout = try snapshot.data(as: Workout.self)
                completion(workout)
            } catch {
                print("Error decoding workout: \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - User Profile
    func updateUserProfile(userId: String, profileImageURL: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "profileImageURL": profileImageURL
        ])
    }
}

