//
//  MessagesView.swift
//  Ascendr
//
//  Messages/conversations list view
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var showingFriendsSearch = false
    @State private var selectedUser: User?
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                if messagingViewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 48))
                            .foregroundColor(appSettings.secondaryText)
                        Text("No Messages")
                            .font(.headline)
                            .foregroundColor(appSettings.primaryText)
                        Text("Start a conversation with a friend!")
                            .font(.subheadline)
                            .foregroundColor(appSettings.secondaryText)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messagingViewModel.conversations) { conversation in
                                ConversationRow(conversation: conversation)
                                    .onTapGesture {
                                        selectedUser = conversation.otherUser
                                    }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Messages")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(appSettings.primaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFriendsSearch = true
                    }) {
                        Image(systemName: "plus.message.fill")
                            .foregroundColor(appSettings.accentColor)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await messagingViewModel.loadConversations(userId: userId)
                    }
                    messagingViewModel.startListeningForConversations(userId: userId)
                }
            }
            .onDisappear {
                messagingViewModel.stopListeningForConversations()
            }
            .sheet(item: $selectedUser) { user in
                ChatView(otherUser: user)
                    .environmentObject(messagingViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(appSettings)
            }
            .sheet(isPresented: $showingFriendsSearch) {
                FriendsViewForMessaging(onUserSelected: { user in
                    selectedUser = user
                    showingFriendsSearch = false
                })
                .environmentObject(friendsViewModel)
                .environmentObject(authViewModel)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            AsyncImage(url: URL(string: conversation.otherUser.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(appSettings.secondaryBackground)
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(appSettings.secondaryText)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUser.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(appSettings.primaryText)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundColor(appSettings.secondaryText)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundColor(appSettings.secondaryText)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessage = conversation.lastMessage {
                    Text(formatTime(lastMessage.timestamp))
                        .font(.caption)
                        .foregroundColor(appSettings.secondaryText)
                }
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appSettings.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(appSettings.cardBackground)
        .cornerRadius(12)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "M/d/yy"
        }
        
        return formatter.string(from: date)
    }
}

