# Firebase Realtime Database Rules for Messaging

Add these rules to your Firebase Realtime Database rules to enable messaging:

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
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
        },
        "friends": {
          ".read": "$uid === auth.uid || auth != null",
          ".write": "$uid === auth.uid || auth != null"
        }
      }
    },
    "posts": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "friendRequests": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null"
      }
    },
    "userStatus": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "liveWorkoutInvites": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null"
      }
    },
    "liveWorkouts": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "liveWorkoutNotifications": {
      "$uid": {
        ".read": "$uid === auth.uid || auth != null",
        ".write": "$uid === auth.uid || auth != null"
      }
    },
    "messages": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$messageId": {
        ".read": "auth != null",
        ".write": "auth != null && (data.child('senderId').val() === auth.uid || data.child('receiverId').val() === auth.uid)"
      }
    },
    "conversations": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$conversationId": {
        ".read": "auth != null && ($conversationId.contains(auth.uid))",
        ".write": "auth != null && ($conversationId.contains(auth.uid))"
      }
    }
  }
}
```

