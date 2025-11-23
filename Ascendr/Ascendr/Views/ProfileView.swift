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
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedWorkout: Workout?
    @State private var showingSettings = false
    @State private var selectedTab: ProfileTab = .recent
    
    enum ProfileTab {
        case recent
        case shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header
                    VStack(spacing: 14) {
                        // Profile Image with online indicator
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ZStack {
                                        Circle()
                                            .fill(appSettings.cardBackground)
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.secondary)
                                    }
                                }
                                    .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                
                                // Border
                                Circle()
                                    .stroke(
                                        appSettings.buttonGradient,
                                        lineWidth: 3
                                    )
                                    .frame(width: 90, height: 90)
                            }
                            
                            // Online indicator (always shown for own profile)
                            Circle()
                                .fill(appSettings.accentColor)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(appSettings.primaryBackground, lineWidth: 2.5)
                                )
                                .shadow(color: appSettings.accentColor.opacity(0.3), radius: 8, x: 0, y: 0)
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
                    .padding(12)
                    
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
                    .padding(.horizontal, 12)
                    
                    // Progress Pics Section
                    if !profileViewModel.progressPics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Pics")
                                .font(.headline)
                                .padding(.horizontal, 12)
                            
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
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    
                    // Workout History with Tabs
                    VStack(alignment: .leading, spacing: 12) {
                        // Tab selector
                        HStack(spacing: 0) {
                            ProfileTabButton(
                                title: "Recent",
                                isSelected: selectedTab == .recent,
                                action: { selectedTab = .recent }
                            )
                            
                            ProfileTabButton(
                                title: "Shared",
                                isSelected: selectedTab == .shared,
                                action: { selectedTab = .shared }
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        // Content based on selected tab
                        if selectedTab == .recent {
                            if profileViewModel.workouts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary.opacity(0.3))
                                    Text("No workouts yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Start your first workout!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(profileViewModel.workouts) { workout in
                                    Button(action: {
                                        selectedWorkout = workout
                                    }) {
                                        WorkoutHistoryCard(workout: workout)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            if profileViewModel.sharedWorkouts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary.opacity(0.3))
                                    Text("No shared workouts yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Start a live workout with a friend!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(profileViewModel.sharedWorkouts) { workout in
                                    Button(action: {
                                        selectedWorkout = workout
                                    }) {
                                        SharedWorkoutCard(workout: workout)
                                    }
                                    .buttonStyle(.plain)
                                }
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
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(12)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(AppSettings.shared)
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
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(appSettings.cardBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.primary)
                    .font(.system(size: 16, weight: .semibold))
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
                        .background(appSettings.cardBackground)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appSettings.cardBackground)
                .shadow(color: Color.black.opacity(appSettings.isDarkMode ? 0.05 : 0.02), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ProfileTabButton: View {
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
                                .fill(
                                    LinearGradient(
                                        colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            LinearGradient(
                                                colors: appSettings.isDarkMode ? [appSettings.accentColor, appSettings.accentColorSecondary] : [appSettings.accentColor, appSettings.accentColorSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        } else {
                            Color.clear
                        }
                    }
                )
        }
    }
}

struct SharedWorkoutCard: View {
    let workout: Workout
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(appSettings.cardBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.2.fill")
                    .foregroundColor(.primary)
                    .font(.system(size: 16, weight: .semibold))
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
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(partnerName)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appSettings.cardBackground)
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
                
                // Show combined stats
                let totalWeight = workout.exercises.reduce(0) { total, exercise in
                    total + exercise.sets.reduce(0) { setTotal, set in
                        setTotal + (set.weight * Double(set.reps))
                    }
                }
                
                if totalWeight > 0 {
                    Text("Combined: \(Int(totalWeight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appSettings.cardBackground)
                .shadow(color: Color.black.opacity(appSettings.isDarkMode ? 0.05 : 0.02), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
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
                            .font(.system(size: 18, weight: .semibold))
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
                    .padding(12)
                    
                    Divider()
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal, 12)
                        
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
    @EnvironmentObject var appSettings: AppSettings
    
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
}

struct ExerciseDetailCard: View {
    let exercise: Exercise
    @EnvironmentObject var appSettings: AppSettings
    
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
        .padding(12)
                        .background(appSettings.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }
}

