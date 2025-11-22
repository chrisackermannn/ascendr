# Fix FirebaseStorage Import Error

If you're still seeing "Unable to find module dependency: 'FirebaseStorage'" after adding the package, follow these steps:

## Step 1: Verify Package is Added

1. Open Xcode
2. Select your project (Ascendr) in the Project Navigator
3. Select the **Ascendr** target
4. Go to **"General"** tab
5. Scroll down to **"Frameworks, Libraries, and Embedded Content"**
6. Check if `FirebaseStorage` is listed there

## Step 2: If FirebaseStorage is NOT in Frameworks

1. Go to **"Package Dependencies"** tab
2. Find `firebase-ios-sdk` in the list
3. Click on it
4. In the right panel, make sure **FirebaseStorage** is checked
5. If it's not checked, check it
6. Xcode should automatically add it to your target

## Step 3: Manually Add to Target (if needed)

1. Go to **"General"** tab
2. Scroll to **"Frameworks, Libraries, and Embedded Content"**
3. Click the **"+"** button
4. Find `FirebaseStorage` in the list
5. Select it and click **"Add"**
6. Make sure it's set to **"Do Not Embed"**

## Step 4: Clean Build

1. **Product → Clean Build Folder** (Shift + Cmd + K)
2. Close Xcode completely
3. Reopen Xcode
4. **Product → Build** (Cmd + B)

## Step 5: If Still Not Working

Try removing and re-adding the package:

1. Go to **Package Dependencies** tab
2. Select `firebase-ios-sdk`
3. Click the **"-"** button to remove it
4. Click **"+"** to add it again
5. Enter: `https://github.com/firebase/firebase-ios-sdk`
6. Make sure to check **FirebaseStorage** in the product list
7. Click **"Add Package"**
8. Clean build folder and rebuild

## Step 6: Verify Import Works

After following the steps above, the import should work. If you still see the error:

1. Make sure you're building for a **real device or simulator** (not just checking syntax)
2. Check that your **deployment target** is iOS 13.0 or higher
3. Try restarting your Mac (sometimes Xcode caches get stuck)

