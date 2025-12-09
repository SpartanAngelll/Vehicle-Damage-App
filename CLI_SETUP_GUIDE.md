# CLI Setup Guide - Supabase + Firebase Integration

This guide shows you how to use Supabase CLI and Firebase CLI to complete the remaining setup operations.

## Prerequisites

1. **Supabase CLI** - Install via npm:
   ```bash
   npm install -g supabase
   ```

2. **Firebase CLI** - Install via npm:
   ```bash
   npm install -g firebase-tools
   ```

## Quick Start

### Windows (PowerShell)
```powershell
.\complete_setup.ps1
```

### Linux/macOS (Bash)
```bash
chmod +x complete_setup.sh
./complete_setup.sh
```

## What the Scripts Do

The `complete_setup.ps1` (Windows) and `complete_setup.sh` (Linux/macOS) scripts automate:

1. ✅ **Check CLI installations** - Verifies Supabase and Firebase CLIs are installed
2. ✅ **Get Supabase credentials** - Prompts for or retrieves Supabase anon key
3. ✅ **Update Flutter app** - Automatically adds Supabase initialization to `lib/main.dart`
4. ✅ **Deploy Firestore rules** - Deploys Firestore security rules using Firebase CLI
5. ⚠️ **JWT Configuration** - Provides instructions for manual JWT setup

## Manual Steps

### 1. Get Supabase Credentials

**Option A: Using the helper script**
```powershell
# Windows
.\get_supabase_credentials.ps1

# Linux/macOS
chmod +x get_supabase_credentials.sh
./get_supabase_credentials.sh
```

**Option B: Using Supabase Dashboard**
1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/api
2. Copy the `anon public` key

**Option C: Using Supabase CLI**
```bash
# Login first
supabase login

# Link your project
supabase link --project-ref rodzemxwopecqpazkjyk

# Get API keys
supabase projects api-keys --project-ref rodzemxwopecqpazkjyk
```

### 2. Configure JWT Secret (CRITICAL)

Supabase needs to accept Firebase JWT tokens for RLS to work.

**Option A: Using Supabase Dashboard (Recommended)**
1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/api
2. Find "JWT Settings" section
3. Get Firebase private key:
   - Firebase Console → Project Settings → Service Accounts
   - Generate new private key (or use existing)
   - Copy the entire private key (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
4. Paste into Supabase JWT Secret field

**Option B: Using Supabase CLI**
```bash
# Get Firebase private key first (from Firebase Console)
# Then update Supabase JWT secret
supabase projects update --jwt-secret "YOUR_FIREBASE_PRIVATE_KEY"
```

**Note:** The JWT secret must be the Firebase service account private key for Supabase to verify Firebase tokens.

### 3. Update Flutter App (if not done automatically)

If the script didn't update `lib/main.dart`, add this manually:

```dart
// In lib/main.dart, add import:
import 'services/firebase_supabase_service.dart';

// In _initializeApp() method, after Firebase initialization:
await FirebaseSupabaseService.instance.initialize(
  supabaseUrl: 'https://rodzemxwopecqpazkjyk.supabase.co',
  supabaseAnonKey: 'YOUR_ANON_KEY_HERE', // Replace with actual key
);
```

### 4. Deploy Firestore Rules

**Using Firebase CLI:**
```bash
# Login to Firebase (if not already)
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

**Using the setup script:**
The `complete_setup.ps1` or `complete_setup.sh` script will automatically deploy rules if Firebase CLI is configured.

## Verification

After completing setup, verify everything works:

1. **Test Supabase Connection:**
   ```dart
   // In your Flutter app
   final supabase = FirebaseSupabaseService.instance;
   final result = await supabase.query(table: 'users', limit: 1);
   print('Supabase connection: ${result != null ? "✅" : "❌"}');
   ```

2. **Test Firebase Auth:**
   ```dart
   final auth = FirebaseAuthServiceWrapper.instance;
   final user = await auth.signUpWithEmailAndPassword(
     email: 'test@example.com',
     password: 'password123',
     fullName: 'Test User',
     role: 'owner',
   );
   ```

3. **Verify RLS Policies:**
   - Sign in as a user
   - Try to query your own data (should work)
   - Try to query another user's data (should fail with RLS)

## Troubleshooting

### Supabase CLI Not Found
```bash
npm install -g supabase
```

### Firebase CLI Not Found
```bash
npm install -g firebase-tools
```

### Not Logged In to Supabase
```bash
supabase login
supabase link --project-ref rodzemxwopecqpazkjyk
```

### Not Logged In to Firebase
```bash
firebase login
```

### JWT Configuration Issues
- Make sure you're using the Firebase service account **private key**, not the public key
- The private key should include the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` markers
- Verify the key is correctly pasted in Supabase Dashboard

### RLS Policies Not Working
- Verify JWT secret is configured correctly
- Check that `firebase_uid()` function exists in Supabase
- Verify RLS is enabled on tables: `ALTER TABLE users ENABLE ROW LEVEL SECURITY;`

## Next Steps

After completing setup:

1. ✅ Test authentication flow (see `TESTING_GUIDE.md`)
2. ✅ Verify RLS policies are working
3. ✅ Test booking workflow
4. ✅ Test payment workflow
5. ✅ Test chat functionality

## Additional Resources

- [Supabase CLI Documentation](https://supabase.com/docs/reference/cli)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Testing Guide](./TESTING_GUIDE.md)
- [Setup Complete Summary](./SETUP_COMPLETE.md)

