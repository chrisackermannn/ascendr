//
//  PendingLiveWorkoutRequestsView.swift
//  Ascendr
//
//  View to show pending live workout requests
//

import SwiftUI
import FirebaseDatabase

struct PendingLiveWorkoutRequestsView: View {
    @Binding var invites: [LiveWorkoutInvite]
    let onAccept: (LiveWorkoutInvite) -> Void
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var liveWorkoutViewModel = LiveWorkoutViewModel()
    @State private var showingLiveWorkout = false
    @State private var pendingSessions: [PendingSession] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if invites.isEmpty && pendingSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Text("No Pending Requests")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Live workout requests will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Show pending sessions first (for inviter to rejoin)
                        ForEach(pendingSessions) { session in
                            PendingSessionRow(
                                session: session,
                                onJoin: {
                                    liveWorkoutViewModel.startLiveWorkout(sessionId: session.sessionId, currentUserId: session.userId)
                                    showingLiveWorkout = true
                                }
                            )
                        }
                        
                        // Show incoming invites
                        ForEach(invites) { invite in
                            LiveWorkoutRequestRow(
                                invite: invite,
                                onAccept: {
                                    Task {
                                        await acceptInvite(invite)
                                    }
                                },
                                onDecline: {
                                    Task {
                                        let databaseService = RealtimeDatabaseService()
                                        try? await databaseService.rejectLiveWorkoutInvite(
                                            inviteId: invite.inviteId,
                                            toUserId: invite.toUserId
                                        )
                                        loadInvites()
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pending Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingLiveWorkout) {
                LiveWorkoutView()
                    .environmentObject(AppSettings.shared)
                    .environmentObject(liveWorkoutViewModel)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                loadInvites()
            }
        }
    }
    
    private func loadInvites() {
        Task {
            if let userId = authViewModel.currentUser?.id {
                let databaseService = RealtimeDatabaseService()
                
                // Load pending invites
                if let fetchedInvites = try? await databaseService.fetchPendingLiveWorkoutInvites(userId: userId) {
                    await MainActor.run {
                        invites = fetchedInvites
                    }
                }
                
                // Load pending sessions (for inviter to rejoin)
                if let sessions = try? await databaseService.fetchPendingSessions(userId: userId) {
                    await MainActor.run {
                        pendingSessions = sessions
                    }
                }
            }
        }
    }
    
    private func acceptInvite(_ invite: LiveWorkoutInvite) async {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.username else { return }
        
        do {
            let databaseService = RealtimeDatabaseService()
            if let sessionId = try await databaseService.acceptLiveWorkoutInvite(
                inviteId: invite.inviteId,
                toUserId: userId,
                toUserName: userName
            ) {
                // Notify the inviter to join the session
                let notificationRef = Database.database().reference()
                    .child("liveWorkoutNotifications")
                    .child(invite.fromUserId)
                    .child(sessionId)
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    notificationRef.setValue([
                        "sessionId": sessionId,
                        "timestamp": Date().timeIntervalSince1970
                    ]) { error, _ in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                
                // Start the live workout
                await MainActor.run {
                    liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: userId)
                    showingLiveWorkout = true
                }
            }
        } catch {
            print("Error accepting invite: \(error)")
        }
    }
}

struct PendingSession: Identifiable {
    let id: String
    let sessionId: String
    let userId: String
    let partnerName: String
    let timestamp: Date
}

struct PendingSessionRow: View {
    let session: PendingSession
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Session")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("with \(session.partnerName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap to rejoin")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            
            Button(action: onJoin) {
                Text("Join Session")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct LiveWorkoutRequestRow: View {
    let invite: LiveWorkoutInvite
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var timeRemaining: Int = 60
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.fromUserName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("wants to start a live workout")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(timeRemaining)s remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            calculateTimeRemaining()
        }
    }
    
    private func calculateTimeRemaining() {
        let elapsed = Date().timeIntervalSince(invite.timestamp)
        timeRemaining = max(0, 60 - Int(elapsed))
        
        // Update every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(invite.timestamp)
            timeRemaining = max(0, 60 - Int(elapsed))
            
            if timeRemaining <= 0 {
                timer.invalidate()
            }
        }
    }
}

