//
//  FeedView.swift
//  Ascendr
//
//  Feed view showing workout and progress pic posts
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if feedViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if feedViewModel.posts.isEmpty {
                        Text("No posts yet. Be the first to share!")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(feedViewModel.posts) { post in
                            PostCardView(post: post)
                                .environmentObject(feedViewModel)
                                .environmentObject(authViewModel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .refreshable {
                await feedViewModel.fetchPosts()
            }
        }
    }
}

struct PostCardView: View {
    let post: Post
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack {
                AsyncImage(url: URL(string: post.userProfileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(post.userName)
                        .font(.headline)
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
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
                .cornerRadius(12)
            }
            
            // Workout Summary
            if let workout = post.workout {
                WorkoutSummaryView(workout: workout)
            }
            
            // Like button
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
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(post.likes.count)")
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                    .foregroundColor(.blue)
            }
            
            Text("\(workout.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

