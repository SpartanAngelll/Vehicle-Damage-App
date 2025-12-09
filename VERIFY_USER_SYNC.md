# How to Verify Your Account in Supabase

After signing up as a service professional in the app, follow these steps to verify your account was synced to Supabase.

## 🔍 Quick Verification Steps

### Step 1: Get Your Firebase UID

1. **Check your app logs** (the terminal where you ran `flutter run`)
2. Look for a line like:
   ```
   ✅ [FirebaseAuth] User synced to Supabase: zcD6sKY3OrTKaQHJbrsllcsIUnF3
   ```
3. Copy that Firebase UID (the long string after "Supabase: ")

### Step 2: Run Verification Queries

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new

2. **Open the verification script**
   - Open `database/verify_user_in_supabase.sql`
   - Copy the entire file

3. **Replace the placeholder**
   - Find `'YOUR_FIREBASE_UID'` in the queries
   - Replace it with your actual Firebase UID from Step 1
   - Or use your email address if you prefer

4. **Run the queries**
   - Paste into Supabase SQL Editor
   - Click "Run"
   - Review the results

## 📊 What to Look For

### ✅ Success Indicators:

1. **Users Table Check:**
   - Should show your account with:
     - `firebase_uid`: Your Firebase UID
     - `email`: Your email address
     - `role`: `serviceProfessional` or `service_professional`
     - `created_at`: Recent timestamp

2. **Service Professionals Table Check:**
   - Should show your professional profile with:
     - `user_id`: Links to your user account
     - `business_name`: If you entered one
     - `years_of_experience`: Your experience
     - `service_category_ids`: Your selected categories
     - `specializations`: Your specializations

3. **Audit Logs:**
   - Should show entries like:
     - `create_users` - When your user account was created
     - `create_service_professionals` - When your profile was created
     - `update_users` - Any profile updates

## 🐛 Troubleshooting

### Issue: User Not Found in Users Table

**Possible Causes:**
1. **Supabase API key issue** - Check your app logs for errors like:
   ```
   ❌ [FirebaseSupabase] Insert error: PostgrestException(message: Invalid API key...)
   ```

2. **RLS Policy blocking** - The insert might be blocked by Row Level Security

3. **Sync failed** - The sync might have failed silently

**Solutions:**
1. **Check Supabase API keys:**
   - Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your `.env` file
   - Make sure they're correct in Supabase Dashboard → Settings → API

2. **Check app logs:**
   - Look for `✅ [FirebaseAuth] User synced to Supabase` message
   - If you see errors, fix them first

3. **Try manual sync:**
   - Sign out and sign back in
   - This should trigger a sync

### Issue: Service Professional Profile Not Found

**Possible Causes:**
1. **Registration form didn't complete** - The form might have failed silently
2. **Firestore write succeeded but Supabase sync failed**
3. **Profile created in Firestore but not synced to Supabase**

**Solutions:**
1. **Check Firestore:**
   - Go to Firebase Console → Firestore Database
   - Check if profile exists in `service_professionals` collection
   - If it exists in Firestore but not Supabase, there's a sync issue

2. **Check app logs:**
   - Look for errors during registration submission
   - Check for Supabase-related errors

3. **Re-submit registration:**
   - If profile is missing, try completing the registration form again

### Issue: Audit Logs Empty

**Possible Causes:**
1. **Audit logging not set up** - The triggers might not be created
2. **User ID is NULL** - If user wasn't authenticated when creating records

**Solutions:**
1. **Verify audit logging setup:**
   ```sql
   SELECT trigger_name 
   FROM information_schema.triggers 
   WHERE trigger_name LIKE 'audit_%';
   ```
   - Should show 9 triggers

2. **Check if user was authenticated:**
   - Audit logs need the user to be authenticated
   - If you created records via SQL Editor, user_id will be NULL

## 📝 Quick Check Queries

### By Email (Easiest):
```sql
SELECT 
  u.*,
  sp.*
FROM users u
LEFT JOIN service_professionals sp ON sp.user_id = u.id
WHERE u.email = 'your-email@example.com';
```

### By Firebase UID:
```sql
SELECT 
  u.*,
  sp.*
FROM users u
LEFT JOIN service_professionals sp ON sp.user_id = u.id
WHERE u.firebase_uid = 'your-firebase-uid-here';
```

### Recent Users (Last Hour):
```sql
SELECT 
  firebase_uid,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

## ✅ Expected Results

After successful registration, you should see:

1. **In `users` table:**
   - One row with your Firebase UID, email, and role

2. **In `service_professionals` table:**
   - One row linked to your user account with your profile details

3. **In `audit_logs` table:**
   - At least 2 entries:
     - `create_users` action
     - `create_service_professionals` action

## 🆘 Still Having Issues?

If you can't find your account:

1. **Check Supabase Logs:**
   - Dashboard → Logs → Postgres Logs
   - Look for errors around the time you registered

2. **Check RLS Policies:**
   - Make sure RLS allows inserts for authenticated users
   - Run `database/rls_policies_firebase.sql` if needed

3. **Verify Firebase UID Extraction:**
   ```sql
   -- This should work when authenticated with Firebase token
   SELECT public.firebase_uid();
   ```

4. **Check API Connection:**
   - Verify Supabase URL and keys are correct
   - Test connection in your app

---

**Quick Reference:** Use `database/verify_user_in_supabase.sql` for all verification queries.

