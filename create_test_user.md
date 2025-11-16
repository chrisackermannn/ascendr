# Create Test User for Ascendr

## Test User Credentials

**Email:** test@ascendr.com  
**Password:** test123  
**Username:** TestUser

## How to Create the Test User

### Option 1: Through the App (Recommended)
1. Run the app in Xcode
2. On the login screen, tap "Sign Up"
3. Enter the credentials above
4. Tap "Create Account"
5. The user will be automatically created in Firebase Auth and Realtime Database

### Option 2: Through Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ascendr-4ee66`
3. Navigate to **Authentication** → **Users**
4. Click **Add User**
5. Enter:
   - Email: `test@ascendr.com`
   - Password: `test123`
6. Click **Add User**

### Option 3: Manual Database Entry (if needed)

If you need to manually add user data to Realtime Database, use this structure:

```json
{
  "users": {
    "USER_ID_FROM_FIREBASE_AUTH": {
      "id": "USER_ID_FROM_FIREBASE_AUTH",
      "email": "test@ascendr.com",
      "username": "TestUser",
      "createdAtTimestamp": 1700000000,
      "workoutCount": 0,
      "totalWorkoutTime": 0,
      "bio": "Test user for Ascendr app",
      "workouts": {}
    }
  }
}
```

## Database Structure

The Realtime Database is organized as follows:

```
ascendr-4ee66-default-rtdb/
└── users/
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

## Security Rules

Make sure your Realtime Database rules allow authenticated users to read/write:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null"
      }
    }
  }
}
```

## Notes

- The test user will be created automatically when signing up through the app
- User data is stored in both Firebase Authentication and Realtime Database
- Workout history is nested under each user for easy access
- All timestamps are stored as Unix timestamps (seconds since 1970)

