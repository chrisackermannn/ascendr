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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        }
                        
                        Text(authViewModel.currentUser?.username ?? "User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(profileViewModel.workouts.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Workouts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(profileViewModel.progressPics.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Progress Pics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
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
                                WorkoutHistoryCard(workout: workout)
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
            .navigationTitle("Profile")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage, let userId = authViewModel.currentUser?.id {
                    Task {
                        await profileViewModel.updateProfileImage(image, userId: userId)
                    }
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.date, style: .date)
                    .font(.headline)
                
                Spacer()
                
                if let partnerName = workout.partnerName {
                    Label(partnerName, systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Text("\(workout.exercises.count) exercises")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if workout.duration > 0 {
                Text("Duration: \(formatDuration(workout.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
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
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

