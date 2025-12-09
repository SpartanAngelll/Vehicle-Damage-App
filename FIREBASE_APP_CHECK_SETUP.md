# Firebase App Check Setup Guide

Firebase App Check helps protect your backend resources from abuse by verifying that requests come from your authentic app.

## 📋 Prerequisites

- Firebase project set up
- Flutter app with Firebase initialized
- Access to Firebase Console

## 🚀 Setup Instructions

### Step 1: Enable App Check in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `vehicle-damage-app`
3. Navigate to **Build** → **App Check**
4. Click **Get started**
5. Select your app (Android, iOS, or Web)

### Step 2: Choose Provider

#### For Android:
- **Production**: Play Integrity API (recommended)
- **Development**: DeviceCheck (for debug builds)

#### For iOS:
- **Production**: DeviceCheck (recommended)
- **Development**: App Attest (for debug builds)

#### For Web:
- **Production**: reCAPTCHA Enterprise (recommended)
- **Development**: reCAPTCHA v3 (for testing)

### Step 3: Install Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_app_check: ^0.2.1+4
```

Then run:
```bash
flutter pub get
```

### Step 4: Initialize App Check in Your App

Update `lib/main.dart`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> _initializeApp() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ [Main] Environment variables loaded');
  } catch (e) {
    print('⚠️ [Main] Failed to load .env file: $e');
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase App Check
  try {
    if (kIsWeb) {
      // For web, use reCAPTCHA v3
      // You'll need to get a reCAPTCHA site key from Firebase Console
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android, use Play Integrity API
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS, use DeviceCheck
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.deviceCheck,
      );
    }
    print('✅ [Main] Firebase App Check initialized');
  } catch (e) {
    print('⚠️ [Main] Failed to initialize App Check: $e');
    // Don't fail app startup if App Check fails
  }
  
  // ... rest of initialization
}
```

### Step 5: Get reCAPTCHA Site Key (Web Only)

For web apps:

1. Go to Firebase Console → App Check
2. Select your Web app
3. Click **Get started** with reCAPTCHA
4. Copy the site key provided
5. Replace `'your-recaptcha-site-key'` in the code above

### Step 6: Enforce App Check in Firestore Rules (Optional but Recommended)

Update `firestore.rules` to require App Check tokens:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to verify App Check
    function isAppCheckVerified() {
      return request.appCheck != null && request.appCheck.valid;
    }
    
    // Apply to sensitive collections
    match /users/{userId} {
      allow read: if isAppCheckVerified() && isAuthenticated();
      allow write: if isAppCheckVerified() && isAuthenticated() && request.auth.uid == userId;
    }
    
    match /bookings/{bookingId} {
      allow read: if isAppCheckVerified() && isAuthenticated() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.professionalId == request.auth.uid
      );
      // ... rest of rules
    }
    
    // ... apply to other sensitive collections
  }
}
```

**Note**: You can gradually enable App Check enforcement. Start without it, then add it to sensitive collections.

### Step 7: Test App Check

1. **Build and run your app**
   ```bash
   flutter run
   ```

2. **Check Firebase Console**
   - Go to Firebase Console → App Check
   - You should see usage statistics
   - Verify tokens are being generated

3. **Test with Firestore**
   - Try reading/writing data
   - Check that operations work correctly
   - If you enabled enforcement in rules, verify unauthorized requests are blocked

## 🔍 Verification

### Check App Check Status

1. Go to Firebase Console → App Check
2. Select your app
3. Check the dashboard for:
   - Token generation rate
   - Token validation rate
   - Any errors

### Test Enforcement

If you enabled App Check in Firestore rules:

1. Try accessing Firestore from an unauthorized app
2. Requests should be blocked
3. Check Firebase Console for blocked requests

## ⚠️ Important Notes

1. **Development vs Production**:
   - Use different providers for development and production
   - Development providers are more lenient
   - Production providers provide better security

2. **Gradual Rollout**:
   - Start without enforcing App Check in rules
   - Monitor usage and errors
   - Gradually enable enforcement on sensitive collections

3. **Performance**:
   - App Check adds minimal overhead
   - Tokens are cached and refreshed automatically
   - No noticeable impact on app performance

4. **Compatibility**:
   - Works with all Firebase services
   - Can be integrated with Supabase (requires custom implementation)
   - Works on all platforms (Android, iOS, Web)

## 🐛 Troubleshooting

### Issue: App Check not initializing
**Solution**:
- Verify Firebase is initialized first
- Check that you have the correct provider selected
- For web, ensure reCAPTCHA site key is correct
- Check console for error messages

### Issue: Firestore requests blocked
**Solution**:
- Verify App Check is initialized before Firestore operations
- Check Firestore rules for App Check enforcement
- Temporarily disable enforcement to test
- Verify tokens are being generated (check Firebase Console)

### Issue: reCAPTCHA not working on web
**Solution**:
- Verify site key is correct
- Check that reCAPTCHA is enabled in Firebase Console
- Ensure your domain is registered in Firebase
- Check browser console for errors

## 📚 Additional Resources

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Play Integrity API](https://developer.android.com/google/play/integrity)
- [DeviceCheck Documentation](https://developer.apple.com/documentation/devicecheck)
- [reCAPTCHA Documentation](https://developers.google.com/recaptcha)

## ✅ Checklist

- [ ] App Check enabled in Firebase Console
- [ ] Provider selected (Play Integrity/DeviceCheck/reCAPTCHA)
- [ ] Dependencies installed (`firebase_app_check`)
- [ ] App Check initialized in `main.dart`
- [ ] reCAPTCHA site key obtained (web only)
- [ ] App Check tested and working
- [ ] Firestore rules updated (optional)
- [ ] Usage monitored in Firebase Console

---

**Status**: Setup guide created - Follow steps to enable App Check
**Last Updated**: Security audit

