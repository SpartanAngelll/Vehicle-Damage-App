# Fix Localhost Authentication Issue

## Problem
Authentication fails on localhost and web with errors:
- "requests-from-referer-http://localhost:64718-are-blocked"
- "api-key-expired.-please-renew-the-api-key"

## Solution: Update API Key Restrictions

The web API key needs to allow localhost for development. Follow these steps:

### Step 1: Open Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **vehicle-damage-app**
3. Navigate to **APIs & Services** → **Credentials**

### Step 2: Edit the Web API Key

1. Find the API key: **`YOUR_FIREBASE_WEB_API_KEY`** (check `lib/firebase_options.dart` for the actual key)
2. Click on the key name to edit it

### Step 3: Update Application Restrictions

Under **Application restrictions**:
1. Select **HTTP referrers (web sites)**
2. In the **Website restrictions** section, add these referrers (one per line):

```
https://vehicle-damage-app.web.app/*
https://vehicle-damage-app.firebaseapp.com/*
https://*.web.app/*
https://*.firebaseapp.com/*
http://localhost:*
http://127.0.0.1:*
http://localhost:*/ *
http://127.0.0.1:*/ *
```

**Important Notes:**
- The `*` wildcard allows any port number (like `:64718`, `:8080`, etc.)
- Add both `localhost` and `127.0.0.1` to cover all localhost variations
- The trailing `/*` allows all paths on that domain

### Step 4: Update API Restrictions

Under **API restrictions**:
1. Select **Restrict key**
2. Make sure these APIs are enabled:
   - ✅ **Identity Toolkit API** (required for authentication)
   - ✅ Firebase Installations API
   - ✅ Firebase Cloud Messaging API
   - ✅ Cloud Firestore API
   - ✅ Firebase Storage API

**OR** select **Don't restrict key** for development (less secure but easier)

### Step 5: Save Changes

1. Click **Save** at the bottom
2. Wait 1-2 minutes for changes to propagate

### Step 6: Test

1. Restart your Flutter web app:
   ```bash
   flutter run -d chrome
   ```
2. Try logging in again
3. Check browser console for any remaining errors

## Alternative: Create Separate Development Key

If you want to keep production keys more restricted, create a separate API key for development:

1. In Google Cloud Console → **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Name it: "Firebase Web - Development"
4. Configure it with:
   - **Application restrictions**: HTTP referrers
   - **Website restrictions**: Only `http://localhost:*` and `http://127.0.0.1:*`
   - **API restrictions**: Same Firebase APIs
5. Update `lib/firebase_options.dart` web section with the new key for local development
6. Use the restricted key for production deployments

## Verify API Key Status

1. In Google Cloud Console → **APIs & Services** → **Credentials**
2. Check the API key status:
   - Should show "Enabled" (not "Expired" or "Disabled")
   - If expired, you may need to regenerate it

## Common Issues

### Issue: Still getting blocked after updating
**Solution**: 
- Wait 2-5 minutes for changes to propagate
- Clear browser cache
- Try incognito/private browsing mode
- Check that you saved the changes in Google Cloud Console

### Issue: API key shows as expired
**Solution**:
- The key might need to be regenerated
- Check if billing is enabled for your Google Cloud project
- Verify the key hasn't been deleted

### Issue: Works on mobile but not web
**Solution**:
- Mobile uses a different API key (Android/iOS)
- Only the web API key needs localhost restrictions
- Make sure you're editing the correct key (web key, not Android/iOS)

## Quick Reference

**Web API Key**: Check `lib/firebase_options.dart` for your actual Firebase web API key
**Project**: vehicle-damage-app
**Required Referrers for Development**:
- `http://localhost:*`
- `http://127.0.0.1:*`

## After Fixing

Once localhost is working:
1. ✅ Test login on localhost
2. ✅ Test login on deployed web app
3. ✅ Verify mobile app still works (uses different key)
4. ✅ Consider creating separate dev/prod keys for better security

