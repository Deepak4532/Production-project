# Google Sign-In Integration Setup Guide

## ✅ What's Been Done

1. ✓ Added `google_sign_in: ^6.1.5` to pubspec.yaml
2. ✓ Created `google_sign_in_service.dart` with Google Sign-In logic
3. ✓ Added `createUser()` method to database_helper.dart
4. ✓ Updated login_screen.dart with Google login button functionality

---

## 📱 Android Setup (REQUIRED)

### Step 1: Get SHA-1 Fingerprint

Run this command in your project root:
```bash
./gradlew signingReport
```

Look for the SHA-1 under "Variant: debug" (and "release" if needed).

### Step 2: Create Firebase Project & App

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Create a new project"** (or select existing)
3. Name: `medication-app` (or your preferred name)
4. Accept terms and create
5. Once created, click **"Add app"** → Select **Android**

### Step 3: Register Android App

Fill in the form:
- **Package name**: `com.example.medication` (check in `android/app/src/main/AndroidManifest.xml`)
- **SHA-1 certificate fingerprint**: Paste the SHA-1 from Step 1
- **App nickname** (optional): `Medication App`

Click **"Register app"**

### Step 4: Download & Add google-services.json

1. Click **"Download google-services.json"**
2. Place the file in: `android/app/`
   ```
   medication/
   ├── android/
   │   └── app/
   │       └── google-services.json  ← Place here
   ```

### Step 5: Update Android Gradle Files

**File: `android/build.gradle.kts`**

Add this dependency in the `plugins` section if not already present:
```kotlin
// At the top, in plugins block
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

**File: `android/app/build.gradle.kts`**

Add at the bottom:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### Step 6: Update AndroidManifest.xml

**File: `android/app/src/main/AndroidManifest.xml`**

Add internet permission if not present (add inside `<manifest>` tag):
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🍎 iOS Setup (REQUIRED)

### Step 1: Create/Get iOS App in Firebase

1. In [Firebase Console](https://console.firebase.google.com), go to your project
2. Click **"Add app"** → Select **iOS**

### Step 2: Bundle ID

Get your Bundle ID:
- **File**: `ios/Runner/Info.plist`
- Find the key `CFBundleIdentifier`
- It's typically something like `com.example.medication`

Register it in Firebase with this Bundle ID.

### Step 3: Download GoogleService-Info.plist

1. Click **"Download GoogleService-Info.plist"**
2. Open `ios/Runner.xcworkspace` in Xcode (NOT the .xcodeproj)
3. Drag and drop `GoogleService-Info.plist` into the Runner project
4. Make sure it's added to the **Runner** target

### Step 4: Configure URL Scheme in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target → **Info** tab
3. Scroll to **URL Types** section
4. Click **+** to add a new URL scheme
5. Copy the **Reversed Client ID** from your `GoogleService-Info.plist` file
   - It looks like: `com.googleusercontent.apps.YOUR_APP_ID`
6. Paste it as the **URL Scheme**

---

## 🚀 Installation & Testing

### Step 1: Get Flutter Dependencies

```bash
cd /Users/deepaksubedi/development/medication
flutter clean
flutter pub get
```

### Step 2: Android Testing

```bash
flutter run -v
```

- Click the **"Google Account"** button on login screen
- Select a Google account to sign in
- You should be redirected to the home screen

### Step 3: iOS Testing

```bash
flutter run -v
```

If using iOS, you may see a Google Sign-In dialog. Complete the sign-in.

---

## ✨ Features Implemented

✅ **Email & Password Login** - Existing functionality
✅ **Google Sign-In** - New! Click "Google Account" button
✅ **Auto User Creation** - New users are automatically added to database
✅ **Session Persistence** - Login state persists across app restarts
✅ **Error Handling** - Clear error messages for failed sign-in

---

## 📋 Troubleshooting

### "Google sign-in failed: PlatformException"
- Check SHA-1 fingerprint matches Firebase
- Verify google-services.json is in android/app/

### "Failed to load GoogleService-Info.plist"
- Ensure GoogleService-Info.plist is added to Xcode target
- Check the file exists and is readable

### "Sign-in dialog doesn't appear"
- Verify Bundle ID matches Firebase registration
- Check URL scheme is correctly set in Info.plist

### Still having issues?
- Run `flutter clean && flutter pub get`
- Delete build folders: `rm -rf build ios/Pods`
- Rebuild the app from scratch

---

## 🔐 Security Notes

- Passwords are hashed using SHA256 before storage
- Google authentication tokens are managed by the google_sign_in package
- No sensitive credentials are stored in the app code

---

## 📝 Next Steps (Optional Enhancements)

1. **Email Verification** - Add email verification for regular sign-up
2. **Profile Photo** - Display Google profile picture in app
3. **Account Linking** - Allow linking email/password account with Google
4. **Social Login** - Add Apple Sign-In, Facebook, etc.

---

Once you complete the Android & iOS setup above, run the app and test the Google Sign-In button!
