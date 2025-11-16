//
//  AuthenticationView.swift
//  Ascendr
//
//  Login and Sign Up view
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isSignUpMode = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App Logo/Title
            Text("Ascendr")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
            
            Spacer()
            
            VStack(spacing: 16) {
                if isSignUpMode {
                    TextField("Username", text: $authViewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                
                TextField("Email", text: $authViewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $authViewModel.password)
                    .textFieldStyle(.roundedBorder)
                
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        if isSignUpMode {
                            await authViewModel.signUp()
                        } else {
                            await authViewModel.signIn()
                        }
                    }
                }) {
                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(authViewModel.isLoading)
                
                Button(action: {
                    isSignUpMode.toggle()
                }) {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

