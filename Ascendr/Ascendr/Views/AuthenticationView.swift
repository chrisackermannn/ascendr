//
//  AuthenticationView.swift
//  Ascendr
//
//  Modern Login and Sign Up view
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isSignUpMode = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, email, password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Logo/Title
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Ascendr")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Elevate Your Fitness Journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                    
                    // Form Card
                    VStack(spacing: 20) {
                        // Mode Toggle
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isSignUpMode = false
                                }
                            }) {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(isSignUpMode ? .secondary : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isSignUpMode ? Color.clear : Color.blue.opacity(0.1))
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isSignUpMode = true
                                }
                            }) {
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(isSignUpMode ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isSignUpMode ? Color.blue.opacity(0.1) : Color.clear)
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        VStack(spacing: 16) {
                            if isSignUpMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Username")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    TextField("Enter username", text: $authViewModel.username)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                        .focused($focusedField, equals: .username)
                                        .autocapitalization(.none)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                TextField("Enter email", text: $authViewModel.email)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                SecureField("Enter password", text: $authViewModel.password)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            if let error = authViewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: {
                                focusedField = nil
                                Task {
                                    if isSignUpMode {
                                        await authViewModel.signUp()
                                    } else {
                                        await authViewModel.signIn()
                                    }
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(isSignUpMode ? "Create Account" : "Sign In")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(authViewModel.isLoading)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    
                    // Test User Info (for development)
                    #if DEBUG
                    VStack(spacing: 8) {
                        Text("Test User")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Email: test@ascendr.com")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Password: test123")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    #endif
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }
}

