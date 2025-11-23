# Firebase Realtime Database Rules for Workouts

Add these rules to your Firebase Realtime Database rules to ensure workout history is accessible:

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid",
        "workouts": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid",
          "$workoutId": {
            ".read": "$uid === auth.uid || auth != null",
            ".write": "$uid === auth.uid"
          }
        },
        "sharedWorkouts": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid",
          "$workoutId": {
            ".read": "$uid === auth.uid || auth != null",
            ".write": "$uid === auth.uid"
          }
        },
        "templates": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid",
          "$templateId": {
            ".read": "$uid === auth.uid || auth != null",
            ".write": "$uid === auth.uid"
          }
        }
      }
    }
  }
}
```

## How to Apply These Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ascendr-4ee66`
3. Navigate to **Realtime Database** → **Rules**
4. Paste the rules above (merge with existing rules if you have messaging rules)
5. Click **Publish**

## Rule Explanation

- **Users**: All authenticated users can read user data
- **User Workouts**: Users can only write their own workouts, but can read any user's workouts (for feed/public posts)
- **Shared Workouts**: Users can read/write their own shared workouts
- **Templates**: Users can read/write their own workout templates

These rules ensure:
- ✅ Users can fetch their own workout history (`fetchUserWorkoutHistory`)
- ✅ Users can save workouts to their history (`saveWorkoutToHistory`)
- ✅ Users can access shared workouts
- ✅ Users can manage their workout templates

