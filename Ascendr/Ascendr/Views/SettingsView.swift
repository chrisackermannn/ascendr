//
//  SettingsView.swift
//  Ascendr
//
//  Settings view for user preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var showingSuccess = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }                             placeholder: {
                                ZStack {
                                    Circle()
                                        .fill(appSettings.secondaryBackground)
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            
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
                            .offset(x: 8, y: 8)
                        }
                        
                        Text("Tap to change profile picture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    HStack {
                        Text("Current Username")
                        Spacer()
                        Text(authViewModel.currentUser?.username ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter new username", text: $newUsername)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: newUsername) { oldValue, newValue in
                                usernameError = nil
                            }
                        
                        if let error = usernameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if showingSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Username updated successfully!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button(action: updateUsername) {
                        HStack {
                            if isCheckingUsername {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Update Username")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isCheckingUsername || newUsername.trimmingCharacters(in: .whitespaces).isEmpty || newUsername.lowercased() == authViewModel.currentUser?.username.lowercased())
                }
                
                Section("Appearance") {
                    Toggle(isOn: $appSettings.isDarkMode) {
                        HStack {
                            Image(systemName: appSettings.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(appSettings.accentColor)
                            Text(appSettings.isDarkMode ? "Dark Mode" : "Light Mode")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .id(appSettings.isDarkMode) // Force refresh when theme changes
            .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
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
                    Button("Done") {
                        dismiss()
                    }
                }
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
        }
    }
    
    private func updateUsername() {
        guard !newUsername.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isCheckingUsername = true
        usernameError = nil
        showingSuccess = false
        
        Task {
            do {
                try await authViewModel.updateUsername(newUsername.trimmingCharacters(in: .whitespaces))
                await MainActor.run {
                    showingSuccess = true
                    newUsername = ""
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    usernameError = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isCheckingUsername = false
            }
        }
    }
}

