//
//  LiveWorkoutView.swift
//  Ascendr
//
//  Live workout view with split screen - matches single person workout functionality
//

import SwiftUI

struct LiveWorkoutView: View {
    @EnvironmentObject var liveWorkoutViewModel: LiveWorkoutViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingExercisePicker = false
    
    private var currentUserId: String? {
        liveWorkoutViewModel.currentUserId
    }
    
    private var user1Id: String? {
        liveWorkoutViewModel.session?.userId1
    }
    
    private var user2Id: String? {
        liveWorkoutViewModel.session?.userId2
    }
    
    // Determine if current user is user1
    private var isCurrentUser1: Bool {
        guard let currentUserId = currentUserId,
              let user1Id = user1Id else { return false }
        return currentUserId == user1Id
    }
    
    // Exercises added by user1 (left side)
    private var user1Exercises: [Exercise] {
        guard let user1Id = user1Id else { return [] }
        return liveWorkoutViewModel.exercises.filter { $0.addedByUserId == user1Id }
    }
    
    // Exercises added by user2 (right side)
    private var user2Exercises: [Exercise] {
        guard let user2Id = user2Id else { return [] }
        return liveWorkoutViewModel.exercises.filter { $0.addedByUserId == user2Id }
    }
    
    // Current user's exercises (their side)
    private var currentUserExercises: [Exercise] {
        isCurrentUser1 ? user1Exercises : user2Exercises
    }
    
    // Partner's exercises (other side)
    private var partnerExercises: [Exercise] {
        isCurrentUser1 ? user2Exercises : user1Exercises
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with partner info
                HStack(spacing: 16) {
                    // Current user info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(authViewModel.currentUser?.username ?? "You")
                            .font(.headline)
                            .foregroundColor(isCurrentUser1 ? .blue : .green)
                    }
                    
                    Spacer()
                    
                    // Connection indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Live")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    // Partner info
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Partner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(liveWorkoutViewModel.partnerName ?? "Partner")
                            .font(.headline)
                            .foregroundColor(isCurrentUser1 ? .green : .blue)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Split screen workout view
                HStack(spacing: 0) {
                    // Left side - Current user's exercises
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Your Exercises")
                                .font(.headline)
                                .foregroundColor(isCurrentUser1 ? .blue : .green)
                            Spacer()
                            // Only show + button if current user can add to this side
                            if isCurrentUser1 {
                                Button(action: {
                                    showingExercisePicker = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                        }
                        .padding()
                        .background(isCurrentUser1 ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if currentUserExercises.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.system(size: 40))
                                            .foregroundColor((isCurrentUser1 ? Color.blue : Color.green).opacity(0.3))
                                        Text("No exercises yet")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Tap + to add an exercise")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(currentUserExercises) { exercise in
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
                                    
                                    // Add exercise button
                                    Button(action: {
                                        showingExercisePicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Exercise")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background((isCurrentUser1 ? Color.blue : Color.green).opacity(0.1))
                                        .foregroundColor(isCurrentUser1 ? .blue : .green)
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                    
                    // Right side - Partner's exercises
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Partner's Exercises")
                                .font(.headline)
                                .foregroundColor(isCurrentUser1 ? .green : .blue)
                            Spacer()
                            // Only show + button if current user can add to this side
                            if !isCurrentUser1 {
                                Button(action: {
                                    showingExercisePicker = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                        }
                        .padding()
                        .background(isCurrentUser1 ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if partnerExercises.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.system(size: 40))
                                            .foregroundColor((isCurrentUser1 ? Color.green : Color.blue).opacity(0.3))
                                        Text("No exercises yet")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Waiting for partner...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(partnerExercises) { exercise in
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
                                    
                                    // Add exercise button (only if current user is user2)
                                    if !isCurrentUser1 {
                                        Button(action: {
                                            showingExercisePicker = true
                                        }) {
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                Text("Add Exercise")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background((isCurrentUser1 ? Color.green : Color.blue).opacity(0.1))
                                            .foregroundColor(isCurrentUser1 ? .green : .blue)
                                            .cornerRadius(10)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6).opacity(0.5))
                }
                
                // End workout button
                Button(action: {
                    Task {
                        await liveWorkoutViewModel.endWorkout()
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("End Workout")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Live Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        Task {
                            await liveWorkoutViewModel.endWorkout()
                            dismiss()
                        }
                    }
                }
            }
            .onDisappear {
                liveWorkoutViewModel.cleanup()
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exerciseItem in
                    let exercise = Exercise(
                        name: exerciseItem.name,
                        sets: [],
                        equipment: exerciseItem.equipment,
                        category: exerciseItem.category,
                        addedByUserId: currentUserId // Set ownership to current user
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

struct LiveExerciseCardView: View {
    let exercise: Exercise
    let currentUserId: String
    let onAddSet: (Set) -> Void
    @State private var reps = ""
    @State private var weight = ""
    @State private var timeMinutes = ""
    @State private var timeSeconds = ""
    @State private var distance = ""
    
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
                
                if exercise.sets.isEmpty {
                    Label("No sets", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
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
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Completed sets
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
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
                .padding(.vertical, 4)
            }
            
            // Add set form
            Divider()
            
            if isCardio {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Min", text: $timeMinutes)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Text(":")
                        TextField("Sec", text: $timeSeconds)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                    }
                    
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Distance", text: $distance)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            } else if isBodyweightOrCardio {
                TextField("Reps", text: $reps)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                HStack {
                    TextField("Reps", text: $reps)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    TextField("Weight (lbs)", text: $weight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
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
                .padding(.vertical, 10)
                .background(canAddSet ? Color.blue : Color.gray)
                .cornerRadius(8)
            }
            .disabled(!canAddSet)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func addSet() {
        if isCardio {
            if !timeMinutes.isEmpty, let minutes = Int(timeMinutes) {
                let newSet = Set(reps: 0, weight: Double(minutes), addedByUserId: currentUserId)
                onAddSet(newSet)
                timeMinutes = ""
                timeSeconds = ""
            } else if !timeSeconds.isEmpty, let seconds = Int(timeSeconds) {
                let newSet = Set(reps: seconds, weight: 0, addedByUserId: currentUserId)
                onAddSet(newSet)
                timeMinutes = ""
                timeSeconds = ""
            } else if !distance.isEmpty, let dist = Double(distance) {
                let newSet = Set(reps: 0, weight: dist, addedByUserId: currentUserId)
                onAddSet(newSet)
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
