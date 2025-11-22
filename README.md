# Ascendr - iOS Gym App

A modern, simplistic iOS gym app built with SwiftUI and Firebase.

## Features

- **Authentication**: Secure user login and signup with Firebase Authentication
- **Social Feed**: View and post workouts and progress pictures
- **Workout Tracking**: Start workouts, add exercises and sets
- **Partner Workouts**: Real-time collaborative workouts with friends
- **Profile Management**: View workout history, progress pics, and update profile

## Project Structure

```
Ascendr/
├── AscendrApp.swift          # App entry point
├── ContentView.swift          # Main content view with auth state
├── Models/
│   ├── User.swift            # User model
│   ├── Workout.swift         # Workout, Exercise, Set models
│   └── Post.swift            # Post model for feed
├── Services/
│   ├── AuthenticationService.swift  # Firebase Auth service
│   ├── FirestoreService.swift       # Firestore database service
│   └── StorageService.swift         # Firebase Storage for images
├── ViewModels/
│   ├── AuthenticationViewModel.swift
│   ├── FeedViewModel.swift
│   ├── WorkoutViewModel.swift
│   └── ProfileViewModel.swift
├── Views/
│   ├── MainTabView.swift     # Tab navigation
│   ├── AuthenticationView.swift
│   ├── FeedView.swift
│   ├── WorkoutView.swift
│   └── ProfileView.swift
└── Info.plist                # Privacy permissions
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new iOS App project
3. Choose SwiftUI as the interface
4. Name it "Ascendr"
5. Copy all the files from this structure into your Xcode project

### 2. Install Firebase

1. Add Firebase SDK via Swift Package Manager:
   - File → Add Packages...
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Select these products (check all boxes):
     - ✅ FirebaseCore
     - ✅ FirebaseAuth
     - ✅ FirebaseDatabase
     - ✅ FirebaseStorage ⚠️ **Required for profile pictures**
   
   **Note:** If you get "Unable to find module dependency: 'FirebaseStorage'", see `ADD_FIREBASE_STORAGE.md` for detailed instructions.

### 3. Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing
3. Add an iOS app to your project
4. Download `GoogleService-Info.plist`
5. Add `GoogleService-Info.plist` to your Xcode project root

### 4. Enable Firebase Services

In Firebase Console:
- **Authentication**: Enable Email/Password sign-in method
- **Firestore Database**: Create database in test mode (or set up security rules)
- **Storage**: Enable Firebase Storage

### 5. Firestore Security Rules (Development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. Storage Security Rules (Development)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Key Features Implementation

### Authentication
- Email/password authentication via Firebase Auth
- Automatic session persistence
- User data stored in Firestore

### Feed
- Real-time feed of workout and progress pic posts
- Like functionality
- Pull-to-refresh

### Workout Tracking
- Start individual or partner workouts
- Add exercises and sets in real-time
- Partner workouts sync via Firestore listeners
- Workout duration tracking

### Profile
- View workout history
- Progress pic gallery
- Profile picture upload
- User statistics

## Next Steps for Enhancement

1. **Push Notifications**: Add Firebase Cloud Messaging for partner workout invites
2. **Search**: Add user search for finding workout partners
3. **Workout Templates**: Pre-defined workout routines
4. **Analytics**: Track progress over time with charts
5. **Social Features**: Comments, shares, follow system
6. **Workout Sharing**: Share workouts to feed after completion
7. **Progress Tracking**: Body measurements, weight tracking
8. **Achievements**: Badges and milestones

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Firebase iOS SDK

## Notes

- This is a basic outline structure. You'll need to:
  - Add proper error handling
  - Implement image compression
  - Add loading states
  - Style the UI further
  - Add animations
  - Implement proper partner workout session management
  - Add validation for inputs
