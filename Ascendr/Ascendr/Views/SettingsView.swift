//
//  SettingsView.swift
//  Ascendr
//
//  Settings view for user preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var usernameError: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
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
                    Button("Done") {
                        dismiss()
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

