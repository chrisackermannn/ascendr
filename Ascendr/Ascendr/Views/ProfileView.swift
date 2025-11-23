//
//  ProfileView.swift
//  Ascendr
//
//  Profile view with progress history and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedWorkout: Workout?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 20) {
                        // Profile Image with online indicator
                        ZStack(alignment: .bottomTrailing) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(.systemGray6))
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    
                                    // Border
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3)
                                        .frame(width: 120, height: 120)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            // Online indicator (always shown for own profile)
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 3)
                                )
                            
                            // Edit button overlay
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .semibold))
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: 40, y: 40)
                        }
                        
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUser?.username ?? "User")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let bio = authViewModel.currentUser?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding()
                    
                    // Stats - Enhanced
                    HStack(spacing: 20) {
                        StatCardView(
                            value: "\(profileViewModel.workouts.count)",
                            label: "Workouts",
                            icon: "figure.strengthtraining.traditional",
                            color: .primary
                        )
                        
                        StatCardView(
                            value: "\(profileViewModel.progressPics.count)",
                            label: "Progress Pics",
                            icon: "photo.on.rectangle",
                            color: .primary
                        )
                    }
                    .padding(.horizontal)
                    
                    // Progress Pics Section
                    if !profileViewModel.progressPics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Pics")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(profileViewModel.progressPics) { post in
                                        if let picURL = post.progressPicURL {
                                            AsyncImage(url: URL(string: picURL)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                            }
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Workout History
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if profileViewModel.workouts.isEmpty {
                            Text("No workouts yet. Start your first workout!")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(profileViewModel.workouts.prefix(5)) { workout in
                                Button(action: {
                                    selectedWorkout = workout
                                }) {
                                    WorkoutHistoryCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Sign Out Button
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ascendr")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .allowsHitTesting(false)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue, let userId = authViewModel.currentUser?.id {
                    Task {
                        await profileViewModel.updateProfileImage(image, userId: userId)
                        // Refresh current user data in auth view model
                        let databaseService = RealtimeDatabaseService()
                        if let updatedUser = try? await databaseService.fetchUser(userId: userId) {
                            await MainActor.run {
                                authViewModel.currentUser = updatedUser
                            }
                        }
                        // Clear selected image after processing
                        selectedImage = nil
                    }
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await profileViewModel.fetchUserData(userId: userId)
                    }
                }
            }
        }
    }
}

struct WorkoutHistoryCard: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.primary)
                    .font(.title3)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(workout.date, style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let partnerName = workout.partnerName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text(partnerName)
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if workout.duration > 0 {
                        Label(formatDuration(workout.duration), systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Image Picker with camera support
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Use edited image if available, otherwise use original
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

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.date, style: .date)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if workout.duration > 0 {
                            Text("Duration: \(formatDuration(workout.duration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let partnerName = workout.partnerName {
                            Label("Partner: \(partnerName)", systemImage: "person.2.fill")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(workout.exercises) { exercise in
                            ExerciseDetailCard(exercise: exercise)
                        }
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StatCardView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ExerciseDetailCard: View {
    let exercise: Exercise
    
    private var isBodyweightOrCardio: Bool {
        guard let equipment = exercise.equipment else { return false }
        return equipment == .bodyweight || exercise.category == .cardio
    }
    
    private var isCardio: Bool {
        exercise.category == .cardio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                if let equipment = exercise.equipment {
                    Text(equipment.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
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
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

