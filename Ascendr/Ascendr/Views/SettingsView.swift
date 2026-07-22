//
//  SettingsView.swift
//  Ascendr
//
//  Settings view for user preferences
//

import SwiftUI
import HealthKit

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var showingSuccess = false
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isRequestingHealthKit = false
    @State private var healthKitError: String?
    @State private var healthKitSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Home screen gradient background
                appSettings.homeGradient
                    .ignoresSafeArea()
                
                Form {
                Section("Profile") {
                    profilePictureSection
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
                
                Section("Health & Fitness") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HealthKit Access")
                                .font(.body)
                            Text(healthKitManager.isAuthorized ? "Authorized" : "Not Authorized")
                                .font(.caption)
                                .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
                        }
                        Spacer()
                    }
                    
                    if !healthKitManager.isAuthorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enable access to track your steps and calories from the Health app.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let error = healthKitError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            if healthKitSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Authorization requested! Please check your Health app settings.")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Button(action: requestHealthKitAuthorization) {
                                HStack {
                                    if isRequestingHealthKit {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: "heart.circle.fill")
                                        Text("Request HealthKit Access")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(isRequestingHealthKit)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Steps and calories are being tracked from Health app")
                                .font(.caption)
                                .foregroundColor(.green)
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
            }
            .id(appSettings.isDarkMode) // Force refresh when theme changes
            .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Change Profile Picture", isPresented: $showingImageSourcePicker, titleVisibility: .visible) {
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
                SettingsImagePicker(image: $selectedImage, sourceType: imagePickerSourceType)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue, let userId = authViewModel.currentUser?.id {
                    Task {
                        print("🖼️ Image selected, starting upload process...")
                        
                        // Upload profile image
                        await profileViewModel.updateProfileImage(image, userId: userId)
                        
                        // Refresh current user data in auth view model to update everywhere
                        await authViewModel.refreshCurrentUser()
                        print("✅ AuthViewModel updated with new profile image")
                        
                        // Clear selected image after processing
                        await MainActor.run {
                            selectedImage = nil
                        }
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
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "HealthKit is not available on this device"
            return
        }
        
        isRequestingHealthKit = true
        healthKitError = nil
        healthKitSuccess = false
        
        healthKitManager.requestAuthorization()
        
        // Check if authorized after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.healthKitManager.isAuthorized {
                self.healthKitSuccess = true
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.healthKitSuccess = false
                }
            } else {
                self.healthKitError = "Authorization was not granted. Please check your Health app settings."
            }
            self.isRequestingHealthKit = false
        }
    }
    
    // MARK: - View Components
    private var profilePictureSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                profileImageWithOverlay
                editButtonOverlay
            }
            
            if let error = profileViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Tap to change profile picture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var profileImageWithOverlay: some View {
        ZStack {
            AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    emptyStateView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    failureStateView
                @unknown default:
                    failureStateView
                }
            }
            .id(authViewModel.currentUser?.profileImageURL ?? UUID().uuidString)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            if profileViewModel.isLoading {
                loadingOverlay
            }
        }
    }
    
    private var emptyStateView: some View {
        ZStack {
            Circle()
                .fill(appSettings.secondaryBackground)
            ProgressView()
        }
    }
    
    private var failureStateView: some View {
        ZStack {
            Circle()
                .fill(appSettings.secondaryBackground)
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(width: 100, height: 100)
    }
    
    private var editButtonOverlay: some View {
        Button(action: {
            showingImageSourcePicker = true
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
        .disabled(profileViewModel.isLoading)
    }
}

// MARK: - Image Picker for Settings
struct SettingsImagePicker: UIViewControllerRepresentable {
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
        let parent: SettingsImagePicker
        
        init(_ parent: SettingsImagePicker) {
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

