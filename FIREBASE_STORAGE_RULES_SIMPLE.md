# Firebase Storage Rules - SIMPLE VERSION (Copy This!)

These are the SIMPLEST rules that will work. Copy and paste these into Firebase Console → Storage → Rules.

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images - EVERYONE can read, users can only write their own
    match /profileImages/{fileName} {
      // ALL authenticated users can read profile images
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

## Quick Setup:

1. Go to **Firebase Console** → **Storage** → **Rules** tab
2. **DELETE** all existing rules
3. **COPY** the rules above (everything between the ```javascript and ```)
4. **PASTE** into the rules editor
5. Click **"Publish"**
6. Wait a few seconds for rules to propagate

## What These Rules Do:

✅ **ALL authenticated users** can **READ** profile images (so they're visible everywhere)
✅ **Only the owner** can **WRITE** their own profile image
✅ File size limit: 5MB for profile pics, 10MB for progress pics
✅ Only JPEG images allowed

## If You Still Get Permission Errors:

1. Make sure you're **authenticated** (signed in)
2. Make sure the rules are **published** (clicked "Publish" button)
3. Wait 10-30 seconds after publishing for rules to propagate
4. Try uploading again

## Test the Rules:

After applying, you should be able to:
- ✅ Upload your own profile image
- ✅ See all profile images in the app
- ❌ Cannot upload profile images for other users

