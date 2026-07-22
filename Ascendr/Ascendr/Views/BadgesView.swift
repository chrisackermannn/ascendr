//
//  BadgesView.swift
//  Ascendr
//
//  Badges collection view
//

import SwiftUI

struct BadgesView: View {
    @EnvironmentObject var rewardViewModel: RewardViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: BadgeCategory? = nil
    
    private var filteredBadges: [Badge] {
        let badges = rewardViewModel.badges
        if let category = selectedCategory {
            return badges.filter { $0.category == category }
        }
        return badges
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        BadgeCategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(BadgeCategory.allCases, id: \.self) { category in
                            BadgeCategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                // Badges grid
                if filteredBadges.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "medal")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No badges yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Complete workouts and challenges to earn badges!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredBadges) { badge in
                                BadgeCard(badge: badge, isPinned: rewardViewModel.pinnedBadge?.id == badge.id)
                                    .onTapGesture {
                                        if rewardViewModel.pinnedBadge?.id == badge.id {
                                            Task {
                                                if let userId = authViewModel.currentUser?.id {
                                                    await rewardViewModel.unpinBadge(userId: userId)
                                                }
                                            }
                                        } else {
                                            Task {
                                                if let userId = authViewModel.currentUser?.id {
                                                    await rewardViewModel.pinBadge(badge, userId: userId)
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BadgeCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : appSettings.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            appSettings.buttonGradient
                        } else {
                            appSettings.secondaryBackground
                        }
                    }
                )
                .cornerRadius(16)
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    let isPinned: Bool
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                appSettings.accentColor.opacity(0.3),
                                appSettings.accentColorSecondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(appSettings.accentColor)
                
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 30, y: -30)
                }
            }
            
            Text(badge.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if let earnedDate = badge.earnedDate {
                Text(earnedDate, style: .date)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isPinned ? Color.red : Color.clear,
                            lineWidth: isPinned ? 2 : 0
                        )
                )
        )
    }
}

