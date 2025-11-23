//
//  WorkoutView.swift
//  Ascendr
//
//  Workout view with partner functionality
//

import SwiftUI
import FirebaseDatabase
import UIKit

struct WorkoutView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var showingFriendsSearch = false
    @State private var showingExercisePicker = false
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showingPostToFeed = false
    @State private var showingTemplatePicker = false
    @State private var showingPendingRequests = false
    @State private var pendingInvites: [LiveWorkoutInvite] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if workoutViewModel.currentWorkout == nil {
                    // Start workout screen
                    VStack(spacing: 16) {
                        Spacer()
                        
                        // Welcome
                        VStack(spacing: 12) {
                            Text("Ready to train?")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(appSettings.primaryText)
                        }
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                startWorkout()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Start New Workout")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    appSettings.buttonGradient
                                )
                                .cornerRadius(10)
                                .shadow(color: appSettings.accentColor.opacity(0.2), radius: 12, x: 0, y: 6)
                            }
                            .padding(.horizontal, 12)
                        
                            Button(action: {
                                showingTemplatePicker = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                    Text("Use Template")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(appSettings.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appSettings.secondaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(appSettings.accentColor.opacity(0.3), lineWidth: 1.5)
                                        )
                                        )
                            }
                            .padding(.horizontal, 12)
                            
                            Button(action: {
                                showingFriendsSearch = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                    Text("Start Live Workout")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(appSettings.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appSettings.secondaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 1, green: 0, blue: 0.43).opacity(0.5), lineWidth: 1.5)
                                        )
                                )
                            }
                            .padding(.horizontal, 12)
                            
                            // Pending Live Workout Requests button
                            Button(action: {
                                showingPendingRequests = true
                                loadPendingInvites()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                    Text("Pending Requests")
                                        .fontWeight(.medium)
                                    
                                    if !pendingInvites.isEmpty {
                                        Text("(\(pendingInvites.count))")
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundColor(appSettings.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appSettings.secondaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 1, green: 0.75, blue: 0.04).opacity(0.5), lineWidth: 1.5)
                                        )
                                )
                            }
                            .padding(.horizontal, 12)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Active workout screen
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Enhanced workout stats with timer and HealthKit
                            WorkoutStatsView(startTime: workoutViewModel.workoutStartTime)
                                .id(workoutViewModel.workoutStartTime?.timeIntervalSince1970 ?? 0)
                            
                            // Partner info if applicable
                            if workoutViewModel.isPartnerMode {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.primary)
                                    Text("Partner: \(workoutViewModel.partnerName ?? "")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .padding(.horizontal, 12)
                            }
                            
                            // Exercises section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Exercises")
                                    .font(.system(size: 16, weight: .semibold))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 12)
                                
                                ForEach(workoutViewModel.exercises) { exercise in
                                    ExerciseCardView(exercise: exercise, workoutViewModel: workoutViewModel)
                                }
                                
                                // Add exercise button
                                Button(action: {
                                    showingExercisePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Exercise")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appSettings.secondaryBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appSettings.accentColor.opacity(0.3), lineWidth: 1.5)
                                            )
                                    )
                                    .foregroundColor(appSettings.primaryText)
                                }
                                .padding(.horizontal, 12)
                            }
                            
                            // Error message
                            if let errorMessage = workoutViewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, 12)
                            }
                            
                            // Finish workout button
                            VStack(spacing: 12) {
                                if !workoutViewModel.canFinishWorkout && !workoutViewModel.exercises.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.secondary)
                                        Text("Add at least one set to each exercise")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 12)
                                }
                                
                                Button(action: {
                                    showingPostToFeed = true
                                }) {
                                    HStack(spacing: 12) {
                                        if workoutViewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Finish Workout")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(workoutViewModel.canFinishWorkout ? .white : appSettings.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                    .background(
                                        Group {
                                            if workoutViewModel.canFinishWorkout {
                                                LinearGradient(
                                                    colors: appSettings.isDarkMode ? [appSettings.accentColor, appSettings.accentColorSecondary] : [appSettings.accentColor, appSettings.accentColorSecondary],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            } else {
                                                appSettings.secondaryBackground
                                            }
                                        }
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: workoutViewModel.canFinishWorkout ? appSettings.accentColor.opacity(0.2) : Color.clear, radius: 12, x: 0, y: 6)
                                }
                                .disabled(workoutViewModel.isLoading || !workoutViewModel.canFinishWorkout)
                            }
                            .padding(12)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ascendr")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(appSettings.primaryText)
                        .allowsHitTesting(false)
                }
            }
            .sheet(isPresented: $showingFriendsSearch) {
                FriendsView()
                    .environmentObject(friendsViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exerciseItem in
                    addExerciseFromLibrary(exerciseItem)
                }
            }
            .sheet(isPresented: $showingPostToFeed) {
                if let workout = workoutViewModel.currentWorkout {
                    PostToFeedView(workout: workout) { content, image in
                        Task {
                            await workoutViewModel.finishWorkout(shouldPostToFeed: content != nil || image != nil, postContent: content, postImage: image)
                            await MainActor.run {
                                showingPostToFeed = false
                            }
                        }
                    }
                    .environmentObject(appSettings)
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { template in
                    if let userId = authViewModel.currentUser?.id,
                       let userName = authViewModel.currentUser?.username {
                        workoutViewModel.importTemplate(template, userId: userId, userName: userName)
                    }
                    showingTemplatePicker = false
                }
                .environmentObject(workoutViewModel)
                .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingPendingRequests) {
                PendingLiveWorkoutRequestsView(
                    invites: $pendingInvites,
                    onAccept: { invite in
                        if let userId = authViewModel.currentUser?.id,
                           let userName = authViewModel.currentUser?.username {
                            Task {
                                await acceptLiveWorkoutInvite(invite: invite, userId: userId, userName: userName)
                            }
                        }
                        showingPendingRequests = false
                    }
                )
                .environmentObject(friendsViewModel)
                .environmentObject(authViewModel)
            }
            .onAppear {
                loadPendingInvites()
            }
        }
    }
    
    private func loadPendingInvites() {
        Task {
            if let userId = authViewModel.currentUser?.id {
                let databaseService = RealtimeDatabaseService()
                if let invites = try? await databaseService.fetchPendingLiveWorkoutInvites(userId: userId) {
                    await MainActor.run {
                        pendingInvites = invites
                    }
                }
            }
        }
    }
    
    private func acceptLiveWorkoutInvite(invite: LiveWorkoutInvite, userId: String, userName: String) async {
        do {
            let databaseService = RealtimeDatabaseService()
            if let sessionId = try await databaseService.acceptLiveWorkoutInvite(
                inviteId: invite.inviteId,
                toUserId: userId,
                toUserName: userName
            ) {
                // Notify the inviter to join the session
                let notificationRef = Database.database().reference()
                    .child("liveWorkoutNotifications")
                    .child(invite.fromUserId)
                    .child(sessionId)
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    notificationRef.setValue([
                        "sessionId": sessionId,
                        "timestamp": Date().timeIntervalSince1970
                    ]) { error, _ in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                
                // Start the live workout
                await MainActor.run {
                    let liveWorkoutViewModel = LiveWorkoutViewModel()
                    liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: userId)
                    // This will be handled by the view that shows the live workout
                }
            }
        } catch {
            print("Error accepting invite: \(error)")
        }
    }
    
    private func startWorkout() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.username else {
            print("Error: Cannot start workout - user not authenticated")
            return
        }
        print("Starting workout for user: \(userName)")
        workoutViewModel.startWorkout(userId: userId, userName: userName)
        print("Workout started. Current workout: \(workoutViewModel.currentWorkout != nil)")
    }
    
    
    private func addExerciseFromLibrary(_ exerciseItem: ExerciseItem) {
        let exercise = Exercise(
            name: exerciseItem.name,
            sets: [],
            equipment: exerciseItem.equipment,
            category: exerciseItem.category
        )
        workoutViewModel.addExercise(exercise)
        showingExercisePicker = false
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ExerciseCardView: View {
    let exercise: Exercise
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var appSettings: AppSettings
    @State private var reps = ""
    @State private var weight = ""
    @State private var timeMinutes = ""
    @State private var timeSeconds = ""
    @State private var distance = ""
    @State private var showingInstructions = false
    
    private var isBodyweightOrCardio: Bool {
        guard let equipment = exercise.equipment else { return false }
        return equipment == .bodyweight || exercise.category == .cardio
    }
    
    private var isCardio: Bool {
        exercise.category == .cardio
    }
    
    private var canAddSet: Bool {
        if isCardio {
            // For cardio, need time or distance
            return (!timeMinutes.isEmpty && Int(timeMinutes) != nil) || 
                   (!timeSeconds.isEmpty && Int(timeSeconds) != nil) ||
                   (!distance.isEmpty && Double(distance) != nil)
        } else if isBodyweightOrCardio {
            // For bodyweight, just need reps
            return !reps.isEmpty && Int(reps) != nil
        } else {
            // For weighted exercises, need both reps and weight
            return !reps.isEmpty && Int(reps) != nil && !weight.isEmpty && Double(weight) != nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let equipment = exercise.equipment {
                        Text(equipment.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Info button - on far side of name box
                if let exerciseItem = ExerciseLibrary.shared.exercises.first(where: { $0.name == exercise.name }),
                   exerciseItem.instructions != nil {
                    Button(action: {
                        showingInstructions = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(appSettings.accentColor)
                    }
                    .sheet(isPresented: $showingInstructions) {
                        ExerciseInstructionsView(exercise: exerciseItem)
                    }
                }
                
                if exercise.sets.isEmpty {
                    Label("No sets", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Label("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            // Reference sets (from template) - show greyed out
            if let referenceSets = exercise.referenceSets, !referenceSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Reference (from template)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(Array(referenceSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if isCardio {
                                if set.weight > 0 {
                                    Text("\(Int(set.weight)) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(set.reps) reps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if isBodyweightOrCardio {
                                Text("\(set.reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(set.reps) × \(set.weight, specifier: "%.1f") lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5).opacity(0.6))
                        )
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            Divider()
            
            // Completed sets
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isCardio {
                                if set.weight > 0 {
                                    Text("\(Int(set.weight)) min")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(set.reps) reps")
                                        .foregroundColor(.secondary)
                                }
                            } else if isBodyweightOrCardio {
                                Text("\(set.reps) reps")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(set.reps) × \(set.weight, specifier: "%.1f") lbs")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Divider()
            
            // Add set form
            VStack(alignment: .leading, spacing: 12) {
                Text("Add Set")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if isCardio {
                    // Cardio: Time or Distance
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("Minutes", text: $timeMinutes)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            
                            Text(":")
                                .foregroundColor(.secondary)
                            
                            TextField("Seconds", text: $timeSeconds)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Distance (miles)", text: $distance)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                    }
                } else if isBodyweightOrCardio {
                    // Bodyweight: Just reps
                    TextField("Reps", text: $reps)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                } else {
                    // Weighted: Reps and weight
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", text: $reps)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight (lbs)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", text: $weight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(canAddSet ? .white : appSettings.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if canAddSet {
                                appSettings.buttonGradient
                            } else {
                                appSettings.secondaryBackground
                            }
                        }
                    )
                    .cornerRadius(8)
                }
                .disabled(!canAddSet)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [appSettings.accentColor.opacity(0.2), appSettings.accentColorSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.15 : 0.1), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
    }
    
    private func addSet() {
        if isCardio {
            // For cardio, store time in weight field (minutes) or reps (seconds)
            if !timeMinutes.isEmpty, let minutes = Int(timeMinutes) {
                let newSet = Set(reps: 0, weight: Double(minutes))
                workoutViewModel.addSet(to: exercise.id, set: newSet)
                timeMinutes = ""
                timeSeconds = ""
            } else if !timeSeconds.isEmpty, let seconds = Int(timeSeconds) {
                let newSet = Set(reps: seconds, weight: 0)
                workoutViewModel.addSet(to: exercise.id, set: newSet)
                timeMinutes = ""
                timeSeconds = ""
            } else if !distance.isEmpty, let dist = Double(distance) {
                // Store distance in weight field
                let newSet = Set(reps: 0, weight: dist)
                workoutViewModel.addSet(to: exercise.id, set: newSet)
                distance = ""
            }
        } else if isBodyweightOrCardio {
            // Bodyweight: just reps, weight = 0
            if let repsInt = Int(reps) {
                let newSet = Set(reps: repsInt, weight: 0)
                workoutViewModel.addSet(to: exercise.id, set: newSet)
                reps = ""
            }
        } else {
            // Weighted: reps and weight
            if let repsInt = Int(reps), let weightDouble = Double(weight) {
                let newSet = Set(reps: repsInt, weight: weightDouble)
                workoutViewModel.addSet(to: exercise.id, set: newSet)
                reps = ""
                weight = ""
            }
        }
    }
}

struct PartnerInputView: View {
    @Binding var partnerId: String
    @Binding var partnerName: String
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Partner Information") {
                    TextField("Partner ID", text: $partnerId)
                    TextField("Partner Name", text: $partnerName)
                }
            }
            .navigationTitle("Partner Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        onStart()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExercisePickerView: View {
    let onSelect: (ExerciseItem) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    
    private let exerciseLibrary = ExerciseLibrary.shared
    
    private var filteredExercises: [ExerciseItem] {
        var exercises = exerciseLibrary.exercises
        
        // Filter by category
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exerciseLibrary.searchExercises(query: searchText).filter { exercise in
                if let category = selectedCategory {
                    return exercise.category == category
                }
                return true
            }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                // Exercise list
                List(filteredExercises) { exercise in
                    ExerciseRowView(exercise: exercise) {
                        onSelect(exercise)
                        dismiss()
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : appSettings.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            appSettings.buttonGradient
                        } else {
                            appSettings.secondaryBackground
                        }
                    }
                )
                .cornerRadius(16)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ExerciseItem
    let onSelect: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingInstructions = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    // Exercise GIF/Image placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(width: 60, height: 60)
                        
                        if let gifURL = exercise.gifURL, !gifURL.isEmpty {
                            AsyncImage(url: URL(string: gifURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Label(exercise.category.rawValue, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label(exercise.equipment.rawValue, systemImage: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // Info button
            if exercise.instructions != nil {
                Button(action: {
                    showingInstructions = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(appSettings.accentColor)
                }
                .sheet(isPresented: $showingInstructions) {
                    ExerciseInstructionsView(exercise: exercise)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct PostToFeedView: View {
    let workout: Workout
    let onFinish: (String?, UIImage?) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @State private var shouldPost = false
    @State private var postContent = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Success animation
                        ZStack {
                            Circle()
                                .fill(appSettings.buttonGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: appSettings.accentColor.opacity(0.2), radius: 15, x: 0, y: 8)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 45))
                                .foregroundColor(appSettings.isDarkMode ? .white : appSettings.primaryText)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Workout Complete!")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(appSettings.primaryText)
                            
                            Text("Great job finishing your workout!")
                                .font(.subheadline)
                                .foregroundColor(appSettings.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Share toggle
                        VStack(spacing: 12) {
                            Toggle(isOn: $shouldPost) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .foregroundColor(appSettings.primaryText)
                                    Text("Share to Feed")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(appSettings.primaryText)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: appSettings.accentColor))
                        }
                        .padding(16)
                        .background(appSettings.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        
                        // Post creation section (only shown if sharing)
                        if shouldPost {
                            VStack(spacing: 16) {
                                // Text input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What's on your mind?")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(appSettings.primaryText)
                                    
                                    TextEditor(text: $postContent)
                                        .font(.system(size: 15))
                                        .foregroundColor(appSettings.primaryText)
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(appSettings.secondaryBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(appSettings.borderColor, lineWidth: 1)
                                        )
                                        .focused($isTextFieldFocused)
                                    
                                    Text("\(postContent.count)/500")
                                        .font(.caption)
                                        .foregroundColor(appSettings.secondaryText)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(16)
                                .background(appSettings.cardBackground)
                                .cornerRadius(12)
                                
                                // Image picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Add a photo")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(appSettings.primaryText)
                                    
                                    if let selectedImage = selectedImage {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: selectedImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 200)
                                                .clipped()
                                                .cornerRadius(12)
                                            
                                            Button(action: {
                                                self.selectedImage = nil
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                            }
                                            .padding(8)
                                        }
                                    } else {
                                        Button(action: {
                                            showingImagePicker = true
                                        }) {
                                            VStack(spacing: 12) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(appSettings.accentColor)
                                                Text("Tap to add photo")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(appSettings.secondaryText)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .background(appSettings.secondaryBackground)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appSettings.borderColor, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(16)
                                .background(appSettings.cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Done button
                        Button(action: {
                            onFinish(shouldPost ? postContent.isEmpty ? nil : postContent : nil, shouldPost ? selectedImage : nil)
                        }) {
                            HStack(spacing: 12) {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(shouldPost ? "Share Workout" : "Done")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                Group {
                                    if shouldPost && (postContent.isEmpty && selectedImage == nil) {
                                        appSettings.secondaryBackground
                                    } else {
                                        appSettings.buttonGradient
                                    }
                                }
                            )
                            .cornerRadius(12)
                            .shadow(color: appSettings.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isUploading || (shouldPost && postContent.isEmpty && selectedImage == nil))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Finish Workout")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: postContent) { newValue in
                if newValue.count > 500 {
                    postContent = String(newValue.prefix(500))
                }
            }
        }
    }
}

struct TemplatePickerView: View {
    let onSelect: (Workout) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            List {
                if workoutViewModel.templates.isEmpty {
                    Text("No templates saved yet. Copy a workout from the feed to create one!")
                        .foregroundColor(.secondary)
                        .padding(12)
                } else {
                    ForEach(workoutViewModel.templates, id: \.id) { template in
                        Button(action: {
                            onSelect(template.workout)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(template.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("\(template.workout.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await workoutViewModel.fetchTemplates(userId: userId)
                    }
                }
            }
        }
    }
}

