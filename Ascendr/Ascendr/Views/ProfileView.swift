//
//  ProfileView.swift
//  Ascendr
//
//  Modern Profile view matching detailed design spec
//

import SwiftUI
import HealthKit

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var rewardViewModel = RewardViewModel()
    @State private var selectedWorkout: Workout?
    @State private var showingSettings = false
    @State private var showingProgressVault = false
    @State private var showingBadges = false
    @State private var progressPhotoCount = 0
    @State private var weeklyCalories: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full screen background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Status bar area
                        statusBarArea
                            .padding(.top, 8)
                            .padding(.horizontal, 20)
                        
                        // Profile Header Section
                        profileHeaderSection
                            .padding(.horizontal, 20)
                        
                        // Statistics Section
                        statisticsSection
                            .padding(.horizontal, 20)
                        
                        // Trainings Section
                        trainingsSection
                            .padding(.horizontal, 20)
                        
                        // Progress Photos Section
                        progressPhotosSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(appSettings)
                    .environmentObject(healthKitManager)
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
                    .environmentObject(profileViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingBadges) {
                BadgesView()
                    .environmentObject(rewardViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingProgressVault) {
                ProgressPhotoVaultView()
                    .environmentObject(appSettings)
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await profileViewModel.fetchUserData(userId: userId)
                        await rewardViewModel.loadUserRewards(userId: userId)
                    }
                }
                updateProgressPhotoCount()
                fetchWeeklyCalories()
                // Refresh HealthKit data
                healthKitManager.fetchCaloriesToday()
            }
            .onChange(of: healthKitManager.activeEnergy) { oldValue, newValue in
                // Update weekly calories when HealthKit data changes
                fetchWeeklyCalories()
            }
            .onChange(of: showingProgressVault) { oldValue, newValue in
                if !newValue {
                    updateProgressPhotoCount()
                }
            }
        }
    }
    
    // MARK: - Background Gradient (matching home screen)
    private var backgroundGradient: some View {
        appSettings.homeGradient
    }
    
    // MARK: - Status Bar Area
    private var statusBarArea: some View {
        HStack {
            Spacer()
            
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(appSettings.primaryText)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 18) {
                // Avatar with liquid glass border
                AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(appSettings.secondaryText.opacity(0.5))
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                
                // Name & Stats
                VStack(alignment: .leading, spacing: 10) {
                    Text(authViewModel.currentUser?.username ?? "User")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(appSettings.primaryText)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profileViewModel.workouts.count)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(appSettings.primaryText)
                            Text("workouts")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(appSettings.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(rewardViewModel.badges.count)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(appSettings.primaryText)
                            Text("badges")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(appSettings.secondaryText)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Level Row
            levelRow
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: profileViewModel.workouts.count)
    }
    
    // MARK: - Level Row
    private var levelRow: some View {
        HStack(spacing: 8) {
            // Level icon
            ZStack {
                Circle()
                    .fill(appSettings.accentColor.opacity(0.2))
                    .frame(width: 20, height: 20)
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(appSettings.accentColor)
            }
            
            Text(getLevelName())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(appSettings.primaryText)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(appSettings.secondaryBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(appSettings.buttonGradient)
                        .frame(
                            width: geometry.size.width * getLevelProgress(),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            
            Text("\(rewardViewModel.currentXP) XP")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(appSettings.secondaryText)
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Statistics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(appSettings.primaryText)
                    Text("This week")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(appSettings.secondaryText)
                }
                
                Spacer()
            }
            
            // Stats card without box
            statsCard
        }
    }
    
    // MARK: - Stats Card
    private var statsCard: some View {
        HStack(spacing: 24) {
            // Left column - Numbers
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CALORIES")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appSettings.secondaryText)
                        .textCase(.uppercase)
                    Text(formatCalories(Int(weeklyCalories)))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(appSettings.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appSettings.secondaryText)
                    Text(formatDuration(getWeeklyTime()))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(appSettings.primaryText)
                }
            }
            
            Spacer()
            
            // Right column - Bar chart
            weeklyBarChart
        }
    }
    
    // MARK: - Weekly Bar Chart
    private var weeklyBarChart: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(appSettings.buttonGradient)
                            .frame(width: 8, height: CGFloat(getBarHeight(for: day)))
                        
                        Text(getDayLabel(day))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(appSettings.secondaryText)
                    }
                }
            }
        }
        .frame(width: 120)
    }
    
    // MARK: - Trainings Section
    private var trainingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Trainings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(appSettings.primaryText)
                
                Spacer()
            }
            
            // Training list
            if profileViewModel.workouts.isEmpty {
                Text("No workouts yet")
                    .font(.system(size: 15))
                    .foregroundColor(appSettings.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(profileViewModel.workouts.prefix(5)) { workout in
                            TrainingListItem(workout: workout) {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                selectedWorkout = workout
                            }
                            .environmentObject(appSettings)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progressPhotoCount)
    }
    
    // MARK: - Progress Photos Section
    private var progressPhotosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Progress Photos")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(appSettings.primaryText)
                
                Spacer()
                
                Button("Show all") {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingProgressVault = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(appSettings.accentColor)
            }
            
            // Photo thumbnails - show from local storage
            if progressPhotoCount == 0 {
                Text("No photos yet")
                    .font(.system(size: 15))
                    .foregroundColor(appSettings.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(getProgressPhotoThumbnails().prefix(5).enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .onTapGesture {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    showingProgressVault = true
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Helper Functions
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
    
    private func getLevelName() -> String {
        let xp = rewardViewModel.currentXP
        if xp < 500 { return "Beginner" }
        if xp < 2000 { return "Intermediate" }
        if xp < 5000 { return "Advanced" }
        return "Expert"
    }
    
    private func getLevelProgress() -> CGFloat {
        let xp = rewardViewModel.currentXP
        if xp < 500 { return CGFloat(xp) / 500.0 }
        if xp < 2000 { return CGFloat(xp - 500) / 1500.0 }
        if xp < 5000 { return CGFloat(xp - 2000) / 3000.0 }
        return 1.0
    }
    
    private func getProgressPhotoThumbnails() -> [UIImage] {
        let photoStorage = LocalPhotoStorage.shared
        let photoFilenames = photoStorage.getAllPhotoFilenames()
        var images: [UIImage] = []
        
        for filename in photoFilenames.prefix(5) {
            if let image = photoStorage.loadPhoto(filename: filename) {
                images.append(image)
            }
        }
        
        return images
    }
    
    private func getWeeklyTime() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weeklyWorkouts = profileViewModel.workouts.filter { workout in
            workout.date >= weekAgo
        }
        
        return weeklyWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    private func formatCalories(_ calories: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: calories)) ?? "0") kcal"
    }
    
    private func fetchWeeklyCalories() {
        // Fetch calories from HealthKit for this week
        guard healthKitManager.isAuthorized else {
            weeklyCalories = 0
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        Task {
            // Query HealthKit for weekly active energy
            let healthStore = HKHealthStore()
            guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                weeklyCalories = 0
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: energyType,
                                        quantitySamplePredicate: predicate,
                                        options: .cumulativeSum) { _, result, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching weekly calories: \(error.localizedDescription)")
                        // Fallback to today's calories * 7
                        weeklyCalories = healthKitManager.activeEnergy * 7
                    } else if let sum = result?.sumQuantity() {
                        weeklyCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                    } else {
                        // Fallback to today's calories * 7
                        weeklyCalories = healthKitManager.activeEnergy * 7
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getBarHeight(for day: Int) -> Int {
        // Get workout count for each day of the week
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromToday = (day - weekday + 1 + 7) % 7
        
        guard let targetDate = calendar.date(byAdding: .day, value: daysFromToday, to: now) else {
            return 0
        }
        
        let workoutsOnDay = profileViewModel.workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: targetDate)
        }
        
        // Scale to max height of 60
        return min(workoutsOnDay.count * 15, 60)
    }
    
    private func getDayLabel(_ day: Int) -> String {
        let labels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        return labels[day]
    }
    
    private func updateProgressPhotoCount() {
        progressPhotoCount = LocalPhotoStorage.shared.getPhotoCount()
    }
}

// MARK: - Training List Item
struct TrainingListItem: View {
    let workout: Workout
    let action: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Thumbnail with liquid glass
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(appSettings.accentColor)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                
                // Title & date
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.exercises.first?.name ?? "Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(appSettings.primaryText)
                        .lineLimit(1)
                    
                    Text(relativeDateString(from: workout.date))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(appSettings.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appSettings.secondaryText.opacity(0.5))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysAgo < 7 {
                return "\(daysAgo) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Workout Detail View (kept from original)
struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var offset: CGFloat = 0
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                HStack {
                    Spacer()
                    Button(action: { showingDeleteConfirmation = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                            Text("Delete")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.red)
                        .clipShape(Circle())
                    }
                    .opacity(offset < -50 ? 1 : 0)
                    .offset(x: offset < -50 ? 0 : 100)
                    .padding(.trailing, 20)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workout.date, style: .date)
                                .font(.system(size: 18, weight: .bold))
                            
                            if workout.duration > 0 {
                                Text("Duration: \(formatDuration(workout.duration))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let partnerName = workout.partnerName {
                                Label("Partner: \(partnerName)", systemImage: "person.2.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(12)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Exercises")
                                .font(.headline)
                                .padding(.horizontal, 12)
                            
                            ForEach(workout.exercises) { exercise in
                                ExerciseDetailCard(exercise: exercise)
                            }
                        }
                    }
                    .offset(x: offset)
                }
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -100 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = -120
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        }
                )
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await profileViewModel.deleteWorkout(workout, userId: userId)
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                    }
                }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exercise: Exercise
    @EnvironmentObject var appSettings: AppSettings
    
    private var isBodyweightOrCardio: Bool {
        guard let equipment = exercise.equipment else { return false }
        return equipment == .bodyweight || exercise.category == .cardio
    }
    
    private var isCardio: Bool {
        exercise.category == .cardio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                if let equipment = exercise.equipment {
                    Text(equipment.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if isCardio {
                                if set.weight > 0 {
                                    Text("\(Int(set.weight)) min")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(set.reps) reps")
                                        .foregroundColor(.secondary)
                                }
                            } else if isBodyweightOrCardio {
                                Text("\(set.reps) reps")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(set.reps) × \(set.weight, specifier: "%.1f") lbs")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }
}
