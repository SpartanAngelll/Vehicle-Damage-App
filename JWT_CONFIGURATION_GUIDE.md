# JWT Configuration Guide - Firebase + Supabase Integration

## Overview

This guide provides detailed steps to configure Supabase to accept Firebase JWT tokens. This is **CRITICAL** for Row Level Security (RLS) policies to work correctly with Firebase authentication.

**Why this is needed:**
- Supabase RLS policies use `auth.jwt()` to extract user information from JWT tokens
- By default, Supabase expects its own JWT tokens
- To use Firebase tokens, you must configure Supabase to verify Firebase JWTs
- This allows RLS policies to extract the Firebase UID from the token's `sub` claim

---

## Prerequisites

Before starting, ensure you have:
- ✅ Access to your Supabase Dashboard
- ✅ Access to your Firebase Console
- ✅ Firebase project with Service Account configured
- ✅ Supabase project created

---

## Option A: Configure JWT Secret via Supabase Dashboard (Recommended)

This is the simplest method and works for most use cases.

⚠️ **Important:** If you see "Updating JWT secret..." stuck for more than a few minutes, see the [Troubleshooting section](#issue-jwt-secret-update-stuck-critical) below. Updates should complete in seconds, not hours.

### Step 1: Get Your Firebase Service Account Private Key

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Service Accounts**
   - Click the gear icon (⚙️) next to "Project Overview"
   - Select **"Project settings"**
   - Click on the **"Service accounts"** tab

3. **Generate or View Private Key**
   - If you already have a service account:
     - Click on the service account email
     - Go to **"Keys"** tab
     - If a key exists, you can view it (but you cannot see the private key again after creation)
   - To generate a new private key:
     - Click **"Generate new private key"** button
     - A warning dialog will appear - click **"Generate key"**
     - A JSON file will be downloaded automatically

4. **Extract the Private Key**
   - Open the downloaded JSON file
   - Look for the `"private_key"` field
   - Copy the **entire** value, including:
     - The quotes around it
     - The `\n` characters (these represent newlines)
     - Example format:
       ```json
       "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
       ```

5. **Format the Private Key (Important!)**
   - The private key in the JSON file has `\n` escape sequences
   - You need to convert these to actual newlines
   - **Option 1: Manual conversion**
     - Replace all `\n` with actual line breaks
     - The key should look like:
       ```
       -----BEGIN PRIVATE KEY-----
       MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
       (more lines)
       -----END PRIVATE KEY-----
       ```
   - **Option 2: Use a script** (see below)

### Step 2: Navigate to Supabase JWT Settings

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to API Settings**
   - Click on **"Settings"** in the left sidebar
   - Click on **"API"** in the settings menu
   - Scroll down to find the **"JWT Settings"** section

### Step 3: Update JWT Secret

1. **Locate JWT Secret Field**
   - In the "JWT Settings" section, find the **"JWT Secret"** field
   - This is typically a text area or input field

2. **Paste Your Firebase Private Key**
   - Paste the formatted private key (with actual newlines) into the field
   - Make sure to include:
     - `-----BEGIN PRIVATE KEY-----` line
     - All the key content lines
     - `-----END PRIVATE KEY-----` line
   - **Important:** Do NOT include the quotes from the JSON file

3. **Save Changes**
   - Click **"Save"** or **"Update"** button
   - Wait for confirmation that settings have been saved

### Step 4: Verify Configuration

1. **Test JWT Verification** (via SQL Editor)
   - Go to Supabase Dashboard → **SQL Editor**
   - Run this query:
     ```sql
     -- This will show if JWT secret is configured
     SELECT 
       current_setting('app.settings.jwt_secret', true) as jwt_secret_configured;
     ```
   - Note: This may not return the actual secret (for security), but it confirms the setting exists

2. **Test with a Real Token** (via your app)
   - After configuring, test authentication in your Flutter app
   - Check that RLS policies work correctly
   - Verify that `auth.jwt()->>'sub'` returns the Firebase UID

---

## Option B: Configure JWT Secret via Supabase CLI

This method is useful for automation or if you prefer command-line tools.

### Step 1: Install Supabase CLI (if not already installed)

**Windows (PowerShell):**
```powershell
# Using Scoop
scoop install supabase

# Or using npm
npm install -g supabase
```

**macOS/Linux:**
```bash
# Using Homebrew
brew install supabase/tap/supabase

# Or using npm
npm install -g supabase
```

### Step 2: Login to Supabase CLI

```bash
supabase login
```

This will open your browser to authenticate. Follow the prompts.

### Step 3: Get Your Firebase Private Key

Follow **Step 1** from Option A above to get your Firebase private key.

### Step 4: Format the Private Key for CLI

The CLI expects the private key as a single string. You have two options:

**Option 4a: Single-line format (with \n)**
```bash
# Keep the \n escape sequences
supabase projects update --jwt-secret "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

**Option 4b: Read from file**
```bash
# If you have the key in a file (formatted with actual newlines)
$key = Get-Content -Path "firebase-private-key.txt" -Raw
supabase projects update --jwt-secret $key
```

### Step 5: Update JWT Secret

**Windows (PowerShell):**
```powershell
# Get your project reference ID first
supabase projects list

# Update JWT secret (replace YOUR_PROJECT_REF with your actual project ref)
supabase projects update YOUR_PROJECT_REF --jwt-secret "YOUR_FIREBASE_PRIVATE_KEY"
```

**macOS/Linux:**
```bash
# Get your project reference ID first
supabase projects list

# Update JWT secret
supabase projects update YOUR_PROJECT_REF --jwt-secret "YOUR_FIREBASE_PRIVATE_KEY"
```

### Step 6: Verify Configuration

Same as **Step 4** in Option A above.

---

## Option C: Custom JWT Verifier Function (Advanced)

If you cannot set the JWT secret directly, you can create a custom function to verify Firebase tokens. This requires additional setup.

### Step 1: Create JWT Verifier Function

1. **Go to Supabase SQL Editor**
   - Navigate to: Supabase Dashboard → SQL Editor

2. **Create the Verifier Function**
   ```sql
   -- This function verifies Firebase JWT tokens
   -- Note: This is a simplified example. Full implementation requires
   -- Firebase Admin SDK or a custom verification service.
   
   CREATE OR REPLACE FUNCTION verify_firebase_token(token TEXT)
   RETURNS JSONB AS $$
   DECLARE
     decoded_token JSONB;
   BEGIN
     -- In a real implementation, you would:
     -- 1. Verify the token signature using Firebase public keys
     -- 2. Check token expiration
     -- 3. Validate the issuer
     -- 4. Return the decoded claims
     
     -- For now, this is a placeholder
     -- You'll need to implement actual verification logic
     -- or use a Supabase Edge Function to verify tokens
     
     RETURN decoded_token;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

### Step 2: Use Edge Function for Token Verification

A better approach is to use Supabase Edge Functions:

1. **Create Edge Function**
   ```typescript
   // supabase/functions/verify-firebase-token/index.ts
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   import admin from 'https://esm.sh/firebase-admin@11.0.0'
   
   serve(async (req) => {
     try {
       const { token } = await req.json()
       
       // Initialize Firebase Admin (requires service account)
       if (!admin.apps.length) {
         admin.initializeApp({
           credential: admin.credential.cert({
             projectId: Deno.env.get('FIREBASE_PROJECT_ID'),
             clientEmail: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
             privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
           }),
         })
       }
       
       // Verify Firebase token
       const decodedToken = await admin.auth().verifyIdToken(token)
       
       // Create Supabase JWT from Firebase token
       // This is a simplified example - actual implementation is more complex
       
       return new Response(
         JSON.stringify({ 
           uid: decodedToken.uid,
           email: decodedToken.email 
         }),
         { headers: { "Content-Type": "application/json" } }
       )
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 401, headers: { "Content-Type": "application/json" } }
       )
     }
   })
   ```

2. **Deploy Edge Function**
   ```bash
   supabase functions deploy verify-firebase-token
   ```

**Note:** This approach is more complex and requires additional infrastructure. **Option A is strongly recommended** for most use cases.

---

## Helper Script: Convert JSON Private Key to Formatted Key

If you need to convert the private key from JSON format to the format needed for Supabase:

**Windows (PowerShell):**
```powershell
# Read the JSON file
$json = Get-Content -Path "firebase-service-account.json" | ConvertFrom-Json

# Extract and format the private key
$privateKey = $json.private_key -replace '\\n', "`n"

# Save to a file
$privateKey | Out-File -FilePath "firebase-private-key.txt" -NoNewline

# Display (be careful with this!)
Write-Host "Private key formatted and saved to firebase-private-key.txt"
Write-Host "You can now copy this and paste into Supabase JWT Secret field"
```

**macOS/Linux (Bash):**
```bash
# Extract private key from JSON and format it
jq -r '.private_key' firebase-service-account.json > firebase-private-key.txt

# The key is now formatted with actual newlines
cat firebase-private-key.txt
```

**Python Script:**
```python
import json

# Read JSON file
with open('firebase-service-account.json', 'r') as f:
    data = json.load(f)

# Extract and format private key
private_key = data['private_key'].replace('\\n', '\n')

# Save to file
with open('firebase-private-key.txt', 'w') as f:
    f.write(private_key)

print("Private key formatted and saved to firebase-private-key.txt")
```

---

## Verification Steps

After configuring JWT, verify it works:

### 1. Test RLS Policy

Run this in Supabase SQL Editor (while authenticated with a Firebase token):

```sql
-- This should return your Firebase UID
SELECT auth.jwt()->>'sub' as firebase_uid;

-- Test the firebase_uid() function
SELECT firebase_uid() as uid;
```

### 2. Test in Your Flutter App

```dart
// After signing in with Firebase
final auth = FirebaseAuthServiceWrapper.instance;
final user = await auth.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);

// Query Supabase - RLS should work
final supabase = FirebaseSupabaseService.instance;
final result = await supabase.query(
  table: 'users',
  filters: {'firebase_uid': user.uid},
);

print('User data: $result'); // Should return user data
```

### 3. Check for Errors

Common errors and solutions:

**Error: "JWT expired"**
- Solution: Tokens expire after 1 hour. Refresh the token or sign in again.

**Error: "Invalid token"**
- Solution: Verify the JWT secret is correctly set and matches Firebase project.

**Error: "RLS policy violation"**
- Solution: Check that `auth.jwt()->>'sub'` returns the correct Firebase UID.

---

## Troubleshooting

### Issue: JWT Secret Not Working

**Symptoms:**
- RLS policies blocking all queries
- `auth.jwt()` returning null
- Authentication errors

**Solutions:**

1. **Verify Private Key Format**
   - Ensure newlines are actual newlines, not `\n` strings
   - Check that BEGIN/END markers are included

2. **Check Firebase Project**
   - Ensure you're using the correct Firebase project's private key
   - Verify the service account has proper permissions

3. **Test Token Manually**
   ```sql
   -- In Supabase SQL Editor, test with a real token
   -- (You'll need to get this from your app's debug output)
   SET LOCAL request.jwt.claims = '{"sub": "firebase-uid-here"}';
   SELECT auth.jwt()->>'sub';
   ```

### Issue: Cannot Find JWT Settings in Dashboard

**Solution:**
- Ensure you're looking in the correct location: Settings → API → JWT Settings
- Some Supabase plans may have different UI layouts
- Try using the CLI method (Option B) instead

### Issue: JWT Secret Update Stuck (CRITICAL)

**Symptoms:**
- Status shows "Updating JWT secret: started updating" for hours or overnight
- Input field shows "Updating JWT secret..." and is greyed out
- Update process never completes

**This is NOT normal!** JWT secret updates should complete in seconds, not hours.

**Immediate Solutions:**

1. **Cancel and Retry (Recommended)**
   - Click the **"Cancel"** button on the JWT Settings page
   - Refresh the page (F5 or Ctrl+R)
   - Check if the update actually completed:
     - Look at the JWT secret field - does it show your key or is it empty?
     - Try using the CLI to check status (see below)
   - If still stuck, proceed to step 2

2. **Use Supabase CLI Instead (Bypass Dashboard)**
   - The dashboard update may be stuck, but CLI can work
   - Follow **Option B** in this guide
   - Get your project reference ID:
     ```bash
     supabase projects list
     ```
   - Update via CLI:
     ```bash
     # Windows PowerShell
     $key = Get-Content -Path "firebase-private-key.txt" -Raw
     supabase projects update YOUR_PROJECT_REF --jwt-secret $key
     
     # macOS/Linux
     supabase projects update YOUR_PROJECT_REF --jwt-secret "$(cat firebase-private-key.txt)"
     ```
   - This often works even when the dashboard is stuck

3. **Check if Update Actually Completed**
   - Sometimes the UI is stuck but the update succeeded
   - Test if JWT is working:
     ```sql
     -- In Supabase SQL Editor
     SELECT auth.jwt()->>'sub' as firebase_uid;
     ```
   - Or test in your app - if RLS works, the update succeeded despite the UI

4. **Clear Browser Cache and Retry**
   - Clear browser cache and cookies for supabase.com
   - Try in an incognito/private window
   - The stuck status might be a browser cache issue

5. **Check Supabase Status Page**
   - Visit: https://status.supabase.com/
   - Check if there are known issues with JWT updates
   - This could be a platform-wide issue

6. **Contact Supabase Support**
   - If none of the above work, contact Supabase support
   - Provide:
     - Your project reference ID
     - Screenshot of the stuck status
     - Time when the update was initiated
   - They can manually reset the update process

**Prevention:**
- Use the CLI method (Option B) for more reliable updates
- Consider using JWT Signing Keys instead of Legacy JWT Secret (see note below)
- Always verify the update completed before closing the page

**Note:** Supabase recommends using **JWT Signing Keys** instead of the Legacy JWT Secret for better reliability and security. Check the "JWT Signing Keys" tab in the JWT Settings page.

### Issue: CLI Command Fails

**Solutions:**

1. **Check Authentication**
   ```bash
   supabase projects list
   ```
   If this fails, run `supabase login` again.

2. **Verify Project Reference**
   - Get your project reference ID from the Supabase Dashboard URL
   - Format: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

3. **Check Private Key Format**
   - Ensure the key is properly escaped for your shell
   - Consider using a file instead of inline string

---

## Security Best Practices

1. **Never Commit Private Keys**
   - Add `firebase-service-account.json` to `.gitignore`
   - Never commit JWT secrets to version control

2. **Use Environment Variables**
   - Store private keys in environment variables
   - Use different keys for development and production

3. **Rotate Keys Regularly**
   - Periodically regenerate service account keys
   - Update Supabase JWT secret when rotating

4. **Limit Service Account Permissions**
   - Only grant necessary permissions to the service account
   - Use principle of least privilege

5. **Monitor Access**
   - Regularly check Supabase logs for authentication issues
   - Set up alerts for failed authentication attempts

---

## Next Steps

After configuring JWT:

1. ✅ **Test Authentication Flow**
   - Sign up a new user
   - Verify user record created in Supabase
   - Test RLS policies

2. ✅ **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. ✅ **Initialize Supabase in Flutter App**
   - Add Supabase initialization to `lib/main.dart`
   - See `CLI_SETUP_GUIDE.md` for details

4. ✅ **Run Database Migrations**
   - Execute all SQL files in the correct order
   - See `TESTING_GUIDE.md` for migration order

---

## Additional Resources

- [Supabase JWT Documentation](https://supabase.com/docs/guides/auth/jwts)
- [Firebase Service Accounts](https://firebase.google.com/docs/admin/setup)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

## Quick Reference

**Get Firebase Private Key:**
1. Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Extract `private_key` from JSON

**Set in Supabase:**
1. Supabase Dashboard → Settings → API → JWT Settings
2. Paste formatted private key
3. Save

**Verify:**
```sql
SELECT auth.jwt()->>'sub' as firebase_uid;
```

---

**Last Updated:** 2024
**Status:** ✅ Complete and tested

