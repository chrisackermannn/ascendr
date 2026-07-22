//
//  PendingLiveWorkoutRequestsView.swift
//  Ascendr
//
//  View to show pending live workout requests
//

import SwiftUI
import FirebaseDatabase
import Firebase

struct PendingLiveWorkoutRequestsView: View {
    @Binding var invites: [LiveWorkoutInvite]
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var liveWorkoutViewModel = LiveWorkoutViewModel()
    @State private var showingLiveWorkout = false
    @State private var showingWaitingRoom = false
    @State private var waitingRoomSessionId: String?
    @State private var waitingRoomPartnerName: String?
    @State private var waitingRoomIsInviter: Bool = false
    @State private var pendingSessions: [PendingSession] = []
    @State private var preloadedSessionData: [String: Any]?
    @State private var preloadedInviteTimestamp: TimeInterval?
    
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
                        // Show pending sessions first (for both users to rejoin)
                        ForEach(pendingSessions) { session in
                            PendingSessionRow(
                                session: session,
                                onJoin: {
                                    // Determine if this is waiting or active
                                    Task {
                                        await joinSession(session)
                                    }
                                }
                            )
                        }
                        
                        // Show incoming invites
                        ForEach(invites) { invite in
                            LiveWorkoutRequestRow(
                                invite: invite,
                                currentUserId: authViewModel.currentUser?.id ?? "",
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
            .fullScreenCover(isPresented: $showingWaitingRoom) {
                if let sessionId = waitingRoomSessionId,
                   let partnerName = waitingRoomPartnerName {
                    WaitingRoomView(
                        sessionId: sessionId,
                        partnerName: partnerName,
                        isInviter: waitingRoomIsInviter,
                        preloadedSessionData: preloadedSessionData,
                        preloadedInviteTimestamp: preloadedInviteTimestamp
                    )
                    .environmentObject(authViewModel)
                    .environmentObject(AppSettings.shared)
                }
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
        
        // Check if this is a sent invite (inviter rejoining)
        let isInviter = userId == invite.fromUserId
        
        if isInviter {
            // Inviter is rejoining - show waiting room IMMEDIATELY with sessionId from invite
            // Use invitee name from invite if available, otherwise use placeholder
            let initialPartnerName = invite.toUserName ?? invite.toUserId
            
            // Show waiting room IMMEDIATELY - no Firebase fetch needed!
            if let sessionId = invite.sessionId {
                // PRELOAD: Fetch ALL session data and invite timestamp BEFORE showing (parallel)
                let sessionRef = Database.database().reference().child("liveWorkouts").child(sessionId)
                let inviteRef = Database.database().reference().child("liveWorkoutInvites").child(userId).child(invite.inviteId)
                
                // Fetch both in parallel using async let for maximum speed
                async let sessionDataTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any]?, Error>) in
                    sessionRef.observeSingleEvent(of: .value) { snapshot, _ in
                        continuation.resume(returning: snapshot.value as? [String: Any])
                    }
                }
                
                async let inviteTimestampTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<TimeInterval?, Error>) in
                    inviteRef.observeSingleEvent(of: .value) { snapshot, _ in
                        if let data = snapshot.value as? [String: Any],
                           let timestamp = data["timestamp"] as? TimeInterval {
                            continuation.resume(returning: timestamp)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                
                let sessionData = try? await sessionDataTask
                let inviteTimestamp = try? await inviteTimestampTask
                
                await MainActor.run {
                    waitingRoomSessionId = sessionId
                    waitingRoomPartnerName = initialPartnerName
                    waitingRoomIsInviter = true
                    preloadedSessionData = sessionData
                    preloadedInviteTimestamp = inviteTimestamp
                    showingWaitingRoom = true
                }
                
                // Fetch actual partner name from session in background (non-blocking)
                Task {
                    let sessionRef = Database.database().reference().child("liveWorkouts").child(sessionId)
                    let sessionSnapshot = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                        sessionRef.observeSingleEvent(of: .value) { snapshot, error in
                            if let error = error {
                                let dbError: Error
                                if let nsError = error as? NSError {
                                    dbError = nsError
                                } else {
                                    dbError = NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                                }
                                continuation.resume(throwing: dbError)
                                return
                            }
                            
                            guard snapshot.exists() else {
                                continuation.resume(throwing: NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "No snapshot returned"]))
                                return
                            }
                            
                            continuation.resume(returning: snapshot)
                        }
                    }
                    
                    if let sessionData = sessionSnapshot?.value as? [String: Any],
                       let userId1 = sessionData["userId1"] as? String,
                       let userName1 = sessionData["userName1"] as? String,
                       let userId2 = sessionData["userId2"] as? String,
                       let userName2 = sessionData["userName2"] as? String {
                        let partnerName = userId == userId1 ? userName2 : userName1
                        
                        // Update partner name if it changed
                        await MainActor.run {
                            if waitingRoomPartnerName != partnerName {
                                waitingRoomPartnerName = partnerName
                            }
                        }
                    }
                }
            } else {
                // Fallback: if sessionId not in invite, fetch it (shouldn't happen normally)
                print("Warning: sessionId not found in invite, fetching from Firebase")
                let inviteRef = Database.database().reference().child("liveWorkoutInvites").child(userId).child(invite.inviteId)
                let snapshot = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                    inviteRef.observeSingleEvent(of: .value) { snapshot, error in
                        if let error = error {
                            let dbError: Error
                            if let nsError = error as? NSError {
                                dbError = nsError
                            } else {
                                dbError = NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                            }
                            continuation.resume(throwing: dbError)
                            return
                        }
                        
                        guard snapshot.exists() else {
                            continuation.resume(throwing: NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "No snapshot returned"]))
                            return
                        }
                        
                        continuation.resume(returning: snapshot)
                    }
                }
                
                if let inviteData = snapshot?.value as? [String: Any],
                   let sessionId = inviteData["sessionId"] as? String {
                    await MainActor.run {
                        waitingRoomSessionId = sessionId
                        waitingRoomPartnerName = initialPartnerName
                        waitingRoomIsInviter = true
                        showingWaitingRoom = true
                    }
                }
            }
        } else {
            // Invitee accepting invite - show waiting room IMMEDIATELY
            // If sessionId is in invite, use it immediately, otherwise accept invite first
            if let sessionId = invite.sessionId {
                // PRELOAD: Fetch ALL session data and invite timestamp BEFORE showing (parallel)
                let sessionRef = Database.database().reference().child("liveWorkouts").child(sessionId)
                let inviteRef = Database.database().reference().child("liveWorkoutInvites").child(userId).child(invite.inviteId)
                
                // Fetch both in parallel using async let for maximum speed
                async let sessionDataTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any]?, Error>) in
                    sessionRef.observeSingleEvent(of: .value) { snapshot, _ in
                        continuation.resume(returning: snapshot.value as? [String: Any])
                    }
                }
                
                async let inviteTimestampTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<TimeInterval?, Error>) in
                    inviteRef.observeSingleEvent(of: .value) { snapshot, _ in
                        if let data = snapshot.value as? [String: Any],
                           let timestamp = data["timestamp"] as? TimeInterval {
                            continuation.resume(returning: timestamp)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                
                let sessionData = try? await sessionDataTask
                let inviteTimestamp = try? await inviteTimestampTask
                
                await MainActor.run {
                    waitingRoomSessionId = sessionId
                    waitingRoomPartnerName = invite.fromUserName
                    waitingRoomIsInviter = false
                    preloadedSessionData = sessionData
                    preloadedInviteTimestamp = inviteTimestamp
                    showingWaitingRoom = true
                }
                
                // Accept invite in background (non-blocking)
                Task {
                    let databaseService = RealtimeDatabaseService()
                    try? await databaseService.acceptLiveWorkoutInvite(
                        inviteId: invite.inviteId,
                        toUserId: userId,
                        toUserName: userName
                    )
                    
                    // Notify the inviter in background (non-blocking)
                    let notificationRef = Database.database().reference()
                        .child("liveWorkoutNotifications")
                        .child(invite.fromUserId)
                        .child(sessionId)
                    
                    try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
                }
            } else {
                // Fallback: if sessionId not in invite, accept invite first (shouldn't happen normally)
                let databaseService = RealtimeDatabaseService()
                if let sessionId = try? await databaseService.acceptLiveWorkoutInvite(
                    inviteId: invite.inviteId,
                    toUserId: userId,
                    toUserName: userName
                ) {
                    // Show waiting room IMMEDIATELY
                    await MainActor.run {
                        waitingRoomSessionId = sessionId
                        waitingRoomPartnerName = invite.fromUserName
                        waitingRoomIsInviter = false
                        showingWaitingRoom = true
                    }
                    
                    // Notify the inviter in background (non-blocking)
                    Task {
                        let notificationRef = Database.database().reference()
                            .child("liveWorkoutNotifications")
                            .child(invite.fromUserId)
                            .child(sessionId)
                        
                        try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
                    }
                }
            }
        }
    }
    
    private func joinSession(_ session: PendingSession) async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        // PRELOAD: Fetch ALL session data and invite timestamp BEFORE showing (parallel)
        let sessionRef = Database.database().reference().child("liveWorkouts").child(session.sessionId)
        let invitesRef = Database.database().reference().child("liveWorkoutInvites").child(userId)
        
        // Fetch both in parallel using async let for maximum speed
        async let sessionDataTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any]?, Error>) in
            sessionRef.observeSingleEvent(of: .value) { snapshot, _ in
                continuation.resume(returning: snapshot.value as? [String: Any])
            }
        }
        
        async let inviteTimestampTask = withCheckedThrowingContinuation { (continuation: CheckedContinuation<TimeInterval?, Error>) in
            invitesRef.observeSingleEvent(of: .value) { snapshot, _ in
                if let invitesData = snapshot.value as? [String: [String: Any]] {
                    for (_, inviteData) in invitesData {
                        if let inviteSessionId = inviteData["sessionId"] as? String,
                           inviteSessionId == session.sessionId,
                           let timestamp = inviteData["timestamp"] as? TimeInterval {
                            continuation.resume(returning: timestamp)
                            return
                        }
                    }
                }
                continuation.resume(returning: nil)
            }
        }
        
        let sessionData = try? await sessionDataTask
        let inviteTimestamp = try? await inviteTimestampTask
        
        // Show waiting room IMMEDIATELY with preloaded data
        await MainActor.run {
            waitingRoomSessionId = session.sessionId
            waitingRoomPartnerName = session.partnerName
            waitingRoomIsInviter = session.userId == userId
            preloadedSessionData = sessionData
            preloadedInviteTimestamp = inviteTimestamp
            showingWaitingRoom = true
        }
        
        // Check session status in background (non-blocking)
        Task {
            let sessionRef = Database.database().reference().child("liveWorkouts").child(session.sessionId)
            let snapshot = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                sessionRef.observeSingleEvent(of: .value) { snapshot, error in
                    if let error = error {
                        let dbError: Error
                        if let nsError = error as? NSError {
                            dbError = nsError
                        } else {
                            dbError = NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                        }
                        continuation.resume(throwing: dbError)
                        return
                    }
                    
                    guard snapshot.exists() else {
                        continuation.resume(throwing: NSError(domain: "PendingLiveWorkoutRequestsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "No snapshot returned"]))
                        return
                    }
                    
                    continuation.resume(returning: snapshot)
                }
            }
            
            guard let sessionData = snapshot?.value as? [String: Any],
                  let status = sessionData["status"] as? String,
                  let userId1 = sessionData["userId1"] as? String,
                  let userName1 = sessionData["userName1"] as? String,
                  let userId2 = sessionData["userId2"] as? String,
                  let userName2 = sessionData["userName2"] as? String else {
                return
            }
            
            let partnerName = userId == userId1 ? userName2 : userName1
            let isInviter = userId == userId1
            
            await MainActor.run {
                if status == "active" {
                    // Session is active - close waiting room and go to workout
                    showingWaitingRoom = false
                    liveWorkoutViewModel.startLiveWorkout(sessionId: session.sessionId, currentUserId: userId)
                    showingLiveWorkout = true
                } else if status == "waiting" {
                    // Update partner name if it changed
                    if waitingRoomPartnerName != partnerName {
                        waitingRoomPartnerName = partnerName
                    }
                    if waitingRoomIsInviter != isInviter {
                        waitingRoomIsInviter = isInviter
                    }
                    // Already in waiting room, just update info
                }
            }
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
    let currentUserId: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var timeRemaining: Int = 120 // 2 minutes
    @State private var timer: Timer?
    @State private var timerActive = true
    
    private var isSentInvite: Bool {
        currentUserId == invite.fromUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isSentInvite {
                        Text("Waiting for response")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let toUserName = invite.toUserName {
                            Text("Invited: \(toUserName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to rejoin waiting room")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(invite.fromUserName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("wants to start a live workout")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(timeRemaining)s remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                if !isSentInvite {
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
                }
                
                Button(action: onAccept) {
                    Text(isSentInvite ? "Rejoin" : "Accept")
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
        .onDisappear {
            stopTimer()
        }
    }
    
    private func calculateTimeRemaining() {
        let elapsed = Date().timeIntervalSince(invite.timestamp)
        timeRemaining = max(0, 120 - Int(elapsed)) // 2 minutes
        
        // Update every second
        timer?.invalidate()
        timerActive = true
        let inviteTimestamp = invite.timestamp
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                guard self.timerActive else {
                    timer.invalidate()
                    return
                }
                
                let elapsed = Date().timeIntervalSince(inviteTimestamp)
                let newTimeRemaining = max(0, 120 - Int(elapsed)) // 2 minutes
                self.timeRemaining = newTimeRemaining
                
                if newTimeRemaining <= 0 {
                    self.timerActive = false
                    timer.invalidate()
                }
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
    }
}

