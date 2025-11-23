//
//  ChatView.swift
//  Ascendr
//
//  Individual chat view
//

import SwiftUI

struct ChatView: View {
    let otherUser: User
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                if messagingViewModel.messages.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(appSettings.secondaryText)
                                        Text("No messages yet")
                                            .font(.headline)
                                            .foregroundColor(appSettings.primaryText)
                                        Text("Start the conversation!")
                                            .font(.subheadline)
                                            .foregroundColor(appSettings.secondaryText)
                                    }
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(messagingViewModel.messages) { message in
                                        MessageBubble(message: message, isFromCurrentUser: message.senderId == authViewModel.currentUser?.id)
                                            .id(message.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .onChange(of: messagingViewModel.messages.count) { _, _ in
                            if let lastMessage = messagingViewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            if let lastMessage = messagingViewModel.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Message input - Enhanced design
                    HStack(spacing: 10) {
                        TextField("Type a message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(appSettings.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(appSettings.secondaryBackground)
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(appSettings.borderColor, lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                            .lineLimit(1...4)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? appSettings.secondaryText : appSettings.accentColor)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(appSettings.cardBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(appSettings.borderColor),
                        alignment: .top
                    )
                }
            }
            .navigationTitle(otherUser.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(appSettings.accentColor)
                }
            }
            .task {
                // Use .task instead of .onAppear to ensure it runs when view appears
                if let currentUserId = authViewModel.currentUser?.id {
                    await messagingViewModel.loadMessages(userId1: currentUserId, userId2: otherUser.id)
                    // Refresh conversations to update unread count after marking messages as read
                    // The real-time listener will also update automatically
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds for Firebase to update
                        await messagingViewModel.loadConversations(userId: currentUserId)
                    }
                }
            }
            .onDisappear {
                // Refresh conversations when leaving chat to ensure badge updates
                if let currentUserId = authViewModel.currentUser?.id {
                    Task {
                        await messagingViewModel.loadConversations(userId: currentUserId)
                    }
                }
            }
            .onDisappear {
                messagingViewModel.stopListeningForMessages()
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUserId = authViewModel.currentUser?.id,
              !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = messageText
        messageText = ""
        isTextFieldFocused = false
        
        Task {
            await messagingViewModel.sendMessage(
                text: text,
                senderId: currentUserId,
                receiverId: otherUser.id
            )
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(isFromCurrentUser ? .white : appSettings.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isFromCurrentUser {
                                appSettings.buttonGradient
                            } else {
                                appSettings.secondaryBackground
                            }
                        }
                    )
                    .cornerRadius(18)
                    .shadow(color: appSettings.shadowColor, radius: 2, x: 0, y: 1)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(appSettings.secondaryText)
                    .padding(.horizontal, 8)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "M/d h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

