//
//  WaitingRoomView.swift
//  Ascendr
//
//  Shared waiting room for both users in live workout
//

import SwiftUI
import FirebaseDatabase

struct WaitingRoomView: View {
    let sessionId: String
    let partnerName: String
    let isInviter: Bool
    let preloadedSessionData: [String: Any]?
    let preloadedInviteTimestamp: TimeInterval?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var liveWorkoutViewModel = LiveWorkoutViewModel()
    @State private var session: LiveWorkoutSession?
    @State private var isReady = false
    @State private var showingLiveWorkout = false
    @State private var sessionHandle: DatabaseHandle?
    @State private var timeRemaining = 120 // 2 minutes
    @State private var timer: Timer?
    @State private var inviteTimestamp: TimeInterval?
    
    init(sessionId: String, partnerName: String, isInviter: Bool, preloadedSessionData: [String: Any]? = nil, preloadedInviteTimestamp: TimeInterval? = nil) {
        self.sessionId = sessionId
        self.partnerName = partnerName
        self.isInviter = isInviter
        self.preloadedSessionData = preloadedSessionData
        self.preloadedInviteTimestamp = preloadedInviteTimestamp
    }
    
    private let databaseService = RealtimeDatabaseService()
    
    private var currentUserId: String? {
        authViewModel.currentUser?.id
    }
    
    private var isUser1: Bool {
        guard let currentUserId = currentUserId,
              let session = session else { return false }
        return currentUserId == session.userId1
    }
    
    private var myReadyStatus: Bool {
        guard let session = session else { return false }
        return isUser1 ? session.user1Ready : session.user2Ready
    }
    
    private var partnerReadyStatus: Bool {
        guard let session = session else { return false }
        return isUser1 ? session.user2Ready : session.user1Ready
    }
    
    private var bothReady: Bool {
        guard let session = session else { return false }
        return session.user1Ready && session.user2Ready
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                        Spacer()
                        
                        // Partner info
                        VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [appSettings.accentColor.opacity(0.3), appSettings.accentColorSecondary.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(appSettings.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Waiting Room")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(appSettings.primaryText)
                            
                            Text("with \(partnerName)")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(appSettings.primaryText.opacity(0.7))
                            
                            // 2-minute countdown timer
                            Text("\(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(timeRemaining <= 30 ? .red : appSettings.accentColor)
                                .padding(.top, 8)
                            
                            Text("Session expires in")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appSettings.primaryText.opacity(0.6))
                        }
                    }
                    
                    // Ready status
                    VStack(spacing: 16) {
                        // Your status
                        HStack(spacing: 12) {
                            Text("You")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(appSettings.primaryText)
                            
                            Spacer()
                            
                            if myReadyStatus {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Ready")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("Not Ready")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(appSettings.cardBackground)
                        )
                        
                        // Partner status
                        HStack(spacing: 12) {
                            Text(partnerName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(appSettings.primaryText)
                            
                            Spacer()
                            
                            if partnerReadyStatus {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Ready")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("Waiting...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(appSettings.cardBackground)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Ready button or Start button
                    if bothReady {
                        Button(action: {
                            Task {
                                await startWorkout()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(appSettings.buttonGradient)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Button(action: {
                            Task {
                                await toggleReady()
                            }
                        }) {
                            HStack {
                                Image(systemName: myReadyStatus ? "xmark.circle.fill" : "checkmark.circle.fill")
                                Text(myReadyStatus ? "Not Ready" : "I'm Ready")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if myReadyStatus {
                                        Color.red
                                    } else {
                                        appSettings.buttonGradient
                                    }
                                }
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Status message
                    if bothReady {
                        Text("Both ready! Press Start Workout to begin")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.top, 8)
                    } else {
                        Text("Waiting for both users to be ready...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Leave button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Leave Waiting Room")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                // Start countdown immediately
                startCountdownTimer()
                // Load session immediately (non-blocking)
                startListeningToSession()
            }
            .onDisappear {
                cleanup()
            }
            .fullScreenCover(isPresented: $showingLiveWorkout) {
                LiveWorkoutView()
                    .environmentObject(appSettings)
                    .environmentObject(liveWorkoutViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func startListeningToSession() {
        // Use preloaded data if available - INSTANT loading!
        if let preloadedData = preloadedSessionData,
           let sessionId = preloadedData["sessionId"] as? String,
           let userId1 = preloadedData["userId1"] as? String,
           let userName1 = preloadedData["userName1"] as? String,
           let userId2 = preloadedData["userId2"] as? String,
           let userName2 = preloadedData["userName2"] as? String,
           let status = preloadedData["status"] as? String {
            
            let exercises: [Exercise] = []
            let user1Ready = preloadedData["user1Ready"] as? Bool ?? false
            let user2Ready = preloadedData["user2Ready"] as? Bool ?? false
            
            Task { @MainActor in
                self.session = LiveWorkoutSession(
                    sessionId: sessionId,
                    userId1: userId1,
                    userName1: userName1,
                    userId2: userId2,
                    userName2: userName2,
                    status: status,
                    exercises: exercises,
                    user1Ready: user1Ready,
                    user2Ready: user2Ready
                )
            }
        }
        
        // Use preloaded invite timestamp if available
        if let timestamp = preloadedInviteTimestamp {
            Task { @MainActor in
                self.inviteTimestamp = timestamp
                self.startCountdownTimer()
            }
        } else {
            // Fallback: fetch invite timestamp if not preloaded
            Task {
                guard let currentUserId = currentUserId else { return }
                
                let invitesRef = Database.database().reference().child("liveWorkoutInvites").child(currentUserId)
                let invitesSnapshot = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                    invitesRef.observeSingleEvent(of: .value) { snapshot, error in
                        if let error = error {
                            let dbError: Error
                            if let nsError = error as? NSError {
                                dbError = nsError
                            } else {
                                dbError = NSError(domain: "WaitingRoomView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                            }
                            continuation.resume(throwing: dbError)
                            return
                        }
                        continuation.resume(returning: snapshot)
                    }
                }
                
                if let invitesData = invitesSnapshot?.value as? [String: [String: Any]] {
                    for (_, inviteData) in invitesData {
                        if let inviteSessionId = inviteData["sessionId"] as? String,
                           inviteSessionId == sessionId,
                           let timestamp = inviteData["timestamp"] as? TimeInterval {
                            await MainActor.run {
                                self.inviteTimestamp = timestamp
                                self.startCountdownTimer()
                            }
                            break
                        }
                    }
                }
            }
        }
        
        // If no preloaded data, fetch session (fallback)
        if preloadedSessionData == nil {
            Task {
                do {
                    let sessionRef = Database.database().reference().child("liveWorkouts").child(sessionId)
                    let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                        sessionRef.observeSingleEvent(of: .value) { snapshot, error in
                            if let error = error {
                                let dbError: Error
                                if let nsError = error as? NSError {
                                    dbError = nsError
                                } else {
                                    dbError = NSError(domain: "WaitingRoomView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error: \(error)"])
                                }
                                continuation.resume(throwing: dbError)
                                return
                            }
                            
                            guard snapshot.exists() else {
                                continuation.resume(throwing: NSError(domain: "WaitingRoomView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session not found"]))
                                return
                            }
                            
                            continuation.resume(returning: snapshot)
                        }
                    }
                    
                    if let sessionData = snapshot.value as? [String: Any],
                       let sessionId = sessionData["sessionId"] as? String,
                       let userId1 = sessionData["userId1"] as? String,
                       let userName1 = sessionData["userName1"] as? String,
                       let userId2 = sessionData["userId2"] as? String,
                       let userName2 = sessionData["userName2"] as? String,
                       let status = sessionData["status"] as? String {
                        
                        let exercises: [Exercise] = []
                        let user1Ready = sessionData["user1Ready"] as? Bool ?? false
                        let user2Ready = sessionData["user2Ready"] as? Bool ?? false
                        
                        await MainActor.run {
                            self.session = LiveWorkoutSession(
                                sessionId: sessionId,
                                userId1: userId1,
                                userName1: userName1,
                                userId2: userId2,
                                userName2: userName2,
                                status: status,
                                exercises: exercises,
                                user1Ready: user1Ready,
                                user2Ready: user2Ready
                            )
                        }
                    }
                } catch {
                    print("Error fetching session: \(error)")
                }
            }
        }
        
        // Then set up listener for real-time updates
        sessionHandle = databaseService.listenToLiveWorkout(sessionId: sessionId) { session in
            Task { @MainActor in
                self.session = session
                
                // If both are ready and status is still waiting, auto-start
                if let session = session,
                   session.status == "waiting",
                   session.user1Ready && session.user2Ready {
                    // Small delay to ensure both users see ready status
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await self.startWorkout()
                }
                
                // If status changed to active, start workout
                if session?.status == "active" {
                    await self.startLiveWorkout()
                }
            }
        }
    }
    
    private func toggleReady() async {
        guard let currentUserId = currentUserId else { return }
        
        let newReadyStatus = !myReadyStatus
        isReady = newReadyStatus
        
        do {
            try await databaseService.updateReadyStatus(
                sessionId: sessionId,
                userId: currentUserId,
                isReady: newReadyStatus
            )
        } catch {
            print("Error updating ready status: \(error)")
        }
    }
    
    private func startWorkout() async {
        guard let currentUserId = currentUserId else { return }
        
        do {
            // Start the workout (change status to active)
            try await databaseService.startLiveWorkout(sessionId: sessionId)
            
            // Small delay to ensure status propagates
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            await startLiveWorkout()
        } catch {
            print("Error starting workout: \(error)")
        }
    }
    
    private func startLiveWorkout() async {
        guard let currentUserId = currentUserId else { return }
        
        liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: currentUserId)
        
        // Small delay before showing workout
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        showingLiveWorkout = true
    }
    
    private func startCountdownTimer() {
        timer?.invalidate()
        
        // Calculate remaining time based on invite timestamp (2 minutes from invite time)
        let expirationTime: TimeInterval
        if let inviteTimestamp = inviteTimestamp {
            expirationTime = inviteTimestamp + 120 // 2 minutes from invite
        } else {
            // Fallback: if no invite timestamp, use current time (shouldn't happen normally)
            expirationTime = Date().timeIntervalSince1970 + 120
        }
        
        let updateTimer = {
            let now = Date().timeIntervalSince1970
            let remaining = max(0, Int(expirationTime - now))
            
            Task { @MainActor in
                self.timeRemaining = remaining
                
                if remaining <= 0 {
                    self.timer?.invalidate()
                    // Session expired - dismiss waiting room
                    self.dismiss()
                }
            }
        }
        
        // Update immediately
        updateTimer()
        
        // Then update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimer()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func cleanup() {
        if let handle = sessionHandle {
            Database.database().reference().child("liveWorkouts").child(sessionId).removeObserver(withHandle: handle)
            sessionHandle = nil
        }
        timer?.invalidate()
        timer = nil
    }
}
