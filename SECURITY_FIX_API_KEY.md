# Security Fix: Firebase API Key Exposure

## Issue
A Firebase API key was hardcoded in `web/firebase-messaging-sw.js` and exposed in the public repository.

## Actions Taken

1. ✅ Removed hardcoded API key from `web/firebase-messaging-sw.js`
2. ✅ Updated service worker to load config from external file (`firebase-config.js`)
3. ✅ Added `web/firebase-config.js` to `.gitignore` (already present)
4. ✅ Created example config file (`web/firebase-config.js.example`)

## Required Actions

### 1. Revoke the Exposed API Key

**URGENT:** The exposed API key must be revoked immediately:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `vehicle-damage-app`
3. Navigate to **APIs & Services** → **Credentials**
4. Find the API key: Check your Google Cloud Console for the exposed key (if this document was created to fix an exposure)
5. Click on it and select **Restrict key** or **Delete key**
6. If restricting, add domain restrictions:
   - `https://vehicle-damage-app.web.app/*`
   - `https://vehicle-damage-app.firebaseapp.com/*`
   - Your custom domain if applicable

### 2. Create a New API Key (if deleted)

1. In Google Cloud Console → **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Configure the new key:
   - **Application restrictions**: HTTP referrers
   - **Website restrictions**: Add your domains
   - **API restrictions**: Restrict to Firebase services only

### 3. Generate firebase-config.js

The service worker now loads config from `web/firebase-config.js` (which is in `.gitignore`).

**Option A: Manual Creation**
1. Copy `web/firebase-config.js.example` to `web/firebase-config.js`
2. Fill in your Firebase config values from `lib/firebase_options.dart` or Firebase Console

**Option B: Using Script (if Node.js is available)**
```bash
# Set environment variables
export FIREBASE_API_KEY="your-new-api-key"
export FIREBASE_APP_ID="your-app-id"
export FIREBASE_MESSAGING_SENDER_ID="your-sender-id"
export FIREBASE_PROJECT_ID="vehicle-damage-app"
export FIREBASE_AUTH_DOMAIN="vehicle-damage-app.firebaseapp.com"
export FIREBASE_STORAGE_BUCKET="vehicle-damage-app.firebasestorage.app"
export FIREBASE_MEASUREMENT_ID="your-measurement-id"

# Run the script
node scripts/generate_firebase_config.js
```

**Option C: Extract from firebase_options.dart**
The config values can be found in `lib/firebase_options.dart` (web section).

### 4. Verify Service Worker Works

1. Build your web app: `flutter build web --release`
2. Deploy to Firebase: `firebase deploy --only hosting`
3. Test push notifications in the browser
4. Check browser console for any errors

## Security Best Practices

### ✅ DO:
- Keep `web/firebase-config.js` in `.gitignore`
- Use environment variables for build-time config
- Restrict API keys to specific domains
- Regularly rotate API keys
- Use Firebase App Check for additional security
- Monitor API key usage in Google Cloud Console

### ❌ DON'T:
- Commit `web/firebase-config.js` to git
- Hardcode API keys in source files
- Share API keys in public repositories
- Use production keys in development

## Firebase API Key Security

**Important Note:** Firebase API keys for web apps are **meant to be public** in the client-side code. However, security is maintained through:

1. **Domain Restrictions**: Limit which domains can use the key
2. **API Restrictions**: Limit which APIs the key can access
3. **Firebase Security Rules**: Control data access
4. **Firebase App Check**: Verify requests come from your app

The key itself is not a secret, but it should be restricted to prevent unauthorized usage.

## Next Steps

1. ✅ Revoke/restrict the exposed API key
2. ✅ Create new API key if needed
3. ✅ Generate `web/firebase-config.js` locally
4. ✅ Test the service worker
5. ✅ Close the GitHub security alert

## References

- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)

