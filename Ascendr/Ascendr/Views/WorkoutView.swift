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
            ZStack {
                // Home screen gradient background
                appSettings.homeGradient
                    .ignoresSafeArea()
                
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
                    // Active workout screen - Compact redesign
                    ScrollView {
                        VStack(spacing: 10) {
                            // Music Player with Liquid Glass
                            MusicPlayerView()
                                .padding(.horizontal, 12)
                            
                            // Compact stats bar
                            WorkoutStatsView(startTime: workoutViewModel.workoutStartTime)
                                .id(workoutViewModel.workoutStartTime?.timeIntervalSince1970 ?? 0)
                            
                            // Partner info - Compact
                            if workoutViewModel.isPartnerMode {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(appSettings.accentColor)
                                    Text(workoutViewModel.partnerName ?? "")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(appSettings.primaryText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(appSettings.cardBackground)
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.1 : 0.08), radius: 8, x: 0, y: 3)
                                )
                                .padding(.horizontal, 12)
                            }
                            
                            // Exercises section - Compact
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Exercises")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(appSettings.primaryText)
                                    Spacer()
                                    Text("\(workoutViewModel.exercises.count)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                
                                ForEach(workoutViewModel.exercises) { exercise in
                                    ExerciseCardView(exercise: exercise, workoutViewModel: workoutViewModel)
                                }
                                
                                // Add exercise button - Compact
                                Button(action: {
                                    showingExercisePicker = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Add Exercise")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(appSettings.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appSettings.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                            .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.1 : 0.08), radius: 10, x: 0, y: 4)
                                    )
                                }
                                .padding(.horizontal, 12)
                            }
                            .padding(.top, 4)
                            
                            // Error message - Compact
                            if let errorMessage = workoutViewModel.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(Color.red.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .padding(.horizontal, 12)
                            }
                            
                            // Finish workout button - Compact
                            VStack(spacing: 8) {
                                if !workoutViewModel.canFinishWorkout && !workoutViewModel.exercises.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                        Text("Add at least one set to each exercise")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .padding(.horizontal, 12)
                                }
                                
                                Button(action: {
                                    showingPostToFeed = true
                                }) {
                                    HStack(spacing: 8) {
                                        if workoutViewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Finish Workout")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(workoutViewModel.canFinishWorkout ? .white : appSettings.primaryText.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Group {
                                            if workoutViewModel.canFinishWorkout {
                                                appSettings.buttonGradient
                                            } else {
                                                appSettings.secondaryBackground
                                            }
                                        }
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: workoutViewModel.canFinishWorkout ? appSettings.accentColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                                    .shadow(color: workoutViewModel.canFinishWorkout ? appSettings.accentColor.opacity(0.2) : Color.clear, radius: 12, x: 0, y: 6)
                                }
                                .disabled(workoutViewModel.isLoading || !workoutViewModel.canFinishWorkout)
                            }
                            .padding(12)
                        }
                    }
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                hideKeyboard()
                            }
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ascendr")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(
                            appSettings.buttonGradient
                        )
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
                PendingLiveWorkoutRequestsView(invites: $pendingInvites)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                loadPendingInvites()
            }
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
    @State private var selectedSet: Set?
    @State private var showingEditSet = false
    @State private var editReps = ""
    @State private var editWeight = ""
    
    private var isBodyweightOrCardio: Bool {
        guard let equipment = exercise.equipment else { return false }
        return equipment == .bodyweight || exercise.category == .cardio
    }
    
    private var isCardio: Bool {
        exercise.category == .cardio
    }
    
    private var canAddSet: Bool {
        if isCardio {
            return (!timeMinutes.isEmpty && Int(timeMinutes) != nil) || 
                   (!timeSeconds.isEmpty && Int(timeSeconds) != nil) ||
                   (!distance.isEmpty && Double(distance) != nil)
        } else if isBodyweightOrCardio {
            return !reps.isEmpty && Int(reps) != nil
        } else {
            return !reps.isEmpty && Int(reps) != nil && !weight.isEmpty && Double(weight) != nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            exerciseHeader
            if !exercise.sets.isEmpty {
                completedSetsView
            }
            addSetForm
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.1 : 0.08), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .sheet(isPresented: $showingEditSet) {
            if let set = selectedSet {
                EditSetView(
                    exercise: exercise,
                    set: set,
                    initialReps: editReps,
                    initialWeight: editWeight,
                    workoutViewModel: workoutViewModel,
                    isCardio: isCardio,
                    isBodyweightOrCardio: isBodyweightOrCardio,
                    onDismiss: {
                        showingEditSet = false
                        selectedSet = nil
                    }
                )
            }
        }
    }
    
    private var exerciseHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appSettings.primaryText)
                    .lineLimit(1)
                
                if let equipment = exercise.equipment {
                    Text(equipment.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            infoButton
            
            if !exercise.sets.isEmpty {
                setCountBadge
            }
        }
    }
    
    @ViewBuilder
    private var infoButton: some View {
        if let exerciseItem = ExerciseLibrary.shared.exercises.first(where: { $0.name == exercise.name }),
           exerciseItem.instructions != nil {
            Button(action: {
                showingInstructions = true
            }) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(appSettings.accentColor.opacity(0.7))
            }
            .sheet(isPresented: $showingInstructions) {
                ExerciseInstructionsView(exercise: exerciseItem)
            }
        }
    }
    
    private var setCountBadge: some View {
        Text("\(exercise.sets.count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(appSettings.buttonGradient)
            )
    }
    
    private var completedSetsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    setChip(index: index, set: set)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private func setChip(index: Int, set: Set) -> some View {
        Button(action: {
            selectedSet = set
            editReps = "\(set.reps)"
            editWeight = String(format: "%.1f", set.weight)
            showingEditSet = true
        }) {
            HStack(spacing: 4) {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                
                Text(setDisplayText(for: set))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(appSettings.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(appSettings.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.1 : 0.08), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func setDisplayText(for set: Set) -> String {
        if isCardio {
            if set.weight > 0 {
                return "\(Int(set.weight))m"
            } else {
                return "\(set.reps)s"
            }
        } else if isBodyweightOrCardio {
            return "\(set.reps)"
        } else {
            return "\(set.reps) × \(Int(set.weight))"
        }
    }
    
    @ViewBuilder
    private var addSetForm: some View {
        HStack(spacing: 6) {
            if isCardio {
                cardioInputFields
            } else if isBodyweightOrCardio {
                bodyweightInputField
            } else {
                weightedInputFields
            }
            
            addSetButton
        }
    }
    
    private var cardioInputFields: some View {
        HStack(spacing: 4) {
            compactTextField("M", text: $timeMinutes, width: 35)
            Text(":")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            compactTextField("S", text: $timeSeconds, width: 35)
            Text("or")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            compactTextField("Dist", text: $distance, width: 50, keyboardType: .decimalPad)
        }
    }
    
    private var bodyweightInputField: some View {
        compactTextField("Reps", text: $reps, width: nil)
            .frame(maxWidth: .infinity)
    }
    
    private var weightedInputFields: some View {
        Group {
            compactTextField("Reps", text: $reps, width: 50)
            Text("×")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            compactTextField("Lbs", text: $weight, width: 60, keyboardType: .decimalPad)
        }
    }
    
    private func compactTextField(_ placeholder: String, text: Binding<String>, width: CGFloat?, keyboardType: UIKeyboardType = .numberPad) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .keyboardType(keyboardType)
            .font(.system(size: 12, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(.vertical, 6)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appSettings.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                LinearGradient(
                                    colors: [appSettings.accentColor.opacity(0.1), appSettings.accentColorSecondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
    
    private var addSetButton: some View {
        Button(action: addSet) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(canAddSet ? .white : appSettings.primaryText.opacity(0.3))
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if canAddSet {
                            Circle()
                                .fill(appSettings.buttonGradient)
                        } else {
                            Circle()
                                .fill(appSettings.secondaryBackground)
                        }
                    }
                )
        }
        .disabled(!canAddSet)
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
            // Main content area - tappable to select exercise
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
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Info button - separate, only shows info
            if exercise.instructions != nil {
                Button(action: {
                    showingInstructions = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(appSettings.accentColor)
                }
                .buttonStyle(.plain)
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

struct EditSetView: View {
    let exercise: Exercise
    let set: Set
    @State var initialReps: String
    @State var initialWeight: String
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let isCardio: Bool
    let isBodyweightOrCardio: Bool
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var reps: String
    @State private var weight: String
    
    init(exercise: Exercise, set: Set, initialReps: String, initialWeight: String, workoutViewModel: WorkoutViewModel, isCardio: Bool, isBodyweightOrCardio: Bool, onDismiss: @escaping () -> Void) {
        self.exercise = exercise
        self.set = set
        self.initialReps = initialReps
        self.initialWeight = initialWeight
        self.workoutViewModel = workoutViewModel
        self.isCardio = isCardio
        self.isBodyweightOrCardio = isBodyweightOrCardio
        self.onDismiss = onDismiss
        _reps = State(initialValue: initialReps)
        _weight = State(initialValue: initialWeight)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Set")) {
                    if isCardio {
                        if set.weight > 0 {
                            Text("Time: \(Int(set.weight)) minutes")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Time: \(set.reps) seconds")
                                .foregroundColor(.secondary)
                        }
                        Text("Cardio sets cannot be edited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if isBodyweightOrCardio {
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                        
                        TextField("Weight (lbs)", text: $weight)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        if isCardio {
            return false // Cardio sets can't be edited
        } else if isBodyweightOrCardio {
            return !reps.isEmpty && Int(reps) != nil
        } else {
            return !reps.isEmpty && Int(reps) != nil && !weight.isEmpty && Double(weight) != nil
        }
    }
    
    private func saveChanges() {
        if isBodyweightOrCardio {
            if let repsInt = Int(reps) {
                workoutViewModel.updateSet(exerciseId: exercise.id, setId: set.id, reps: repsInt, weight: 0)
            }
        } else if !isCardio {
            if let repsInt = Int(reps), let weightDouble = Double(weight) {
                workoutViewModel.updateSet(exerciseId: exercise.id, setId: set.id, reps: repsInt, weight: weightDouble)
            }
        }
        dismiss()
        onDismiss()
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
    @State private var showingImageSourcePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploading = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        successAnimationView
                        completionMessageView
                        shareToggleView
                        if shouldPost {
                            postCreationSection
                        }
                        doneButtonView
                    }
                }
            }
            .navigationTitle("Finish Workout")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Add Photo", isPresented: $showingImageSourcePicker, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Camera") {
                        imagePickerSourceType = .camera
                        showingImagePicker = true
                    }
                }
                Button("Photo Library") {
                    imagePickerSourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                WorkoutImagePicker(image: $selectedImage, sourceType: imagePickerSourceType)
            }
            .onChange(of: postContent) { newValue in
                if newValue.count > 500 {
                    postContent = String(newValue.prefix(500))
                }
            }
        }
    }
    
    // MARK: - View Components
    private var successAnimationView: some View {
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
    }
    
    private var completionMessageView: some View {
        VStack(spacing: 8) {
            Text("Workout Complete!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(appSettings.primaryText)
            
            Text("Great job finishing your workout!")
                .font(.subheadline)
                .foregroundColor(appSettings.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var shareToggleView: some View {
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
    }
    
    private var postCreationSection: some View {
        VStack(spacing: 16) {
            textInputView
            imagePickerView
        }
        .padding(.horizontal, 16)
    }
    
    private var textInputView: some View {
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
    }
    
    private var imagePickerView: some View {
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
                    showingImageSourcePicker = true
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
    
    private var doneButtonView: some View {
        Button(action: {
            let content = shouldPost ? (postContent.isEmpty ? nil : postContent) : nil
            let image = shouldPost ? selectedImage : nil
            onFinish(content, image)
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
            .background(buttonBackground)
            .cornerRadius(12)
            .shadow(color: appSettings.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(isUploading || (shouldPost && postContent.isEmpty && selectedImage == nil))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private var buttonBackground: some View {
        Group {
            if shouldPost && (postContent.isEmpty && selectedImage == nil) {
                appSettings.secondaryBackground
            } else {
                appSettings.buttonGradient
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

// MARK: - Image Picker for Workout View
struct WorkoutImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: WorkoutImagePicker
        
        init(_ parent: WorkoutImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

