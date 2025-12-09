# Fix Firebase to Supabase User Sync

## Problem
Users are being created in Firebase but not syncing to Supabase (showing 0 users).

## Root Causes

1. **Invalid API Key** - Supabase anon key might be wrong or missing
2. **RLS Policies Blocking** - Row Level Security might be preventing inserts
3. **Token Not Set Correctly** - Firebase token not being passed for Third Party Auth
4. **Silent Failures** - Errors are being caught but not properly handled

## Quick Fixes

### Step 1: Verify Supabase API Keys

1. **Get your Supabase credentials:**
   - Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/settings/api
   - Copy the **Project URL** and **anon public** key

2. **Update your `.env` file:**
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your_actual_anon_key_here
   ```

3. **Restart your app** after updating `.env`

### Step 2: Check RLS Policies

Run this in Supabase SQL Editor to verify RLS allows inserts:

```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- Check if insert policy exists
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'users' 
AND cmd = 'INSERT';

-- If no insert policy, create one:
-- (This should already exist from rls_policies_firebase.sql)
```

### Step 3: Test Manual Insert

Try inserting a user manually to see if RLS is blocking:

```sql
-- This will fail if RLS is blocking
-- You need to be authenticated with a Firebase token
INSERT INTO users (firebase_uid, email, role)
VALUES ('test-uid-123', 'test@example.com', 'owner');
```

### Step 4: Check App Logs

Look for these error messages in your app logs:

**Good signs:**
- `✅ [FirebaseAuth] User synced to Supabase: [UID]`
- `✅ [FirebaseSupabase] Insert successful`

**Bad signs:**
- `❌ [FirebaseSupabase] Insert error: Invalid API key`
- `❌ [FirebaseSupabase] Insert error: new row violates row-level security policy`
- `⚠️ [FirebaseAuth] User created in Firebase but NOT synced to Supabase`

## Code Changes Made

I've updated the sync code to:

1. **Better error handling** - Errors are now logged with full details
2. **Proper token usage** - Firebase token is set before insert
3. **Validation** - Checks if insert actually succeeded
4. **Detailed logging** - Shows exactly what's happening

## Testing

After fixing, test by:

1. **Sign up a new user** in your app
2. **Check app logs** for sync messages
3. **Verify in Supabase:**
   ```sql
   SELECT COUNT(*) FROM users;
   SELECT * FROM users ORDER BY created_at DESC LIMIT 5;
   ```

## Common Issues

### Issue: "Invalid API key"

**Solution:**
- Verify `SUPABASE_ANON_KEY` in `.env` matches Supabase Dashboard
- Make sure there are no extra spaces or quotes
- Restart app after changing `.env`

### Issue: "Row-level security policy violation"

**Solution:**
- Run `database/rls_policies_firebase.sql` in Supabase SQL Editor
- Make sure the insert policy allows authenticated users:
  ```sql
  CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (firebase_uid = public.firebase_uid());
  ```

### Issue: "Supabase client not initialized"

**Solution:**
- Check that Supabase is initialized in `main.dart`
- Verify environment variables are loaded
- Check app startup logs for initialization errors

## Verification Queries

After fixing, run these to verify:

```sql
-- Count users
SELECT COUNT(*) as total_users FROM users;

-- Recent users
SELECT firebase_uid, email, role, created_at 
FROM users 
ORDER BY created_at DESC 
LIMIT 10;

-- Check for your specific user
SELECT * FROM users 
WHERE email = 'your-email@example.com';
```

---

**Status:** Code updated - restart app and test again

