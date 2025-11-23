//
//  RealtimeDatabaseService.swift
//  Ascendr
//
//  Firebase Realtime Database service
//

import Foundation
import FirebaseDatabase

class RealtimeDatabaseService {
    private let database = Database.database().reference()
    
    // MARK: - User Management
    
    /// Save or update user data in Realtime Database
    func saveUser(_ user: User) async throws {
        let userRef = database.child("users").child(user.id)
        
        // Convert User to dictionary for Realtime Database
        var userDict: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "createdAtTimestamp": user.createdAt.timeIntervalSince1970,
            "workoutCount": user.workoutCount,
            "totalWorkoutTime": user.totalWorkoutTime
        ]
        
        if let profileImageURL = user.profileImageURL {
            userDict["profileImageURL"] = profileImageURL
        }
        
        if let bio = user.bio {
            userDict["bio"] = bio
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userRef.setValue(userDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Fetch user data from Realtime Database
    func fetchUser(userId: String) async throws -> User? {
        let userRef = database.child("users").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User?, Error>) in
            userRef.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let user = try self.decodeUser(from: value, userId: userId)
                    continuation.resume(returning: user)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Fetch all users (for future features like search)
    func fetchAllUsers() async throws -> [User] {
        let usersRef = database.child("users")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[User], Error>) in
            usersRef.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var users: [User] = []
                for (userId, userData) in value {
                    if let user = try? self.decodeUser(from: userData, userId: userId) {
                        users.append(user)
                    }
                }
                continuation.resume(returning: users)
            }
        }
    }
    
    /// Update user profile
    func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        let userRef = database.child("users").child(userId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Workout History
    
    /// Save workout to user's workout history
    func saveWorkoutToHistory(userId: String, workout: Workout) async throws {
        let workoutRef = database.child("users").child(userId).child("workouts").child(workout.id)
        
        var workoutDict: [String: Any] = [
            "id": workout.id,
            "userId": workout.userId,
            "userName": workout.userName,
            "dateTimestamp": workout.date.timeIntervalSince1970,
            "duration": workout.duration
        ]
        
        if let partnerId = workout.partnerId {
            workoutDict["partnerId"] = partnerId
        }
        
        if let partnerName = workout.partnerName {
            workoutDict["partnerName"] = partnerName
        }
        
        // Encode exercises
        var exercisesArray: [[String: Any]] = []
        for exercise in workout.exercises {
            var exerciseDict: [String: Any] = [
                "id": exercise.id,
                "name": exercise.name
            ]
            
            // Add optional equipment and category
            if let equipment = exercise.equipment {
                exerciseDict["equipment"] = equipment.rawValue
            }
            if let category = exercise.category {
                exerciseDict["category"] = category.rawValue
            }
            
            var setsArray: [[String: Any]] = []
            for set in exercise.sets {
                setsArray.append([
                    "id": set.id,
                    "reps": set.reps,
                    "weight": set.weight,
                    "restTime": set.restTime ?? 0
                ])
            }
            exerciseDict["sets"] = setsArray
            exercisesArray.append(exerciseDict)
        }
        workoutDict["exercises"] = exercisesArray
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            workoutRef.setValue(workoutDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Update user stats
        try await updateUserStats(userId: userId, workoutDuration: workout.duration)
    }
    
    /// Fetch user's workout history
    func fetchUserWorkoutHistory(userId: String) async throws -> [Workout] {
        let workoutsRef = database.child("users").child(userId).child("workouts")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Workout], Error>) in
            workoutsRef.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var workouts: [Workout] = []
                for (_, workoutData) in value {
                    if let workout = try? self.decodeWorkout(from: workoutData) {
                        workouts.append(workout)
                    }
                }
                // Sort by date descending
                workouts.sort { $0.date > $1.date }
                continuation.resume(returning: workouts)
            }
        }
    }
    
    /// Save shared workout to both users' shared workouts folder
    func saveSharedWorkout(userId1: String, userName1: String, userId2: String, userName2: String, workout: Workout) async throws {
        // Create a unique key for the shared workout (combine both user IDs)
        let sharedWorkoutKey = [userId1, userId2].sorted().joined(separator: "_")
        
        // Save to user1's shared workouts
        let user1SharedRef = database.child("users").child(userId1).child("sharedWorkouts").child(sharedWorkoutKey)
        
        // Save to user2's shared workouts
        let user2SharedRef = database.child("users").child(userId2).child("sharedWorkouts").child(sharedWorkoutKey)
        
        // Encode workout
        var workoutDict: [String: Any] = [
            "id": workout.id,
            "userId1": userId1,
            "userName1": userName1,
            "userId2": userId2,
            "userName2": userName2,
            "dateTimestamp": workout.date.timeIntervalSince1970,
            "duration": workout.duration
        ]
        
        // Encode exercises
        var exercisesArray: [[String: Any]] = []
        for exercise in workout.exercises {
            var exerciseDict: [String: Any] = [
                "id": exercise.id,
                "name": exercise.name
            ]
            
            if let equipment = exercise.equipment {
                exerciseDict["equipment"] = equipment.rawValue
            }
            if let category = exercise.category {
                exerciseDict["category"] = category.rawValue
            }
            if let addedByUserId = exercise.addedByUserId {
                exerciseDict["addedByUserId"] = addedByUserId
            }
            
            var setsArray: [[String: Any]] = []
            for set in exercise.sets {
                var setDict: [String: Any] = [
                    "id": set.id,
                    "reps": set.reps,
                    "weight": set.weight,
                    "restTime": set.restTime ?? 0
                ]
                if let addedByUserId = set.addedByUserId {
                    setDict["addedByUserId"] = addedByUserId
                }
                setsArray.append(setDict)
            }
            exerciseDict["sets"] = setsArray
            exercisesArray.append(exerciseDict)
        }
        workoutDict["exercises"] = exercisesArray
        
        // Save to BOTH users - ensure both saves succeed
        print("💾 Saving shared workout to user1 (\(userName1))...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user1SharedRef.setValue(workoutDict) { error, _ in
                if let error = error {
                    print("❌ Failed to save shared workout to user1: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Shared workout saved to user1")
                    continuation.resume()
                }
            }
        }
        
        print("💾 Saving shared workout to user2 (\(userName2))...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user2SharedRef.setValue(workoutDict) { error, _ in
                if let error = error {
                    print("❌ Failed to save shared workout to user2: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Shared workout saved to user2")
                    continuation.resume()
                }
            }
        }
        
        print("✅ Shared workout saved successfully to BOTH users")
    }
    
    /// Fetch user's shared workouts
    func fetchSharedWorkouts(userId: String) async throws -> [Workout] {
        let sharedWorkoutsRef = database.child("users").child(userId).child("sharedWorkouts")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Workout], Error>) in
            sharedWorkoutsRef.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var workouts: [Workout] = []
                for (_, workoutData) in value {
                    // Decode shared workout format
                    guard let id = workoutData["id"] as? String,
                          let userId1 = workoutData["userId1"] as? String,
                          let userName1 = workoutData["userName1"] as? String,
                          let userId2 = workoutData["userId2"] as? String,
                          let userName2 = workoutData["userName2"] as? String,
                          let dateTimestamp = workoutData["dateTimestamp"] as? TimeInterval else {
                        continue
                    }
                    
                    let date = Date(timeIntervalSince1970: dateTimestamp)
                    let duration = workoutData["duration"] as? TimeInterval ?? 0
                    
                    // Determine partner info
                    let partnerId = userId == userId1 ? userId2 : userId1
                    let partnerName = userId == userId1 ? userName2 : userName1
                    
                    // Decode exercises
                    var exercises: [Exercise] = []
                    if let exercisesArray = workoutData["exercises"] as? [[String: Any]] {
                        for exerciseDict in exercisesArray {
                            guard let exerciseId = exerciseDict["id"] as? String,
                                  let name = exerciseDict["name"] as? String else { continue }
                            
                            var equipment: Equipment? = nil
                            if let equipmentString = exerciseDict["equipment"] as? String {
                                equipment = Equipment(rawValue: equipmentString)
                            }
                            
                            var category: ExerciseCategory? = nil
                            if let categoryString = exerciseDict["category"] as? String {
                                category = ExerciseCategory(rawValue: categoryString)
                            }
                            
                            let addedByUserId = exerciseDict["addedByUserId"] as? String
                            
                            var sets: [Set] = []
                            if let setsArray = exerciseDict["sets"] as? [[String: Any]] {
                                for setDict in setsArray {
                                    guard let setId = setDict["id"] as? String,
                                          let reps = setDict["reps"] as? Int,
                                          let weight = setDict["weight"] as? Double else { continue }
                                    
                                    let restTime = setDict["restTime"] as? TimeInterval
                                    let setAddedBy = setDict["addedByUserId"] as? String
                                    sets.append(Set(id: setId, reps: reps, weight: weight, restTime: restTime, addedByUserId: setAddedBy))
                                }
                            }
                            
                            exercises.append(Exercise(id: exerciseId, name: name, sets: sets, equipment: equipment, category: category, addedByUserId: addedByUserId))
                        }
                    }
                    
                    let workout = Workout(
                        id: id,
                        userId: userId,
                        userName: userId == userId1 ? userName1 : userName2,
                        exercises: exercises,
                        date: date,
                        duration: duration,
                        partnerId: partnerId,
                        partnerName: partnerName
                    )
                    
                    workouts.append(workout)
                }
                
                // Sort by date descending
                workouts.sort { $0.date > $1.date }
                continuation.resume(returning: workouts)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func decodeUser(from dict: [String: Any], userId: String) throws -> User {
        guard let email = dict["email"] as? String,
              let username = dict["username"] as? String else {
            throw NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        
        let profileImageURL = dict["profileImageURL"] as? String
        let bio = dict["bio"] as? String
        let workoutCount = dict["workoutCount"] as? Int ?? 0
        let totalWorkoutTime = dict["totalWorkoutTime"] as? TimeInterval ?? 0
        
        let createdAt: Date
        if let timestamp = dict["createdAtTimestamp"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }
        
        return User(
            id: userId,
            email: email,
            username: username,
            profileImageURL: profileImageURL,
            createdAt: createdAt,
            bio: bio,
            workoutCount: workoutCount,
            totalWorkoutTime: totalWorkoutTime
        )
    }
    
    private func decodeWorkout(from dict: [String: Any]) throws -> Workout {
        guard let id = dict["id"] as? String,
              let userId = dict["userId"] as? String,
              let userName = dict["userName"] as? String,
              let dateTimestamp = dict["dateTimestamp"] as? TimeInterval else {
            throw NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid workout data"])
        }
        
        let date = Date(timeIntervalSince1970: dateTimestamp)
        let duration = dict["duration"] as? TimeInterval ?? 0
        let partnerId = dict["partnerId"] as? String
        let partnerName = dict["partnerName"] as? String
        
        var exercises: [Exercise] = []
        if let exercisesArray = dict["exercises"] as? [[String: Any]] {
            for exerciseDict in exercisesArray {
                guard let exerciseId = exerciseDict["id"] as? String,
                      let name = exerciseDict["name"] as? String else { continue }
                
                // Decode optional equipment and category
                var equipment: Equipment? = nil
                if let equipmentString = exerciseDict["equipment"] as? String {
                    equipment = Equipment(rawValue: equipmentString)
                }
                
                var category: ExerciseCategory? = nil
                if let categoryString = exerciseDict["category"] as? String {
                    category = ExerciseCategory(rawValue: categoryString)
                }
                
                var sets: [Set] = []
                if let setsArray = exerciseDict["sets"] as? [[String: Any]] {
                    for setDict in setsArray {
                        guard let setId = setDict["id"] as? String,
                              let reps = setDict["reps"] as? Int,
                              let weight = setDict["weight"] as? Double else { continue }
                        
                        let restTime = setDict["restTime"] as? TimeInterval
                        sets.append(Set(id: setId, reps: reps, weight: weight, restTime: restTime))
                    }
                }
                
                // Decode referenceSets if they exist (for templates)
                var referenceSets: [Set]? = nil
                if let referenceSetsArray = exerciseDict["referenceSets"] as? [[String: Any]] {
                    var refSets: [Set] = []
                    for setDict in referenceSetsArray {
                        guard let setId = setDict["id"] as? String,
                              let reps = setDict["reps"] as? Int,
                              let weight = setDict["weight"] as? Double else { continue }
                        
                        let restTime = setDict["restTime"] as? TimeInterval
                        refSets.append(Set(id: setId, reps: reps, weight: weight, restTime: restTime))
                    }
                    referenceSets = refSets.isEmpty ? nil : refSets
                }
                
                exercises.append(Exercise(id: exerciseId, name: name, sets: sets, equipment: equipment, category: category, referenceSets: referenceSets))
            }
        }
        
        return Workout(
            id: id,
            userId: userId,
            userName: userName,
            exercises: exercises,
            date: date,
            duration: duration,
            partnerId: partnerId,
            partnerName: partnerName
        )
    }
    
    private func updateUserStats(userId: String, workoutDuration: TimeInterval) async throws {
        let userRef = database.child("users").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userRef.runTransactionBlock { currentData in
                var userData = currentData.value as? [String: Any] ?? [:]
                let currentCount = userData["workoutCount"] as? Int ?? 0
                let currentTime = userData["totalWorkoutTime"] as? TimeInterval ?? 0
                
                userData["workoutCount"] = currentCount + 1
                userData["totalWorkoutTime"] = currentTime + workoutDuration
                
                currentData.value = userData
                return TransactionResult.success(withValue: currentData)
            } andCompletionBlock: { error, committed, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Posts
    
    func createPost(_ post: Post) async throws {
        let postRef = database.child("posts").child(post.id)
        
        var postDict: [String: Any] = [
            "id": post.id,
            "userId": post.userId,
            "userName": post.userName,
            "timestamp": post.timestamp.timeIntervalSince1970,
            "likes": post.likes
        ]
        
        if let profileImageURL = post.userProfileImageURL {
            postDict["userProfileImageURL"] = profileImageURL
        }
        
        if let content = post.content {
            postDict["content"] = content
        }
        
        if let progressPicURL = post.progressPicURL {
            postDict["progressPicURL"] = progressPicURL
        }
        
        if let workout = post.workout {
            // Encode workout
            var workoutDict: [String: Any] = [
                "id": workout.id,
                "userId": workout.userId,
                "userName": workout.userName,
                "dateTimestamp": workout.date.timeIntervalSince1970,
                "duration": workout.duration
            ]
            
            if let partnerId = workout.partnerId {
                workoutDict["partnerId"] = partnerId
            }
            if let partnerName = workout.partnerName {
                workoutDict["partnerName"] = partnerName
            }
            
            var exercisesArray: [[String: Any]] = []
            for exercise in workout.exercises {
                var exerciseDict: [String: Any] = [
                    "id": exercise.id,
                    "name": exercise.name
                ]
                
                if let equipment = exercise.equipment {
                    exerciseDict["equipment"] = equipment.rawValue
                }
                if let category = exercise.category {
                    exerciseDict["category"] = category.rawValue
                }
                
                var setsArray: [[String: Any]] = []
                for set in exercise.sets {
                    setsArray.append([
                        "id": set.id,
                        "reps": set.reps,
                        "weight": set.weight,
                        "restTime": set.restTime ?? 0
                    ])
                }
                exerciseDict["sets"] = setsArray
                
                // Save referenceSets if they exist (for templates)
                if let referenceSets = exercise.referenceSets {
                    var referenceSetsArray: [[String: Any]] = []
                    for set in referenceSets {
                        referenceSetsArray.append([
                            "id": set.id,
                            "reps": set.reps,
                            "weight": set.weight,
                            "restTime": set.restTime ?? 0
                        ])
                    }
                    exerciseDict["referenceSets"] = referenceSetsArray
                }
                
                exercisesArray.append(exerciseDict)
            }
            workoutDict["exercises"] = exercisesArray
            postDict["workout"] = workoutDict
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            postRef.setValue(postDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func fetchPosts(limit: Int = 50) async throws -> [Post] {
        let postsRef = database.child("posts")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Post], Error>) in
            postsRef.observeSingleEvent(of: .value) { snapshot, error in
                // Handle error first
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                // Handle case where posts node doesn't exist or is empty
                guard snapshot.exists(), let value = snapshot.value else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Handle different data structures
                var posts: [Post] = []
                
                if let postsDict = value as? [String: [String: Any]] {
                    // Posts stored as dictionary
                    for (_, postData) in postsDict {
                        if let post = try? self.decodePost(from: postData) {
                            posts.append(post)
                        }
                    }
                } else if let postsArray = value as? [[String: Any]] {
                    // Posts stored as array (unlikely but handle it)
                    for postData in postsArray {
                        if let post = try? self.decodePost(from: postData) {
                            posts.append(post)
                        }
                    }
                }
                
                // Sort by timestamp descending
                posts.sort { $0.timestamp > $1.timestamp }
                
                // Limit results
                if posts.count > limit {
                    posts = Array(posts.prefix(limit))
                }
                
                continuation.resume(returning: posts)
            }
        }
    }
    
    func likePost(postId: String, userId: String) async throws {
        let postRef = database.child("posts").child(postId).child("likes")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            postRef.runTransactionBlock { currentData in
                var likes = currentData.value as? [String] ?? []
                if !likes.contains(userId) {
                    likes.append(userId)
                }
                currentData.value = likes
                return TransactionResult.success(withValue: currentData)
            } andCompletionBlock: { error, committed, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func unlikePost(postId: String, userId: String) async throws {
        let postRef = database.child("posts").child(postId).child("likes")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            postRef.runTransactionBlock { currentData in
                var likes = currentData.value as? [String] ?? []
                likes.removeAll { $0 == userId }
                currentData.value = likes
                return TransactionResult.success(withValue: currentData)
            } andCompletionBlock: { error, committed, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func decodePost(from dict: [String: Any]) throws -> Post {
        guard let id = dict["id"] as? String,
              let userId = dict["userId"] as? String,
              let userName = dict["userName"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            throw NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid post data"])
        }
        
        let date = Date(timeIntervalSince1970: timestamp)
        let userProfileImageURL = dict["userProfileImageURL"] as? String
        let content = dict["content"] as? String
        let progressPicURL = dict["progressPicURL"] as? String
        let likes = dict["likes"] as? [String] ?? []
        
        var workout: Workout? = nil
        if let workoutDict = dict["workout"] as? [String: Any] {
            workout = try? decodeWorkout(from: workoutDict)
        }
        
        return Post(
            id: id,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            content: content,
            workout: workout,
            progressPicURL: progressPicURL,
            timestamp: date,
            likes: likes
        )
    }
    
    // MARK: - Templates
    
    func saveTemplate(userId: String, template: Workout, templateName: String) async throws {
        let templateRef = database.child("users").child(userId).child("templates").child(template.id)
        
        var templateDict: [String: Any] = [
            "id": template.id,
            "name": templateName,
            "userId": template.userId,
            "userName": template.userName,
            "dateTimestamp": template.date.timeIntervalSince1970,
            "duration": template.duration
        ]
        
        if let partnerId = template.partnerId {
            templateDict["partnerId"] = partnerId
        }
        if let partnerName = template.partnerName {
            templateDict["partnerName"] = partnerName
        }
        
        // Encode exercises
        var exercisesArray: [[String: Any]] = []
        for exercise in template.exercises {
            var exerciseDict: [String: Any] = [
                "id": exercise.id,
                "name": exercise.name
            ]
            
            if let equipment = exercise.equipment {
                exerciseDict["equipment"] = equipment.rawValue
            }
            if let category = exercise.category {
                exerciseDict["category"] = category.rawValue
            }
            
            // For templates, save referenceSets but clear sets (user will add their own)
            exerciseDict["sets"] = []
            
            // Save referenceSets if they exist
            if let referenceSets = exercise.referenceSets {
                var referenceSetsArray: [[String: Any]] = []
                for set in referenceSets {
                    referenceSetsArray.append([
                        "id": set.id,
                        "reps": set.reps,
                        "weight": set.weight,
                        "restTime": set.restTime ?? 0
                    ])
                }
                exerciseDict["referenceSets"] = referenceSetsArray
            }
            
            exercisesArray.append(exerciseDict)
        }
        templateDict["exercises"] = exercisesArray
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            templateRef.setValue(templateDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func fetchTemplates(userId: String) async throws -> [(id: String, name: String, workout: Workout)] {
        let templatesRef = database.child("users").child(userId).child("templates")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[(id: String, name: String, workout: Workout)], Error>) in
            templatesRef.observeSingleEvent(of: .value) { snapshot, error in
                // Handle error
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var templates: [(id: String, name: String, workout: Workout)] = []
                for (templateId, templateData) in value {
                    if let name = templateData["name"] as? String,
                       let workout = try? self.decodeWorkout(from: templateData) {
                        templates.append((id: templateId, name: name, workout: workout))
                    }
                }
                continuation.resume(returning: templates)
            }
        }
    }
    
    func deleteTemplate(userId: String, templateId: String) async throws {
        let templateRef = database.child("users").child(userId).child("templates").child(templateId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            templateRef.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Friends & Social
    
    /// Send a friend request
    func sendFriendRequest(from userId: String, to friendId: String) async throws {
        let requestRef = database.child("friendRequests").child(friendId).child(userId)
        let requestData: [String: Any] = [
            "fromUserId": userId,
            "toUserId": friendId,
            "status": "pending",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            requestRef.setValue(requestData) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Accept a friend request
    func acceptFriendRequest(from userId: String, to currentUserId: String) async throws {
        // Remove the request
        let requestRef = database.child("friendRequests").child(currentUserId).child(userId)
        
        // Add to both users' friends lists
        let currentUserFriendsRef = database.child("users").child(currentUserId).child("friends").child(userId)
        let friendUserFriendsRef = database.child("users").child(userId).child("friends").child(currentUserId)
        
        let friendData: [String: Any] = [
            "userId": userId,
            "addedAt": Date().timeIntervalSince1970
        ]
        
        let currentUserData: [String: Any] = [
            "userId": currentUserId,
            "addedAt": Date().timeIntervalSince1970
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            requestRef.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                currentUserFriendsRef.setValue(friendData) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    friendUserFriendsRef.setValue(currentUserData) { error, _ in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
    
    /// Reject or cancel a friend request
    func rejectFriendRequest(from userId: String, to currentUserId: String) async throws {
        let requestRef = database.child("friendRequests").child(currentUserId).child(userId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            requestRef.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Remove a friend
    func removeFriend(userId: String, friendId: String) async throws {
        let userFriendsRef = database.child("users").child(userId).child("friends").child(friendId)
        let friendFriendsRef = database.child("users").child(friendId).child("friends").child(userId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userFriendsRef.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                friendFriendsRef.removeValue { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Get friend requests sent to a user
    func getFriendRequests(userId: String) async throws -> [FriendRequest] {
        let requestsRef = database.child("friendRequests").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[FriendRequest], Error>) in
            requestsRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var requests: [FriendRequest] = []
                for (_, requestData) in value {
                    if let fromUserId = requestData["fromUserId"] as? String,
                       let toUserId = requestData["toUserId"] as? String,
                       let status = requestData["status"] as? String,
                       let timestamp = requestData["timestamp"] as? TimeInterval {
                        requests.append(FriendRequest(
                            fromUserId: fromUserId,
                            toUserId: toUserId,
                            status: status,
                            timestamp: Date(timeIntervalSince1970: timestamp)
                        ))
                    }
                }
                continuation.resume(returning: requests)
            }
        }
    }
    
    /// Get user's friends list
    func getFriends(userId: String) async throws -> [String] {
        let friendsRef = database.child("users").child(userId).child("friends")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            friendsRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let friendIds = Array(value.keys)
                continuation.resume(returning: friendIds)
            }
        }
    }
    
    /// Check if username is available
    func isUsernameAvailable(_ username: String, excludingUserId: String? = nil) async throws -> Bool {
        let usersRef = database.child("users")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            usersRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: true) // No users exist, username is available
                    return
                }
                
                let lowercasedUsername = username.lowercased()
                
                for (userId, userData) in value {
                    // Skip the user we're checking for (if updating username)
                    if let excludingUserId = excludingUserId, userId == excludingUserId {
                        continue
                    }
                    
                    if let existingUsername = userData["username"] as? String,
                       existingUsername.lowercased() == lowercasedUsername {
                        continuation.resume(returning: false) // Username taken
                        return
                    }
                }
                
                continuation.resume(returning: true) // Username available
            }
        }
    }
    
    /// Search users by username (exact match or contains)
    func searchUsers(query: String, currentUserId: String) async throws -> [User] {
        let usersRef = database.child("users")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[User], Error>) in
            usersRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var users: [User] = []
                let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
                
                // Only search if query is not empty
                guard !lowercasedQuery.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }
                
                for (userId, userData) in value {
                    // Skip current user
                    if userId == currentUserId {
                        continue
                    }
                    
                    // Only search by username
                    if let username = userData["username"] as? String,
                       username.lowercased().contains(lowercasedQuery) {
                        if let user = try? self.decodeUser(from: userData, userId: userId) {
                            users.append(user)
                        }
                    }
                }
                
                continuation.resume(returning: users)
            }
        }
    }
    
    /// Fetch user by username
    func fetchUserByUsername(_ username: String) async throws -> User? {
        let usersRef = database.child("users")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User?, Error>) in
            usersRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let lowercasedUsername = username.lowercased()
                
                for (userId, userData) in value {
                    if let existingUsername = userData["username"] as? String,
                       existingUsername.lowercased() == lowercasedUsername {
                        if let user = try? self.decodeUser(from: userData, userId: userId) {
                            continuation.resume(returning: user)
                            return
                        }
                    }
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Fetch public workouts for a user (workouts that were posted to feed)
    func fetchPublicWorkouts(userId: String) async throws -> [Workout] {
        let postsRef = database.child("posts")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Workout], Error>) in
            postsRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var workouts: [Workout] = []
                
                for (_, postData) in value {
                    // Only include posts from this user
                    if let postUserId = postData["userId"] as? String,
                       postUserId == userId,
                       let workoutData = postData["workout"] as? [String: Any] {
                        if let workout = try? self.decodeWorkout(from: workoutData) {
                            workouts.append(workout)
                        }
                    }
                }
                
                // Sort by date (newest first)
                workouts.sort { $0.date > $1.date }
                
                continuation.resume(returning: workouts)
            }
        }
    }
    
    /// Set user online status
    func setUserOnline(userId: String) {
        let userStatusRef = database.child("userStatus").child(userId)
        let statusData: [String: Any] = [
            "status": "online",
            "lastSeen": Date().timeIntervalSince1970
        ]
        userStatusRef.setValue(statusData)
        
        // Set up disconnect handler to mark as offline
        userStatusRef.onDisconnectSetValue([
            "status": "offline",
            "lastSeen": Date().timeIntervalSince1970
        ])
    }
    
    /// Get user online status
    func getUserStatus(userId: String) async throws -> UserStatus? {
        let statusRef = database.child("userStatus").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UserStatus?, Error>) in
            statusRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: Any],
                      let status = value["status"] as? String,
                      let lastSeen = value["lastSeen"] as? TimeInterval else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: UserStatus(
                    userId: userId,
                    status: status == "online",
                    lastSeen: Date(timeIntervalSince1970: lastSeen)
                ))
            }
        }
    }
    
    /// Listen to user status changes
    func listenToUserStatus(userId: String, completion: @escaping (UserStatus?) -> Void) -> DatabaseHandle {
        let statusRef = database.child("userStatus").child(userId)
        
        return statusRef.observe(.value) { snapshot in
            guard snapshot.exists(), let value = snapshot.value as? [String: Any],
                  let status = value["status"] as? String,
                  let lastSeen = value["lastSeen"] as? TimeInterval else {
                completion(nil)
                return
            }
            
            completion(UserStatus(
                userId: userId,
                status: status == "online",
                lastSeen: Date(timeIntervalSince1970: lastSeen)
            ))
        }
    }
    
    // MARK: - Live Workouts
    
    /// Send a live workout invite
    func sendLiveWorkoutInvite(from userId: String, fromUserName: String, to friendId: String) async throws -> String {
        let inviteId = UUID().uuidString
        let inviteRef = database.child("liveWorkoutInvites").child(friendId).child(inviteId)
        let now = Date().timeIntervalSince1970
        let expirationTime = now + 60 // 60 seconds from now
        
        let inviteData: [String: Any] = [
            "inviteId": inviteId,
            "fromUserId": userId,
            "fromUserName": fromUserName,
            "toUserId": friendId,
            "status": "pending",
            "timestamp": now,
            "expirationTimestamp": expirationTime
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            inviteRef.setValue(inviteData) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Auto-delete after 60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            inviteRef.removeValue()
        }
        
        return inviteId
    }
    
    /// Create a live workout session
    func createLiveWorkoutSession(sessionId: String, userId1: String, userName1: String, userId2: String, userName2: String) async throws {
        let sessionRef = database.child("liveWorkouts").child(sessionId)
        let sessionData: [String: Any] = [
            "sessionId": sessionId,
            "userId1": userId1,
            "userName1": userName1,
            "userId2": userId2,
            "userName2": userName2,
            "status": "active",
            "createdAt": Date().timeIntervalSince1970,
            "exercises": []
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionRef.setValue(sessionData) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Reject a live workout invite
    func rejectLiveWorkoutInvite(inviteId: String, toUserId: String) async throws {
        let inviteRef = database.child("liveWorkoutInvites").child(toUserId).child(inviteId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            inviteRef.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Accept a live workout invite
    func acceptLiveWorkoutInvite(inviteId: String, toUserId: String, toUserName: String) async throws -> String? {
        let inviteRef = database.child("liveWorkoutInvites").child(toUserId).child(inviteId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            inviteRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let inviteData = snapshot.value as? [String: Any],
                      let fromUserId = inviteData["fromUserId"] as? String,
                      let fromUserName = inviteData["fromUserName"] as? String else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Remove invite
                inviteRef.removeValue { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Create live workout session
                    let sessionId = UUID().uuidString
                    Task {
                        do {
                            // Get userName2 from database
                            let toUser = try? await self.fetchUser(userId: toUserId)
                            let finalUserName2 = toUser?.username ?? toUserName
                            
                            try await self.createLiveWorkoutSession(
                                sessionId: sessionId,
                                userId1: fromUserId,
                                userName1: fromUserName,
                                userId2: toUserId,
                                userName2: finalUserName2
                            )
                            
                            // Notify the inviter by creating a session reference for them
                            // They can listen for this session
                            continuation.resume(returning: sessionId)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    /// Listen to live workout invites
    func listenToLiveWorkoutInvites(userId: String, completion: @escaping (LiveWorkoutInvite?) -> Void) -> DatabaseHandle {
        let invitesRef = database.child("liveWorkoutInvites").child(userId)
        
        return invitesRef.observe(.childAdded) { snapshot in
            guard let inviteData = snapshot.value as? [String: Any],
                  let inviteId = inviteData["inviteId"] as? String,
                  let fromUserId = inviteData["fromUserId"] as? String,
                  let fromUserName = inviteData["fromUserName"] as? String,
                  let toUserId = inviteData["toUserId"] as? String,
                  let status = inviteData["status"] as? String,
                  let timestamp = inviteData["timestamp"] as? TimeInterval else {
                completion(nil)
                return
            }
            
            // Check if invite is still valid (within 60 seconds)
            let expirationTimestamp = inviteData["expirationTimestamp"] as? TimeInterval ?? (timestamp + 60)
            let now = Date().timeIntervalSince1970
            
            if now <= expirationTimestamp {
                completion(LiveWorkoutInvite(
                    inviteId: inviteId,
                    fromUserId: fromUserId,
                    fromUserName: fromUserName,
                    toUserId: toUserId,
                    status: status,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                ))
            } else {
                // Invite expired, remove it
                snapshot.ref.removeValue()
                completion(nil)
            }
        }
    }
    
    /// Fetch pending live workout invites (for viewing in workout page)
    func fetchPendingLiveWorkoutInvites(userId: String) async throws -> [LiveWorkoutInvite] {
        let invitesRef = database.child("liveWorkoutInvites").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[LiveWorkoutInvite], Error>) in
            invitesRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var invites: [LiveWorkoutInvite] = []
                let now = Date().timeIntervalSince1970
                
                for (_, inviteData) in value {
                    guard let inviteId = inviteData["inviteId"] as? String,
                          let fromUserId = inviteData["fromUserId"] as? String,
                          let fromUserName = inviteData["fromUserName"] as? String,
                          let toUserId = inviteData["toUserId"] as? String,
                          let status = inviteData["status"] as? String,
                          let timestamp = inviteData["timestamp"] as? TimeInterval else {
                        continue
                    }
                    
                    // Check if invite is still valid (within 60 seconds)
                    let expirationTimestamp = inviteData["expirationTimestamp"] as? TimeInterval ?? (timestamp + 60)
                    
                    if now <= expirationTimestamp && status == "pending" {
                        invites.append(LiveWorkoutInvite(
                            inviteId: inviteId,
                            fromUserId: fromUserId,
                            fromUserName: fromUserName,
                            toUserId: toUserId,
                            status: status,
                            timestamp: Date(timeIntervalSince1970: timestamp)
                        ))
                    }
                }
                
                // Sort by timestamp descending (newest first)
                invites.sort { $0.timestamp > $1.timestamp }
                continuation.resume(returning: invites)
            }
        }
    }
    
    /// Fetch pending sessions (for inviter to rejoin)
    func fetchPendingSessions(userId: String) async throws -> [PendingSession] {
        let notificationsRef = database.child("liveWorkoutNotifications").child(userId)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[PendingSession], Error>) in
            notificationsRef.observeSingleEvent(of: .value) { snapshot, error in
                if let error = error {
                    let dbError: Error
                    if let nsError = error as? NSError {
                        dbError = nsError
                    } else {
                        dbError = NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                    }
                    continuation.resume(throwing: dbError)
                    return
                }
                
                guard snapshot.exists(), let value = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let now = Date().timeIntervalSince1970
                let sessionIds = value.compactMap { (sessionId, sessionData) -> String? in
                    guard let timestamp = sessionData["timestamp"] as? TimeInterval else { return nil }
                    let notificationAge = now - timestamp
                    // Check if notification is still valid (within 5 minutes) and session is active
                    return notificationAge <= 300 ? sessionId : nil
                }
                
                guard !sessionIds.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Fetch all session details
                var sessions: [PendingSession] = []
                let group = DispatchGroup()
                
                for sessionId in sessionIds {
                    group.enter()
                    let sessionRef = self.database.child("liveWorkouts").child(sessionId)
                    sessionRef.observeSingleEvent(of: .value) { sessionSnapshot, _ in
                        defer { group.leave() }
                        
                        guard let sessionValue = sessionSnapshot.value as? [String: Any],
                              let userId1 = sessionValue["userId1"] as? String,
                              let userName1 = sessionValue["userName1"] as? String,
                              let userId2 = sessionValue["userId2"] as? String,
                              let userName2 = sessionValue["userName2"] as? String,
                              let status = sessionValue["status"] as? String,
                              status == "active" else {
                            return
                        }
                        
                        // Determine partner name
                        let partnerName = userId == userId1 ? userName2 : userName1
                        let timestamp = value[sessionId]?["timestamp"] as? TimeInterval ?? now
                        
                        sessions.append(PendingSession(
                            id: sessionId,
                            sessionId: sessionId,
                            userId: userId,
                            partnerName: partnerName,
                            timestamp: Date(timeIntervalSince1970: timestamp)
                        ))
                    }
                }
                
                group.notify(queue: .main) {
                    // Sort by timestamp descending
                    sessions.sort { $0.timestamp > $1.timestamp }
                    continuation.resume(returning: sessions)
                }
            }
        }
    }
    
    /// Listen to live workout session changes
    func listenToLiveWorkout(sessionId: String, completion: @escaping (LiveWorkoutSession?) -> Void) -> DatabaseHandle {
        let sessionRef = database.child("liveWorkouts").child(sessionId)
        
        return sessionRef.observe(.value) { snapshot in
            guard snapshot.exists(), let sessionData = snapshot.value as? [String: Any],
                  let sessionId = sessionData["sessionId"] as? String,
                  let userId1 = sessionData["userId1"] as? String,
                  let userName1 = sessionData["userName1"] as? String,
                  let userId2 = sessionData["userId2"] as? String,
                  let userName2 = sessionData["userName2"] as? String,
                  let status = sessionData["status"] as? String else {
                completion(nil)
                return
            }
            
            var exercises: [Exercise] = []
            if let exercisesDict = sessionData["exercises"] as? [String: [String: Any]] {
                // Exercises stored as dictionary (current format)
                for (_, exerciseDict) in exercisesDict {
                    if let exercise = try? self.decodeExercise(from: exerciseDict) {
                        exercises.append(exercise)
                    }
                }
            } else if let exercisesArray = sessionData["exercises"] as? [[String: Any]] {
                // Exercises stored as array (fallback for old format)
                for exerciseDict in exercisesArray {
                    if let exercise = try? self.decodeExercise(from: exerciseDict) {
                        exercises.append(exercise)
                    }
                }
            }
            
            completion(LiveWorkoutSession(
                sessionId: sessionId,
                userId1: userId1,
                userName1: userName1,
                userId2: userId2,
                userName2: userName2,
                status: status,
                exercises: exercises
            ))
        }
    }
    
    /// Add exercise to live workout
    func addExerciseToLiveWorkout(sessionId: String, exercise: Exercise, addedByUserId: String) async throws {
        let sessionRef = database.child("liveWorkouts").child(sessionId).child("exercises")
        let exerciseRef = sessionRef.child(exercise.id)
        
        var exerciseDict: [String: Any] = [
            "id": exercise.id,
            "name": exercise.name,
            "addedByUserId": addedByUserId
        ]
        
        if let equipment = exercise.equipment {
            exerciseDict["equipment"] = equipment.rawValue
        }
        if let category = exercise.category {
            exerciseDict["category"] = category.rawValue
        }
        
        var setsArray: [[String: Any]] = []
        for set in exercise.sets {
            var setDict: [String: Any] = [
                "id": set.id,
                "reps": set.reps,
                "weight": set.weight,
                "restTime": set.restTime ?? 0
            ]
            if let addedBy = set.addedByUserId {
                setDict["addedByUserId"] = addedBy
            }
            setsArray.append(setDict)
        }
        exerciseDict["sets"] = setsArray
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exerciseRef.setValue(exerciseDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Add set to exercise in live workout
    func addSetToLiveWorkoutExercise(sessionId: String, exerciseId: String, set: Set, addedByUserId: String) async throws {
        let setRef = database.child("liveWorkouts").child(sessionId).child("exercises").child(exerciseId).child("sets").child(set.id)
        
        var setDict: [String: Any] = [
            "id": set.id,
            "reps": set.reps,
            "weight": set.weight,
            "restTime": set.restTime ?? 0,
            "addedByUserId": addedByUserId
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setRef.setValue(setDict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// End live workout session
    func endLiveWorkoutSession(sessionId: String) async throws {
        let sessionRef = database.child("liveWorkouts").child(sessionId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionRef.updateChildValues(["status": "ended"]) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func decodeExercise(from dict: [String: Any]) throws -> Exercise {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else {
            throw NSError(domain: "RealtimeDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid exercise data"])
        }
        
        var equipment: Equipment? = nil
        if let equipmentString = dict["equipment"] as? String {
            equipment = Equipment(rawValue: equipmentString)
        }
        
        var category: ExerciseCategory? = nil
        if let categoryString = dict["category"] as? String {
            category = ExerciseCategory(rawValue: categoryString)
        }
        
        let addedByUserId = dict["addedByUserId"] as? String
        
        var sets: [Set] = []
        // Firebase stores sets as a dictionary (object), not an array
        if let setsDict = dict["sets"] as? [String: [String: Any]] {
            // Sets stored as dictionary: { setId: { id, reps, weight, ... } }
            for (_, setDict) in setsDict {
                guard let setId = setDict["id"] as? String,
                      let reps = setDict["reps"] as? Int,
                      let weight = setDict["weight"] as? Double else { continue }
                
                let restTime = setDict["restTime"] as? TimeInterval
                let setAddedBy = setDict["addedByUserId"] as? String
                sets.append(Set(id: setId, reps: reps, weight: weight, restTime: restTime, addedByUserId: setAddedBy))
            }
        } else if let setsArray = dict["sets"] as? [[String: Any]] {
            // Fallback: Sets stored as array (old format)
            for setDict in setsArray {
                guard let setId = setDict["id"] as? String,
                      let reps = setDict["reps"] as? Int,
                      let weight = setDict["weight"] as? Double else { continue }
                
                let restTime = setDict["restTime"] as? TimeInterval
                let setAddedBy = setDict["addedByUserId"] as? String
                sets.append(Set(id: setId, reps: reps, weight: weight, restTime: restTime, addedByUserId: setAddedBy))
            }
        }
        
        return Exercise(id: id, name: name, sets: sets, equipment: equipment, category: category, addedByUserId: addedByUserId)
    }
    
    // MARK: - Messaging
    
    /// Send a message
    func sendMessage(_ message: Message) async throws {
        let messageRef = database.child("messages").child(message.id)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            messageRef.setValue(message.toDictionary()) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Also store in conversation threads for both users
        let conversationId1 = "\(message.senderId)_\(message.receiverId)"
        let conversationId2 = "\(message.receiverId)_\(message.senderId)"
        
        let conversationRef1 = database.child("conversations").child(conversationId1).child("lastMessage")
        let conversationRef2 = database.child("conversations").child(conversationId2).child("lastMessage")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conversationRef1.setValue(message.toDictionary()) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conversationRef2.setValue(message.toDictionary()) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Fetch messages between two users
    func fetchMessages(userId1: String, userId2: String) async throws -> [Message] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Message], Error>) in
            database.child("messages").observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var allMessages: [Message] = []
                
                for (_, messageDict) in dict {
                    if let senderId = messageDict["senderId"] as? String,
                       let receiverId = messageDict["receiverId"] as? String,
                       ((senderId == userId1 && receiverId == userId2) || (senderId == userId2 && receiverId == userId1)),
                       let message = Message(from: messageDict) {
                        allMessages.append(message)
                    }
                }
                
                // Sort by timestamp
                allMessages.sort { $0.timestamp < $1.timestamp }
                continuation.resume(returning: allMessages)
            }
        }
    }
    
    /// Listen for new messages in real-time
    func listenForMessages(userId1: String, userId2: String, completion: @escaping ([Message]) -> Void) -> DatabaseHandle {
        // Listen to all messages and filter - this fires whenever ANY message changes
        let handle = database.child("messages").observe(.value) { snapshot in
            // Handle both dictionary format and null
            guard snapshot.exists() else {
                completion([])
                return
            }
            
            guard let dict = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }
            
            var allMessages: [Message] = []
            for (messageId, messageDict) in dict {
                // Ensure we have all required fields
                guard let senderId = messageDict["senderId"] as? String,
                      let receiverId = messageDict["receiverId"] as? String else {
                    continue
                }
                
                // Check if this message is between our two users
                let isRelevant = (senderId == userId1 && receiverId == userId2) || 
                                (senderId == userId2 && receiverId == userId1)
                
                if isRelevant {
                    // Try to create message from dictionary
                    var messageDictWithId = messageDict
                    // Ensure the message has an ID
                    if messageDictWithId["id"] == nil {
                        messageDictWithId["id"] = messageId
                    }
                    
                    if let message = Message(from: messageDictWithId) {
                        allMessages.append(message)
                    }
                }
            }
            
            // Sort by timestamp
            allMessages.sort { $0.timestamp < $1.timestamp }
            completion(allMessages)
        }
        
        return handle
    }
    
    /// Fetch all conversations for a user
    func fetchConversations(userId: String) async throws -> [Conversation] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Conversation], Error>) in
            database.child("conversations").observeSingleEvent(of: .value) { snapshot, _ in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var conversations: [Conversation] = []
                let group = DispatchGroup()
                
                for (conversationId, conversationData) in dict {
                    // Check if this conversation involves the user
                    if conversationId.contains(userId) {
                        group.enter()
                        
                        // Extract other user ID - handle both "userId_otherId" and "otherId_userId" formats
                        let parts = conversationId.split(separator: "_")
                        let otherUserId: String
                        if parts.count == 2 {
                            // Get the part that is NOT the current userId
                            if String(parts[0]) == userId {
                                otherUserId = String(parts[1])
                            } else if String(parts[1]) == userId {
                                otherUserId = String(parts[0])
                            } else {
                                // Neither part matches, skip this conversation
                                group.leave()
                                continue
                            }
                        } else {
                            // Invalid format, skip
                            group.leave()
                            continue
                        }
                        
                        // Skip if otherUserId is empty or same as userId
                        guard !otherUserId.isEmpty && otherUserId != userId else {
                            group.leave()
                            continue
                        }
                        
                        // Fetch other user data and count unread messages
                        Task {
                            do {
                                // First, count unread messages for this conversation using async/await
                                var unreadCount = 0
                                let messagesData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                                    self.database.child("messages").observeSingleEvent(of: .value) { snapshot in
                                        continuation.resume(returning: snapshot)
                                    }
                                }
                                
                                if let messagesDict = messagesData.value as? [String: [String: Any]] {
                                    for (_, msgDict) in messagesDict {
                                        if let msgSenderId = msgDict["senderId"] as? String,
                                           let msgReceiverId = msgDict["receiverId"] as? String,
                                           msgSenderId == String(otherUserId) && msgReceiverId == userId,
                                           let isRead = msgDict["isRead"] as? Bool,
                                           !isRead {
                                            unreadCount += 1
                                        }
                                    }
                                }
                                
                                // Fetch other user data
                                if let otherUser = try await self.fetchUser(userId: String(otherUserId)) {
                                    var lastMessage: Message?
                                    
                                    if let lastMessageDict = conversationData["lastMessage"] as? [String: Any],
                                       let message = Message(from: lastMessageDict) {
                                        lastMessage = message
                                    }
                                    
                                    let conversation = Conversation(
                                        id: String(otherUserId),
                                        otherUser: otherUser,
                                        lastMessage: lastMessage,
                                        unreadCount: unreadCount
                                    )
                                    
                                    await MainActor.run {
                                        conversations.append(conversation)
                                        group.leave()
                                    }
                                } else {
                                    group.leave()
                                }
                            } catch {
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    // Remove duplicate conversations (same otherUserId)
                    var uniqueConversations: [Conversation] = []
                    var seenUserIds: Swift.Set<String> = []
                    
                    for conversation in conversations {
                        if !seenUserIds.contains(conversation.id) {
                            seenUserIds.insert(conversation.id)
                            uniqueConversations.append(conversation)
                        }
                    }
                    
                    // Sort by last message timestamp
                    uniqueConversations.sort { ($0.lastMessage?.timestamp ?? Date.distantPast) > ($1.lastMessage?.timestamp ?? Date.distantPast) }
                    continuation.resume(returning: uniqueConversations)
                }
            }
        }
    }
    
    /// Mark messages as read
    func markMessagesAsRead(userId: String, otherUserId: String) async throws {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.child("messages").observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume()
                    return
                }
                
                let group = DispatchGroup()
                var hasUpdates = false
                
                for (messageId, messageDict) in dict {
                    if let senderId = messageDict["senderId"] as? String,
                       let receiverId = messageDict["receiverId"] as? String,
                       senderId == otherUserId && receiverId == userId,
                       let isRead = messageDict["isRead"] as? Bool,
                       !isRead {
                        group.enter()
                        hasUpdates = true
                        
                        self.database.child("messages").child(messageId).updateChildValues(["isRead": true]) { error, _ in
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    continuation.resume()
                }
            }
        }
    }
}

