//
//  WaitingRoomView.swift
//  Ascendr
//
//  Waiting room for live workout inviter
//

import SwiftUI
import FirebaseDatabase

struct WaitingRoomView: View {
    let friendName: String
    let friendId: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var liveWorkoutViewModel = LiveWorkoutViewModel()
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    @State private var showingLiveWorkout = false
    @State private var sessionHandle: DatabaseHandle?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Waiting animation
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Waiting for \(friendName)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("They have \(timeRemaining) seconds to accept")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Pulsing indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .opacity(0.6)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .opacity(0.4)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .opacity(0.2)
                }
                .padding()
                
                Spacer()
                
                // Cancel button
                Button(action: {
                    Task {
                        await cancelInvite()
                    }
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Waiting Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        Task {
                            await cancelInvite()
                        }
                    }
                }
            }
            .onAppear {
                startTimer()
                startListeningForAcceptance()
            }
            .onDisappear {
                stopTimer()
                cleanup()
            }
            .fullScreenCover(isPresented: $showingLiveWorkout) {
                LiveWorkoutView()
                    .environmentObject(AppSettings.shared)
                    .environmentObject(liveWorkoutViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time expired
                stopTimer()
                dismiss()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startListeningForAcceptance() {
        // Listen for session notifications (when invitee accepts)
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let notificationsRef = Database.database().reference().child("liveWorkoutNotifications").child(userId)
        sessionHandle = notificationsRef.observe(.childAdded) { snapshot, _ in
            guard let sessionData = snapshot.value as? [String: Any],
                  let sessionId = sessionData["sessionId"] as? String else { return }
            
            Task { @MainActor in
                // Use the captured userId and update state directly
                // Since this is a struct, we need to update state through the view's binding mechanism
                // We'll handle this through a notification or by using a view model
                liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: userId)
                
                // Update state on main thread
                DispatchQueue.main.async {
                    stopTimer()
                    showingLiveWorkout = true
                }
                
                // Remove notification after reading
                snapshot.ref.removeValue()
            }
        }
    }
    
    private func cleanup() {
        if let handle = sessionHandle {
            Database.database().reference().child("liveWorkoutNotifications").child(authViewModel.currentUser?.id ?? "").removeObserver(withHandle: handle)
            sessionHandle = nil
        }
    }
    
    private func cancelInvite() async {
        stopTimer()
        cleanup()
        dismiss()
    }
}

