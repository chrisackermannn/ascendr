# How to Add FirebaseStorage to Your Xcode Project

## Quick Fix for "Unable to find module dependency: 'FirebaseStorage'"

### Step-by-Step Instructions:

1. **Open your Xcode project** (`Ascendr.xcodeproj`)

2. **Select your project** in the Project Navigator (top item)

3. **Select your target** (Ascendr) in the main editor

4. **Go to "Package Dependencies" tab** (at the top of the editor)

5. **Check if firebase-ios-sdk is already added:**
   - If you see `firebase-ios-sdk` in the list, proceed to step 6
   - If not, click the **"+"** button and add: `https://github.com/firebase/firebase-ios-sdk`

6. **Add FirebaseStorage:**
   - If `firebase-ios-sdk` is already added:
     - Click on `firebase-ios-sdk` in the Package Dependencies list
     - In the right panel, make sure **FirebaseStorage** is checked under "Products"
     - If it's not checked, check it and Xcode will automatically resolve dependencies
   
   - If you're adding the package for the first time:
     - After entering the URL and clicking "Add Package"
     - In the product selection screen, make sure to check:
       - ✅ FirebaseCore
       - ✅ FirebaseAuth
       - ✅ FirebaseDatabase
       - ✅ **FirebaseStorage** ⚠️ (This is the one you're missing!)

7. **Verify the package is added:**
   - Go to your target's "General" tab
   - Scroll down to "Frameworks, Libraries, and Embedded Content"
   - You should see `FirebaseStorage` listed

8. **Clean and rebuild:**
   - Product → Clean Build Folder (Shift + Cmd + K)
   - Product → Build (Cmd + B)

### Alternative: If Package Dependencies doesn't work

If you can't find Package Dependencies or it's not working:

1. **File → Add Packages...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Click "Add Package"
4. **Make sure to select FirebaseStorage** in the product list
5. Click "Add Package"

### Verify It's Working

After adding, try building the project. The error should be gone. If you still see the error:

1. Make sure `FirebaseStorage` is in "Frameworks, Libraries, and Embedded Content"
2. Try restarting Xcode
3. Clean build folder and rebuild

