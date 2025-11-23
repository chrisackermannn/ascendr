//
//  FriendsViewForMessaging.swift
//  Ascendr
//
//  Friends view for selecting a user to message
//

import SwiftUI

struct FriendsViewForMessaging: View {
    let onUserSelected: (User) -> Void
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return friendsViewModel.friends
        } else {
            return friendsViewModel.friends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                appSettings.primaryBackground
                    .ignoresSafeArea()
                
                if friendsViewModel.isLoading {
                    ProgressView("Loading friends...")
                        .foregroundColor(appSettings.primaryText)
                } else if filteredFriends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(appSettings.secondaryText)
                        Text(searchText.isEmpty ? "No Friends" : "No Results")
                            .font(.headline)
                            .foregroundColor(appSettings.primaryText)
                        Text(searchText.isEmpty ? "Add friends to start messaging!" : "Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(appSettings.secondaryText)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                Button(action: {
                                    onUserSelected(friend)
                                }) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
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
                                        
                                        Text(friend.username)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(appSettings.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(appSettings.secondaryText)
                                            .font(.caption)
                                    }
                                    .padding(12)
                                    .background(appSettings.cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search friends...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(appSettings.accentColor)
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await friendsViewModel.fetchFriends(userId: userId)
                    }
                }
            }
        }
    }
}

