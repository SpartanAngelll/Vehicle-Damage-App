# RLS Policy Violation Fix Guide

## 🔴 Current Issue - CONFIRMED

You're getting this error:
```
HTTP 401: {"code":"42501","message":"new row violates row-level security policy for table \"bookings\""}
```

**Common causes:**
1. ❌ `firebase_uid()` function doesn't exist (query returned no rows)
2. ❌ `auth.jwt()->>'sub'` returns NULL (JWT secret not configured)
3. ❌ **Customer ID mismatch** - Using stale `userState.userId` instead of current Firebase UID

**If you see this in the error:**
```
Current Firebase UID: VZ2bAvAX0ThZ4QArKwhDnD37u652
Customer ID in booking: Z1IsrAdLm5TbYhvlddIVwW33Woe2
```

**This means:** The booking is being created with a different `customer_id` than the Firebase UID in your JWT token. The RLS policy checks `customer_id = public.firebase_uid()`, so they must match.

**Fix:** Always use `userState.currentUser?.uid` (current Firebase Auth UID) instead of `userState.userId` (which can be stale from local storage).

## 🔍 Root Cause

The Firebase token is being sent correctly, but Supabase isn't processing it to extract the Firebase UID. This usually means:

1. **Firebase Third Party Auth is not fully configured** in Supabase Dashboard
2. **JWT secret is not set** or doesn't match Firebase
3. **The `firebase_uid()` function** isn't working because `auth.jwt()` returns null

## ✅ IMMEDIATE FIX STEPS

### Step 1: Create the `firebase_uid()` Function (DO THIS FIRST)

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

2. **Run the Fix Script**
   - Copy and paste the contents of `fix_rls_immediate.sql`
   - Click **"Run"** to execute
   - This will create the `firebase_uid()` function

3. **Verify Function Created**
   - Run this query:
     ```sql
     SELECT routine_name FROM information_schema.routines 
     WHERE routine_name = 'firebase_uid';
     ```
   - Should return one row with `routine_schema = 'public'`

### Step 2: Configure JWT Secret (CRITICAL - This is why auth.jwt() returns NULL)

The `auth.jwt()->>'sub'` returning NULL means Supabase can't decode Firebase tokens. You need to configure the JWT secret.

**Quick Method:**

1. **Get Firebase Service Account Private Key**
   - Go to: https://console.firebase.google.com/project/vehicle-damage-app/settings/serviceaccounts/adminsdk
   - Click **"Generate new private key"**
   - Download the JSON file
   - Open it and copy the `private_key` value

2. **Format the Private Key**
   - The key in JSON has `\n` escape sequences
   - Convert them to actual newlines:
     - Replace `\\n` with actual line breaks
     - Should look like:
       ```
       -----BEGIN PRIVATE KEY-----
       MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
       (more lines)
       -----END PRIVATE KEY-----
       ```

3. **Set in Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/api
   - Scroll to **"JWT Settings"** section
   - Paste the formatted private key into **"JWT Secret"** field
   - Click **"Save"**
   - ⚠️ Wait for it to complete (should take seconds, not minutes)

4. **Verify JWT is Working**
   - After saving, go back to SQL Editor
   - Run: `SELECT auth.jwt()->>'sub' as firebase_uid;`
   - **Note:** This will still return NULL in SQL Editor because you're not authenticated
   - The real test is in your app after signing in with Firebase

### Step 3: Verify Firebase Third Party Auth Configuration

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk
   - Navigate to **Authentication** → **Providers**

2. **Check Third Party Auth**
   - Look for **"Third Party Auth"** or **"Custom JWT"** section
   - Verify Firebase is listed and **Enabled**
   - If not enabled, enable it and link your Firebase project

3. **Verify Firebase Project Link**
   - Firebase Project ID should be: `vehicle-damage-app`
   - Status should be: **Enabled** or **Active**

### Step 2: Test JWT Extraction in Supabase

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

2. **Test if `auth.jwt()` works**
   ```sql
   SELECT auth.jwt()->>'sub' as firebase_uid;
   ```
   
   **Expected Result:**
   - If Third Party Auth is working: Returns your Firebase UID
   - If not working: Returns `null`

3. **Test `firebase_uid()` function**
   ```sql
   SELECT public.firebase_uid() as firebase_uid;
   ```
   
   **Expected Result:**
   - Should return your Firebase UID
   - If returns `null`, the function exists but `auth.jwt()` is null

### Step 3: Verify `firebase_uid()` Function Exists

Run this query:
```sql
SELECT 
  routine_name,
  routine_schema,
  routine_type
FROM information_schema.routines
WHERE routine_name = 'firebase_uid';
```

**Expected Result:** Should return one row with `routine_schema = 'public'`

**If function doesn't exist**, run this:
```sql
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT AS $$
BEGIN
  RETURN (auth.jwt()->>'sub')::TEXT;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.firebase_uid() TO authenticated;
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO anon;
```

### Step 4: Check RLS Policies

Verify the bookings policy exists:
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'bookings'
AND policyname = 'Customers can create bookings';
```

**Expected Result:** Should return a policy with:
- `cmd = 'INSERT'`
- `with_check` should contain `customer_id = public.firebase_uid()`

### Step 5: Configure JWT Secret (If Needed)

If `auth.jwt()` returns null, you may need to configure the JWT secret:

1. **Get Firebase JWT Secret**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Or use Firebase Admin SDK private key

2. **Set in Supabase** (if Third Party Auth doesn't auto-configure)
   - Go to Supabase Dashboard → Settings → API → JWT Settings
   - See `JWT_CONFIGURATION_GUIDE.md` for details

**Note:** With Third Party Auth properly configured, JWT secret should be automatic.

## 🧪 Test After Fix

After completing the steps above, test in your app:

1. **Sign in with Firebase** in your app
2. **Try creating a booking** again
3. **Check the logs** - you should see:
   - `✅ [FirebaseSupabase] Insert successful`
   - No RLS policy violations

## 🔧 Alternative: Temporary Workaround

If you need a quick workaround while fixing Third Party Auth, you can temporarily disable RLS for testing (NOT for production):

```sql
-- ⚠️ WARNING: Only for testing, NOT for production!
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
```

**Then re-enable after fixing:**
```sql
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
```

## 📋 Verification Checklist

After fixing, verify:

- [ ] Firebase Third Party Auth is enabled in Supabase Dashboard
- [ ] `auth.jwt()->>'sub'` returns Firebase UID (not null)
- [ ] `public.firebase_uid()` function exists and works
- [ ] RLS policies exist for bookings table
- [ ] Can create bookings without RLS violations
- [ ] `customer_id` in booking matches Firebase UID

## 🆘 Still Having Issues?

### Issue: Customer ID Mismatch

**If you see different Firebase UID and Customer ID in error messages:**

```
Current Firebase UID: VZ2bAvAX0ThZ4QArKwhDnD37u652
Customer ID in booking: Z1IsrAdLm5TbYhvlddIVwW33Woe2
```

**Root Cause:** The code is using `userState.userId` which can be stale (loaded from local storage from a previous session), instead of the current Firebase Auth UID.

**Solution:** The code has been fixed to use `userState.currentUser?.uid` first, which always matches the JWT token. If you're still seeing this issue:

1. **Restart your app completely** (not just hot reload)
2. **Clear app data** if the issue persists
3. **Verify the fix** - Check that booking creation uses `currentUser?.uid`

### Issue: auth.jwt() Returns NULL

If `auth.jwt()` still returns null after configuring Third Party Auth:

1. **Check Supabase Logs**
   - Dashboard → Logs → API Logs
   - Look for JWT verification errors

2. **Verify Token Format**
   - Firebase tokens should be JWT format (3 parts separated by `.`)
   - Token should start with `eyJ`

3. **Test with Direct SQL**
   - Try inserting a booking directly in SQL Editor with a hardcoded UID
   - This verifies RLS policies work when UID is known

4. **Contact Supabase Support**
   - If Third Party Auth is configured but still not working
   - Provide your project ID and error logs

## 📚 Related Files

- `FIREBASE_THIRD_PARTY_AUTH_SETUP.md` - Full setup guide
- `JWT_CONFIGURATION_GUIDE.md` - JWT secret configuration
- `database/firebase_authenticated_role_setup.sql` - Function setup
- `supabase/migrations/20240101000005_rls_policies.sql` - RLS policies

