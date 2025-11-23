//
//  MessagingViewModel.swift
//  Ascendr
//
//  ViewModel for messaging system
//

import Foundation
import FirebaseDatabase
import Combine

@MainActor
class MessagingViewModel: ObservableObject {
    @Published var conversations: [Conversation] = [] {
        didSet {
            // Automatically update total unread count when conversations change
            totalUnreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
        }
    }
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isInitialLoad = true
    @Published var errorMessage: String?
    @Published var totalUnreadCount: Int = 0
    
    private let databaseService = RealtimeDatabaseService()
    nonisolated(unsafe) private var messageHandle: DatabaseHandle?
    nonisolated(unsafe) private var conversationsHandle: DatabaseHandle?
    nonisolated(unsafe) private var messagesListenerHandle: DatabaseHandle?
    private var currentUserId: String?
    private var currentOtherUserId: String?
    
    /// Load all conversations for the current user
    func loadConversations(userId: String) async {
        if isInitialLoad {
            isLoading = true
        }
        errorMessage = nil
        currentUserId = userId
        
        do {
            conversations = try await databaseService.fetchConversations(userId: userId)
            // totalUnreadCount is automatically updated via didSet
            isInitialLoad = false
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            isInitialLoad = false
        }
        
        isLoading = false
    }
    
    /// Start listening for conversations in real-time
    func startListeningForConversations(userId: String) {
        currentUserId = userId
        
        // Helper function to refresh conversations and update unread count
        let refreshConversations = { [weak self] in
            Task { @MainActor in
                guard let self = self, self.currentUserId == userId else { return }
                do {
                    let newConversations = try await self.databaseService.fetchConversations(userId: userId)
                    self.conversations = newConversations
                    // totalUnreadCount is automatically updated via didSet
                } catch {
                    // Silently fail
                }
            }
        }
        
        // Listen to conversations in real-time - this will update when messages are sent
        let conversationsRef = Database.database().reference().child("conversations")
        conversationsHandle = conversationsRef.observe(.value) { _ in
            refreshConversations()
        }
        
        // Also listen to messages to update unread count when messages are marked as read
        // Use a debounced approach to avoid multiple rapid refreshes
        let messagesRef = Database.database().reference().child("messages")
        var lastRefreshTime: Date = Date()
        messagesListenerHandle = messagesRef.observe(.value) { _ in
            let now = Date()
            // Debounce: only refresh if at least 0.5 seconds have passed since last refresh
            if now.timeIntervalSince(lastRefreshTime) > 0.5 {
                lastRefreshTime = now
                refreshConversations()
            }
        }
    }
    
    /// Stop listening for conversations
    nonisolated func stopListeningForConversations() {
        if let handle = conversationsHandle {
            Database.database().reference().removeObserver(withHandle: handle)
            conversationsHandle = nil
        }
        if let handle = messagesListenerHandle {
            Database.database().reference().removeObserver(withHandle: handle)
            messagesListenerHandle = nil
        }
        Task { @MainActor in
            currentUserId = nil
        }
    }
    
    /// Load messages between two users
    func loadMessages(userId1: String, userId2: String) async {
        isLoading = true
        errorMessage = nil
        currentUserId = userId1
        currentOtherUserId = userId2
        
        // Stop previous listener
        if let handle = messageHandle {
            Database.database().reference().removeObserver(withHandle: handle)
            messageHandle = nil
        }
        
        do {
            // Load initial messages
            let initialMessages = try await databaseService.fetchMessages(userId1: userId1, userId2: userId2)
            messages = initialMessages
            messages.sort { $0.timestamp < $1.timestamp }
            
            // Start real-time listener that will update messages as they come in
            messageHandle = databaseService.listenForMessages(userId1: userId1, userId2: userId2) { [weak self] newMessages in
                Task { @MainActor in
                    guard let self = self,
                          self.currentUserId == userId1,
                          self.currentOtherUserId == userId2 else { return }
                    
                    // Always use the latest from Firebase - this ensures persistence
                    // The real-time listener fires whenever ANY message changes in the database
                    // This means when we send a message, it will appear here immediately
                    self.messages = newMessages
                    self.messages.sort { $0.timestamp < $1.timestamp }
                }
            }
            
            // Mark messages as read
            try await databaseService.markMessagesAsRead(userId: userId1, otherUserId: userId2)
            
            // Refresh conversations to update unread count immediately
            if let currentUserId = currentUserId {
                do {
                    let updatedConversations = try await databaseService.fetchConversations(userId: currentUserId)
                    conversations = updatedConversations
                    // totalUnreadCount is automatically updated via didSet
                } catch {
                    // Silently fail
                }
            }
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Send a message
    func sendMessage(text: String, senderId: String, receiverId: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let message = Message(
            senderId: senderId,
            receiverId: receiverId,
            text: text.trimmingCharacters(in: .whitespaces)
        )
        
        let messageId = message.id
        
        // Add to local state immediately for instant feedback (optimistic update)
        if !messages.contains(where: { $0.id == messageId }) {
            messages.append(message)
            messages.sort { $0.timestamp < $1.timestamp }
        }
        
        // Save to Firebase
        do {
            try await databaseService.sendMessage(message)
            // The real-time listener will automatically fire and update messages
            // This ensures the message persists and both users see it
        } catch {
            // Remove from local state if send failed
            messages.removeAll { $0.id == messageId }
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    /// Stop listening for messages
    nonisolated func stopListeningForMessages() {
        if let handle = messageHandle {
            Database.database().reference().removeObserver(withHandle: handle)
            messageHandle = nil
        }
        Task { @MainActor in
            currentUserId = nil
            currentOtherUserId = nil
            messages = []
        }
    }
    
    deinit {
        if let handle = messageHandle {
            Database.database().reference().removeObserver(withHandle: handle)
        }
    }
}

