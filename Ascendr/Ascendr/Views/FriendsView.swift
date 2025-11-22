//
//  FriendsView.swift
//  Ascendr
//
//  Friends view with search and friend requests
//

import SwiftUI
import FirebaseDatabase

struct FriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0 = Friends, 1 = Requests, 2 = Search
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    friendsList
                } else if selectedTab == 1 {
                    friendRequestsList
                } else {
                    searchView
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await friendsViewModel.fetchFriends(userId: userId)
                        await friendsViewModel.fetchFriendRequests(userId: userId)
                    }
                }
            }
            .onDisappear {
                friendsViewModel.cleanup()
            }
        }
    }
    
    // MARK: - Friends List
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if friendsViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if friendsViewModel.friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No friends yet")
                            .font(.headline)
                        Text("Search for users to add friends!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(friendsViewModel.friends) { friend in
                        FriendRowView(
                            user: friend,
                            status: friendsViewModel.getStatus(for: friend.id),
                            onRemove: {
                                if let userId = authViewModel.currentUser?.id {
                                    Task {
                                        await friendsViewModel.removeFriend(userId: userId, friendId: friend.id)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Friend Requests List
    private var friendRequestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if friendsViewModel.friendRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No pending requests")
                            .font(.headline)
                    }
                    .padding()
                } else {
                    ForEach(friendsViewModel.friendRequests) { request in
                        FriendRequestRowView(
                            request: request,
                            onAccept: {
                                if let userId = authViewModel.currentUser?.id {
                                    Task {
                                        await friendsViewModel.acceptFriendRequest(from: request.fromUserId, to: userId)
                                    }
                                }
                            },
                            onReject: {
                                if let userId = authViewModel.currentUser?.id {
                                    Task {
                                        await friendsViewModel.rejectFriendRequest(from: request.fromUserId, to: userId)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search View
    private var searchView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by username...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { oldValue, newValue in
                        if let userId = authViewModel.currentUser?.id {
                            Task {
                                await friendsViewModel.searchUsers(query: newValue, currentUserId: userId)
                            }
                        }
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            // Search results
            ScrollView {
                LazyVStack(spacing: 12) {
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Search for users")
                                .font(.headline)
                            Text("Enter a username to find friends")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if friendsViewModel.searchResults.isEmpty {
                        Text("No users found")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(friendsViewModel.searchResults) { user in
                            SearchResultRowView(
                                user: user,
                                isFriend: friendsViewModel.friends.contains { $0.id == user.id },
                                onAddFriend: {
                                    if let userId = authViewModel.currentUser?.id {
                                        Task {
                                            await friendsViewModel.sendFriendRequest(from: userId, to: user.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let user: User
    let status: UserStatus?
    let onRemove: () -> Void
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingRemoveAlert = false
    @State private var showingInviteWorkout = false
    @State private var inviteSent = false
    @State private var showingUserProfile = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image with online indicator (clickable)
            Button(action: {
                showingUserProfile = true
            }) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(user.username.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    // Online indicator
                    if let status = status, status.status {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showingUserProfile = true
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let status = status {
                        Text(status.status ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(status.status ? .green : .secondary)
                    } else {
                        Text("Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Invite to workout button
                if inviteSent {
                    Label("Invited", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        showingInviteWorkout = true
                    }) {
                        Image(systemName: "figure.run")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: {
                    showingRemoveAlert = true
                }) {
                    Image(systemName: "person.badge.minus")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("Remove Friend", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("Are you sure you want to remove \(user.username) from your friends list?")
        }
        .sheet(isPresented: $showingInviteWorkout) {
            if let currentUserId = authViewModel.currentUser?.id {
                InviteWorkoutView(
                    friendId: user.id,
                    friendName: user.username,
                    currentUserId: currentUserId,
                    onInviteSent: {
                        inviteSent = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            NavigationView {
                UserProfileView(userId: user.id)
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - Invite Workout View
struct InviteWorkoutView: View {
    let friendId: String
    let friendName: String
    let currentUserId: String
    let onInviteSent: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isSending = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Invite \(friendName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Send a live workout invite to \(friendName). They'll be able to join and workout together in real-time!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: sendInvite) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Invite")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSending ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isSending)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Live Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendInvite() {
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                let databaseService = RealtimeDatabaseService()
                if let currentUser = try? await databaseService.fetchUser(userId: currentUserId) {
                    _ = try await databaseService.sendLiveWorkoutInvite(
                        from: currentUserId,
                        fromUserName: currentUser.username,
                        to: friendId
                    )
                    await MainActor.run {
                        onInviteSent()
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to get user info"
                        isSending = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

// MARK: - Live Workout Session Listener
// Helper to listen for when a session is created after sending invite
extension FriendsViewModel {
    func listenForSessionCreation(fromUserId: String, completion: @escaping (String?) -> Void) -> DatabaseHandle {
        let databaseService = RealtimeDatabaseService()
        // Listen for when the invitee accepts and creates a session
        // We'll check liveWorkouts for sessions where userId1 matches fromUserId
        let sessionsRef = Database.database().reference().child("liveWorkouts")
        
        return sessionsRef.queryOrdered(byChild: "userId1")
            .queryEqual(toValue: fromUserId)
            .observe(.childAdded) { snapshot in
                if let sessionData = snapshot.value as? [String: Any],
                   let status = sessionData["status"] as? String,
                   status == "active",
                   let sessionId = sessionData["sessionId"] as? String {
                    completion(sessionId)
                }
            }
    }
}

// MARK: - Friend Request Row View
struct FriendRequestRowView: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var fromUser: User?
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: fromUser?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text((fromUser?.username ?? "U").prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fromUser?.username ?? "Loading...")
                    .font(.headline)
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            Task {
                let databaseService = RealtimeDatabaseService()
                fromUser = try? await databaseService.fetchUser(userId: request.fromUserId)
            }
        }
    }
}

// MARK: - Search Result Row View
struct SearchResultRowView: View {
    let user: User
    let isFriend: Bool
    let onAddFriend: () -> Void
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(user.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isFriend {
                Label("Friends", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if requestSent {
                Text("Sent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button(action: {
                    onAddFriend()
                    requestSent = true
                }) {
                    Text("Add")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

