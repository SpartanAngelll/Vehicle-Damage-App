# Security Setup Guide

## ⚠️ IMPORTANT: Never commit sensitive files to git!

This project contains sensitive configuration files that should **NEVER** be committed to version control.

## Protected Files (Already in .gitignore)

The following files contain sensitive information and are automatically ignored by git:

- `lib/firebase_options.dart` - Contains your Firebase API keys
- `android/app/google-services.json` - Contains your Android Firebase configuration
- `ios/Runner/GoogleService-Info.plist` - Contains your iOS Firebase configuration
- `web/firebase-config.js` - Contains your web Firebase configuration

## Setup Instructions

### 1. Firebase Configuration

1. **Copy the template:**
   ```bash
   cp lib/firebase_options.template.dart lib/firebase_options.dart
   ```

2. **Fill in your Firebase project details:**
   - Get your project details from [Firebase Console](https://console.firebase.google.com/)
   - Replace all `YOUR_*_HERE` placeholders with actual values
   - Save the file

3. **For Android:**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/`

4. **For iOS:**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `ios/Runner/`

### 2. Verify Security

Before committing, ensure these files are ignored:

```bash
git status
```

You should **NOT** see any of these files in the output:
- `firebase_options.dart`
- `google-services.json`
- `GoogleService-Info.plist`

### 3. Test Your Setup

Run the app to ensure Firebase is properly configured:

```bash
flutter run
```

## What Happens If You Accidentally Commit Sensitive Files?

1. **Immediately remove them from git:**
   ```bash
   git rm --cached lib/firebase_options.dart
   git rm --cached android/app/google-services.json
   git commit -m "Remove sensitive files"
   ```

2. **Regenerate your Firebase API keys** in the Firebase Console
3. **Update your configuration files** with new keys
4. **Force push to overwrite the remote history** (if already pushed)

## Security Best Practices

- ✅ Use `.gitignore` to protect sensitive files
- ✅ Use template files for configuration structure
- ✅ Never hardcode API keys in source code
- ✅ Use environment variables for production deployments
- ✅ Regularly rotate API keys
- ✅ Monitor Firebase usage for suspicious activity

## Need Help?

If you accidentally expose sensitive information:
1. Don't panic
2. Remove the files from git immediately
3. Regenerate your Firebase keys
4. Update your configuration
5. Consider the previous commits compromised

Remember: **Security first, convenience second!**
