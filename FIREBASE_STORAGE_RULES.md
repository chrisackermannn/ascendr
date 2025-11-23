# Firebase Storage Rules for Profile Images

These rules ensure that profile images are properly secured and accessible in Firebase Storage.

## Storage Rules

Add these rules to your Firebase Storage console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images - EVERYONE can read, users can only write their own
    match /profileImages/{fileName} {
      // ALL authenticated users can read profile images (so they're visible everywhere)
      allow read: if request.auth != null;
      
      // Users can only write their own profile image (filename must be their UID + .jpg)
      allow write: if request.auth != null && 
                      fileName == request.auth.uid + '.jpg' &&
                      request.resource.size < 5 * 1024 * 1024 &&
                      request.resource.contentType == 'image/jpeg';
    }
    
    // Progress pictures - EVERYONE can read, users can only write their own
    match /progressPics/{userId}/{postId} {
      // ALL authenticated users can read progress pictures
      allow read: if request.auth != null;
      
      // Users can only write to their own folder
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 10 * 1024 * 1024 &&
                      request.resource.contentType == 'image/jpeg';
    }
  }
}
```

## How to Apply These Rules

1. Go to your Firebase project console
2. Navigate to **Storage** in the left sidebar
3. Click on the **Rules** tab
4. Replace the existing rules with the rules above
5. Click **Publish**

## Rule Explanation

### Profile Images (`/profileImages/{userId}.jpg`)

- **Read**: Any authenticated user can read profile images (so they're visible in the app)
- **Write**: Only the user whose `userId` matches their `auth.uid` can upload/update/delete their own profile image
- **File Size**: Maximum 5MB per image
- **Content Type**: Only JPEG images are allowed

### Progress Pictures (`/progressPics/{userId}/{postId}.jpg`)

- **Read**: Any authenticated user can read progress pictures
- **Write**: Only the user whose `userId` matches their `auth.uid` can upload to their own folder
- **File Size**: Maximum 10MB per image (larger because progress pics might be higher quality)
- **Content Type**: Only JPEG images are allowed

## Testing

After applying these rules, test that:

1. ✅ Users can upload their own profile images
2. ✅ Users cannot upload profile images for other users
3. ✅ Profile images are visible to all authenticated users
4. ✅ File size limits are enforced
5. ✅ Only JPEG images are accepted

## Troubleshooting

If profile images aren't uploading:

1. **Check Firebase Storage is enabled**: Go to Firebase Console → Storage → Get Started
2. **Verify rules are published**: Make sure you clicked "Publish" after updating rules
3. **Check authentication**: Ensure the user is authenticated (`request.auth != null`)
4. **Verify file format**: Make sure images are JPEG format
5. **Check file size**: Ensure images are under 5MB for profile pics
6. **Check StorageService**: Verify `uploadProfileImage` is being called correctly

