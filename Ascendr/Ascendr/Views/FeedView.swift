//
//  FeedView.swift
//  Ascendr
//
//  Feed view showing workout and progress pic posts
//

import SwiftUI
import FirebaseDatabase

struct FeedView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var liveWorkoutViewModel = LiveWorkoutViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    @State private var showingFriendsSearch = false
    @State private var showingMessages = false
    @State private var showingLiveWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if feedViewModel.isLoading {
                        ProgressView("Loading posts...")
                            .padding(12)
                    } else if let errorMessage = feedViewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("Error loading feed")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await feedViewModel.fetchPosts()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                        }
                        .padding(12)
                    } else if feedViewModel.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No posts yet")
                                .font(.headline)
                            Text("Be the first to share a workout!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                    } else {
                        ForEach(feedViewModel.posts) { post in
                            PostCardView(post: post)
                                .environmentObject(feedViewModel)
                                .environmentObject(authViewModel)
                        }
                    }
                }
                .padding(12)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ascendr")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(
                            appSettings.buttonGradient
                        )
                        .allowsHitTesting(false)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFriendsSearch = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(appSettings.primaryText)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMessages = true
                    }) {
                        ZStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(appSettings.primaryText)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            if messagingViewModel.totalUnreadCount > 0 {
                                Text("\(messagingViewModel.totalUnreadCount > 99 ? "99+" : "\(messagingViewModel.totalUnreadCount)")")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .padding(.horizontal, messagingViewModel.totalUnreadCount > 9 ? 5 : 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        ZStack {
                                            Color.red
                                            LinearGradient(
                                                colors: [Color.red, Color(red: 0.9, green: 0, blue: 0)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        }
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 2)
                                    .position(x: 20, y: 4)
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                }
            }
            .refreshable {
                await feedViewModel.fetchPosts()
            }
            .onAppear {
                if feedViewModel.posts.isEmpty && !feedViewModel.isLoading {
                    Task {
                        await feedViewModel.fetchPosts()
                    }
                }
                
                // Start listening for live workout invites
                if let userId = authViewModel.currentUser?.id {
                    friendsViewModel.startListeningForInvites(userId: userId)
                    
                    // Load conversations and start listening for unread messages
                    Task {
                        await messagingViewModel.loadConversations(userId: userId)
                    }
                    messagingViewModel.startListeningForConversations(userId: userId)
                }
            }
            .onChange(of: friendsViewModel.pendingSessionId) { oldValue, newValue in
                if let sessionId = newValue, let userId = authViewModel.currentUser?.id {
                    liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: userId)
                    showingLiveWorkout = true
                    friendsViewModel.pendingSessionId = nil
                }
            }
            .onDisappear {
                if let userId = authViewModel.currentUser?.id {
                    friendsViewModel.stopListeningForInvites(userId: userId)
                }
                messagingViewModel.stopListeningForConversations()
            }
            .alert("Live Workout Invite", isPresented: Binding(
                get: { friendsViewModel.liveWorkoutInvite != nil },
                set: { if !$0 { friendsViewModel.liveWorkoutInvite = nil } }
            )) {
                Button("Decline") {
                    if let invite = friendsViewModel.liveWorkoutInvite {
                        Task {
                            let databaseService = RealtimeDatabaseService()
                            try? await databaseService.rejectLiveWorkoutInvite(inviteId: invite.inviteId, toUserId: invite.toUserId)
                        }
                    }
                    friendsViewModel.liveWorkoutInvite = nil
                }
                Button("Accept") {
                    if let invite = friendsViewModel.liveWorkoutInvite,
                       let userId = authViewModel.currentUser?.id,
                       let userName = authViewModel.currentUser?.username {
                        Task {
                            await acceptLiveWorkoutInvite(invite: invite, userId: userId, userName: userName)
                        }
                    }
                }
            } message: {
                if let invite = friendsViewModel.liveWorkoutInvite {
                    Text("\(invite.fromUserName) wants to start a live workout with you!")
                }
            }
            .sheet(isPresented: $showingFriendsSearch) {
                FriendsView()
                    .environmentObject(friendsViewModel)
            }
            .sheet(isPresented: $showingMessages) {
                MessagesView()
                    .environmentObject(authViewModel)
                    .environmentObject(messagingViewModel)
            }
            .fullScreenCover(isPresented: $showingLiveWorkout) {
                LiveWorkoutView()
                    .environmentObject(liveWorkoutViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(AppSettings.shared)
            }
        }
    }
    
    private func acceptLiveWorkoutInvite(invite: LiveWorkoutInvite, userId: String, userName: String) async {
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
                
                await MainActor.run {
                    friendsViewModel.liveWorkoutInvite = nil
                    liveWorkoutViewModel.startLiveWorkout(sessionId: sessionId, currentUserId: userId)
                    showingLiveWorkout = true
                }
            }
        } catch {
            print("Error accepting invite: \(error)")
        }
    }
}

struct PostCardView: View {
    let post: Post
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingCopySuccess = false
    @State private var showingTemplateNameInput = false
    @State private var templateName = ""
    @State private var userStatus: UserStatus?
    @State private var showingUserProfile = false
    
    var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // User info (clickable) - Enhanced
            Button(action: {
                showingUserProfile = true
            }) {
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: post.userProfileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(appSettings.borderColor, lineWidth: 1.5)
                        )
                        
                        // Online indicator
                        if let status = userStatus, status.status {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(appSettings.cardBackground, lineWidth: 2.5)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.userName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(post.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .onAppear {
                Task {
                    let databaseService = RealtimeDatabaseService()
                    userStatus = try? await databaseService.getUserStatus(userId: post.userId)
                }
            }
            .sheet(isPresented: $showingUserProfile) {
                NavigationView {
                    UserProfileView(userId: post.userId)
                        .environmentObject(authViewModel)
                }
            }
            
            // Content
            if let content = post.content {
                Text(content)
                    .font(.body)
            }
            
            // Progress Pic
            if let picURL = post.progressPicURL {
                AsyncImage(url: URL(string: picURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                }
                .cornerRadius(10)
            }
            
            // Workout Summary
            if let workout = post.workout {
                WorkoutSummaryView(workout: workout)
            }
            
            // Actions
            HStack {
                Button(action: {
                    if let userId = authViewModel.currentUser?.id {
                        Task {
                            await feedViewModel.likePost(post, userId: userId)
                        }
                    }
                }) {
                        HStack {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .primary : .secondary)
                            Text("\(post.likes.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                }
                
                Spacer()
                
                // Copy Template button (only show if post has a workout)
                if post.workout != nil {
                    Button(action: {
                        templateName = "\(post.userName)'s Workout"
                        showingTemplateNameInput = true
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Template")
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [appSettings.accentColor.opacity(0.15), appSettings.accentColorSecondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: appSettings.accentColor.opacity(appSettings.isDarkMode ? 0.1 : 0.08), radius: 10, x: 0, y: 4)
        )
        .alert("Template Saved!", isPresented: $showingCopySuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The workout template has been saved to your templates. You can use it when starting a new workout!")
        }
        .sheet(isPresented: $showingTemplateNameInput) {
            TemplateNameInputView(
                templateName: $templateName,
                defaultName: "\(post.userName)'s Workout",
                onSave: {
                    if let userId = authViewModel.currentUser?.id {
                        Task {
                            do {
                                try await feedViewModel.copyTemplate(from: post, userId: userId, templateName: templateName.isEmpty ? "\(post.userName)'s Workout" : templateName)
                                showingTemplateNameInput = false
                                showingCopySuccess = true
                            } catch {
                                print("Error copying template: \(error)")
                            }
                        }
                    }
                }
            )
        }
    }
}

struct TemplateNameInputView: View {
    @Binding var templateName: String
    let defaultName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Template Name", text: $templateName, prompt: Text(defaultName))
                } header: {
                    Text("Name Your Template")
                } footer: {
                    Text("Give your template a memorable name so you can easily find it later.")
                }
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct WorkoutSummaryView: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Summary")
                .font(.headline)
            
            if let partnerName = workout.partnerName {
                Text("Partner: \(partnerName)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Text("\(workout.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if workout.duration > 0 {
                Text("Duration: \(formatDuration(workout.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

