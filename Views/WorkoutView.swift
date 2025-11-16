//
//  WorkoutView.swift
//  Ascendr
//
//  Workout view with partner functionality
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingPartnerInput = false
    @State private var partnerId = ""
    @State private var partnerName = ""
    @State private var showingExerciseInput = false
    @State private var exerciseName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if workoutViewModel.currentWorkout == nil {
                    // Start workout screen
                    VStack(spacing: 24) {
                        Text("Ready to train?")
                            .font(.title)
                            .padding()
                        
                        Button(action: {
                            startWorkout()
                        }) {
                            Text("Start Workout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            showingPartnerInput = true
                        }) {
                            Text("Start Partner Workout")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Active workout screen
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Workout info
                            HStack {
                                if workoutViewModel.isPartnerMode {
                                    Label("Partner: \(workoutViewModel.partnerName ?? "")", systemImage: "person.2.fill")
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if let startTime = workoutViewModel.workoutStartTime {
                                    Text("Duration: \(formatDuration(Date().timeIntervalSince(startTime)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            
                            // Exercises
                            ForEach(workoutViewModel.exercises) { exercise in
                                ExerciseCardView(exercise: exercise, workoutViewModel: workoutViewModel)
                            }
                            
                            // Add exercise button
                            Button(action: {
                                showingExerciseInput = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            // Finish workout button
                            Button(action: {
                                Task {
                                    await workoutViewModel.finishWorkout()
                                }
                            }) {
                                Text("Finish Workout")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding()
                            .disabled(workoutViewModel.isLoading)
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .sheet(isPresented: $showingPartnerInput) {
                PartnerInputView(partnerId: $partnerId, partnerName: $partnerName) {
                    startPartnerWorkout()
                }
            }
            .sheet(isPresented: $showingExerciseInput) {
                ExerciseInputView(exerciseName: $exerciseName) {
                    addExercise()
                }
            }
        }
    }
    
    private func startWorkout() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.username else { return }
        workoutViewModel.startWorkout(userId: userId, userName: userName)
    }
    
    private func startPartnerWorkout() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.username else { return }
        workoutViewModel.startWorkout(
            userId: userId,
            userName: userName,
            partnerId: partnerId.isEmpty ? nil : partnerId,
            partnerName: partnerName.isEmpty ? nil : partnerName
        )
        
        // Listen to partner updates if partner ID provided
        if !partnerId.isEmpty, let workout = workoutViewModel.currentWorkout {
            workoutViewModel.listenToPartnerWorkout(workoutId: workout.id)
        }
        
        showingPartnerInput = false
    }
    
    private func addExercise() {
        let exercise = Exercise(name: exerciseName)
        workoutViewModel.addExercise(exercise)
        exerciseName = ""
        showingExerciseInput = false
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
    @State private var reps = ""
    @State private var weight = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.headline)
            
            ForEach(exercise.sets) { set in
                HStack {
                    Text("Set \(exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0 + 1)")
                    Spacer()
                    Text("\(set.reps) reps")
                    Text("@ \(set.weight, specifier: "%.1f") lbs")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("Reps", text: $reps)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                TextField("Weight (lbs)", text: $weight)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                
                Button(action: {
                    if let repsInt = Int(reps), let weightDouble = Double(weight) {
                        let newSet = Set(reps: repsInt, weight: weightDouble)
                        workoutViewModel.addSet(to: exercise.id, set: newSet)
                        reps = ""
                        weight = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
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

struct ExerciseInputView: View {
    @Binding var exerciseName: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Exercise Name", text: $exerciseName)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
}

