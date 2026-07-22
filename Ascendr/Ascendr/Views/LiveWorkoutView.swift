//
//  LiveWorkoutView.swift
//  Ascendr
//
//  Enhanced live workout view with tab-based interface matching solo workout style
//

import SwiftUI

struct LiveWorkoutView: View {
    @EnvironmentObject var liveWorkoutViewModel: LiveWorkoutViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var showingExercisePicker = false
    @State private var selectedTab: WorkoutTab = .you
    
    enum WorkoutTab {
        case you
        case partner
    }
    
    private var currentUserId: String? {
        liveWorkoutViewModel.currentUserId
    }
    
    private var user1Id: String? {
        liveWorkoutViewModel.session?.userId1
    }
    
    private var user2Id: String? {
        liveWorkoutViewModel.session?.userId2
    }
    
    private var isCurrentUser1: Bool {
        guard let currentUserId = currentUserId,
              let user1Id = user1Id else { return false }
        return currentUserId == user1Id
    }
    
    // Exercises for current user
    private var currentUserExercises: [Exercise] {
        guard let currentUserId = currentUserId else { return [] }
        return liveWorkoutViewModel.exercises.filter { $0.addedByUserId == currentUserId }
    }
    
    // Exercises for partner
    private var partnerExercises: [Exercise] {
        guard currentUserId != nil,
              let user1Id = user1Id,
              let user2Id = user2Id else { return [] }
        let partnerId = isCurrentUser1 ? user2Id : user1Id
        return liveWorkoutViewModel.exercises.filter { $0.addedByUserId == partnerId }
    }
    
    // Exercises for currently selected tab
    private var displayedExercises: [Exercise] {
        selectedTab == .you ? currentUserExercises : partnerExercises
    }
    
    // Combined weight pushed (sum of weight × reps from all exercises for both users)
    private var combinedWeightPushed: Double {
        liveWorkoutViewModel.exercises.reduce(0) { total, exercise in
            let exerciseTotal = exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
            return total + exerciseTotal
        }
    }
    
    // Current tab's weight pushed
    private var currentTabWeightPushed: Double {
        let exercises = selectedTab == .you ? currentUserExercises : partnerExercises
        return exercises.reduce(0) { total, exercise in
            let exerciseTotal = exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
            return total + exerciseTotal
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Compact stats bar
                    WorkoutStatsView(startTime: liveWorkoutViewModel.workoutStartTime)
                        .id(liveWorkoutViewModel.workoutStartTime?.timeIntervalSince1970 ?? 0)
                    
                    // Partner info with tabs - Compact
                    VStack(spacing: 8) {
                        // Tab selector
                        HStack(spacing: 0) {
                            TabButton(
                                title: "You",
                                isSelected: selectedTab == .you,
                                action: { selectedTab = .you }
                            )
                            
                            TabButton(
                                title: liveWorkoutViewModel.partnerName ?? "Partner",
                                isSelected: selectedTab == .partner,
                                action: { selectedTab = .partner }
                            )
                        }
                        .padding(.horizontal, 12)
                        
                        // Live indicator and combined weight
                        HStack(spacing: 12) {
                            // Live indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.15))
                            )
                            
                            Spacer()
                            
                            // Combined weight
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Combined")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(Int(combinedWeightPushed)) lbs")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(appSettings.primaryText)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    // Exercises section - Compact
                    VStack(spacing: 8) {
                        HStack {
                            Text("Exercises")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(appSettings.primaryText)
                            Spacer()
                            Text("\(displayedExercises.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        
                        if displayedExercises.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("No exercises yet")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(displayedExercises) { exercise in
                                LiveExerciseCardView(
                                    exercise: exercise,
                                    currentUserId: currentUserId ?? "",
                                    onAddSet: { set in
                                        Task {
                                            await liveWorkoutViewModel.addSet(to: exercise.id, set: set)
                                        }
                                    }
                                )
                            }
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
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(appSettings.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(appSettings.accentColor.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.top, 4)
                    
                    // Error message - Compact
                    if let errorMessage = liveWorkoutViewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 12)
                    }
                    
                    // Finish workout button - Compact
                    Button(action: {
                        Task {
                            await liveWorkoutViewModel.endWorkout(currentUserName: authViewModel.currentUser?.username ?? "")
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if liveWorkoutViewModel.isLoading {
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
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(appSettings.buttonGradient)
                        .cornerRadius(12)
                        .shadow(color: appSettings.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        .shadow(color: appSettings.accentColor.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ascendr")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: appSettings.isDarkMode ? [appSettings.accentColor, appSettings.accentColorSecondary] : [appSettings.accentColor, appSettings.accentColorSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .allowsHitTesting(false)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingExercisePicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onDisappear {
                liveWorkoutViewModel.cleanup()
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exerciseItem in
                    // Determine which user ID to use based on selected tab
                    let targetUserId: String?
                    if selectedTab == .you {
                        targetUserId = currentUserId
                    } else {
                        // Partner's tab - use partner's ID
                        if let user1Id = user1Id, let user2Id = user2Id {
                            targetUserId = isCurrentUser1 ? user2Id : user1Id
                        } else {
                            targetUserId = currentUserId
                        }
                    }
                    
                    guard let userId = targetUserId else {
                        print("❌ Cannot add exercise: No user ID available")
                        showingExercisePicker = false
                        return
                    }
                    
                    let exercise = Exercise(
                        name: exerciseItem.name,
                        sets: [],
                        equipment: exerciseItem.equipment,
                        category: exerciseItem.category,
                        addedByUserId: userId
                    )
                    
                    Task {
                        await liveWorkoutViewModel.addExercise(exercise)
                    }
                    showingExercisePicker = false
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appSettings.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(appSettings.borderColor, lineWidth: 1)
                                )
                        } else {
                            Color.clear
                        }
                    }
                )
        }
    }
}

struct LiveExerciseCardView: View {
    let exercise: Exercise
    let currentUserId: String
    let onAddSet: (Set) -> Void
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
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
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
                    TextField("Reps", text: $reps)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                } else {
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if canAddSet {
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
                    .cornerRadius(8)
                }
                .disabled(!canAddSet)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appSettings.cardBackground)
                .shadow(color: Color.black.opacity(appSettings.isDarkMode ? 0.08 : 0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
    }
    
    private func addSet() {
        if isCardio {
            if !timeMinutes.isEmpty, let minutes = Int(timeMinutes) {
                let newSet = Set(reps: 0, weight: Double(minutes), addedByUserId: currentUserId)
                onAddSet(newSet)
                timeMinutes = ""
                timeSeconds = ""
                distance = ""
            } else if !timeSeconds.isEmpty, let seconds = Int(timeSeconds) {
                let newSet = Set(reps: seconds, weight: 0, addedByUserId: currentUserId)
                onAddSet(newSet)
                timeMinutes = ""
                timeSeconds = ""
                distance = ""
            } else if !distance.isEmpty, let dist = Double(distance) {
                let newSet = Set(reps: 0, weight: dist, addedByUserId: currentUserId)
                onAddSet(newSet)
                timeMinutes = ""
                timeSeconds = ""
                distance = ""
            }
        } else if isBodyweightOrCardio {
            if let repsInt = Int(reps) {
                let newSet = Set(reps: repsInt, weight: 0, addedByUserId: currentUserId)
                onAddSet(newSet)
                reps = ""
            }
        } else {
            if let repsInt = Int(reps), let weightDouble = Double(weight) {
                let newSet = Set(reps: repsInt, weight: weightDouble, addedByUserId: currentUserId)
                onAddSet(newSet)
                reps = ""
                weight = ""
            }
        }
    }
}
