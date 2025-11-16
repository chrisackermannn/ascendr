# Firebase Realtime Database Setup for Ascendr

## Database URL
Your Firebase Realtime Database is located at:
**https://ascendr-4ee66-default-rtdb.firebaseio.com/**

## What's Been Implemented

### ✅ Authentication
- Firebase Authentication with email/password
- User sign up and sign in
- Automatic user data creation in Realtime Database

### ✅ User Management
- Users are stored in Realtime Database under `/users/{userId}`
- Each user has:
  - Basic info (id, email, username)
  - Profile data (profileImageURL, bio)
  - Statistics (workoutCount, totalWorkoutTime)
  - Complete workout history nested under `/users/{userId}/workouts/`

### ✅ Database Structure
```
users/
└── {userId}/
    ├── id
    ├── email
    ├── username
    ├── profileImageURL (optional)
    ├── bio (optional)
    ├── createdAtTimestamp
    ├── workoutCount
    ├── totalWorkoutTime
    └── workouts/
        └── {workoutId}/
            ├── id
            ├── userId
            ├── userName
            ├── dateTimestamp
            ├── duration
            ├── partnerId (optional)
            ├── partnerName (optional)
            └── exercises/
                └── {exerciseId}/
                    ├── id
                    ├── name
                    └── sets/
                        └── {setId}/
                            ├── id
                            ├── reps
                            ├── weight
                            └── restTime
```

## Test User

**Email:** test@ascendr.com  
**Password:** test123  
**Username:** TestUser

### Creating the Test User

1. **Through the App (Easiest):**
   - Run the app
   - Tap "Sign Up" on the login screen
   - Enter the credentials above
   - Tap "Create Account"
   - The user will be automatically created

2. **Through Firebase Console:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select project: `ascendr-4ee66`
   - Navigate to **Authentication** → **Users** → **Add User**
   - Enter email and password
   - The user data will be created in Realtime Database on first login

## Required Firebase Packages

Make sure these packages are added via Swift Package Manager:
- `FirebaseCore`
- `FirebaseAuth`
- `FirebaseDatabase`

Add them via: File → Add Packages... → `https://github.com/firebase/firebase-ios-sdk`

## Firebase Configuration

1. **Download `GoogleService-Info.plist`** from Firebase Console
2. **Add it to your Xcode project** (drag into project navigator)
3. Make sure it's added to the target

## Database Security Rules

Update your Realtime Database rules in Firebase Console:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null",
        "workouts": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid || auth != null"
        },
        "templates": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid || auth != null"
        }
      }
    },
    "posts": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

## Features

### User Profile
- View complete user information
- See workout history
- View statistics (total workouts, total time)
- Update profile image and bio

### Workout Tracking
- All workouts are saved to `/users/{userId}/workouts/`
- Workout statistics are automatically updated
- Partner workouts are synced to both users

### Data Organization
- Each user's data is self-contained under their userId
- Easy to fetch all user info and workout history
- Perfect structure for future features like:
  - Viewing other users' profiles
  - Social features
  - Leaderboards
  - Workout sharing

## Next Steps

1. **Enable Authentication in Firebase Console:**
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"

2. **Set up Database Rules:**
   - Go to Realtime Database → Rules
   - Paste the rules above

3. **Create Test User:**
   - Use the app to sign up with test credentials
   - Or create manually in Firebase Console

4. **Test the App:**
   - Sign in with test user
   - Create a workout
   - Check Realtime Database to see the data structure

## Notes

- All timestamps are stored as Unix timestamps (seconds since 1970)
- User data is automatically created on sign up
- Workout history is nested under each user for easy access
- The structure allows for easy expansion (posts, comments, etc.)

