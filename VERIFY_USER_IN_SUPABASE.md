# Verify User in Supabase Database

This guide helps you verify if a new user was successfully created in your Supabase database.

## Method 1: Using Supabase SQL Editor (Recommended)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk
   - Navigate to **SQL Editor** (left sidebar)

2. **Run Verification Queries**
   - Open the file: `database/check_user_in_supabase.sql`
   - Copy and paste the queries into the SQL Editor
   - Click **Run** to execute

3. **Check Results**
   - The queries will show:
     - All users in the database
     - Total user count
     - Users by role
     - Recent users (last 24 hours)
     - Users without Firebase UID (should be none)

## Method 2: Using Backend API

If your backend server is running, you can use these endpoints:

### 1. Get All Users
```bash
curl http://localhost:3000/api/users
```

Or in PowerShell:
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/users" | ConvertTo-Json
```

### 2. Get User by Firebase UID
Replace `YOUR_FIREBASE_UID` with the actual Firebase UID from your app logs:
```bash
curl http://localhost:3000/api/users/firebase/YOUR_FIREBASE_UID
```

### 3. Get User Statistics
```bash
curl http://localhost:3000/api/users/stats
```

## Method 3: Using Supabase Dashboard Table Editor

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk
   - Navigate to **Table Editor** (left sidebar)
   - Click on **users** table

2. **View Users**
   - You'll see all users in a table format
   - Check the `firebase_uid` column to find your user
   - Look at `created_at` to see when the user was created

## Method 4: Check App Logs

When you create a new user, look for these log messages:

### Success Messages:
- `✅ [FirebaseAuth] User synced to Supabase: [UID]`
- `✅ [FirebaseAuth] User updated in Supabase: [UID]`

### Warning Messages (User created but not synced):
- `⚠️ [FirebaseAuth] Failed to sync user to Supabase: [error]`
- `⚠️ [FirebaseAuth] User created in Firebase but not in Supabase`

## What to Check

### ✅ User Should Have:
- `firebase_uid` - Matches Firebase Authentication UID
- `email` - User's email address
- `role` - Either 'owner', 'repairman', or 'serviceProfessional'
- `created_at` - Timestamp when user was created
- `is_active` - Should be `true`

### ❌ Common Issues:

1. **User Not Found in Supabase**
   - **Cause**: Supabase sync failed during signup
   - **Solution**: The auth service now automatically syncs users. Try signing in again, or manually sync using the backend API

2. **User Exists but Missing Data**
   - **Cause**: Partial sync or missing fields
   - **Solution**: Check app logs for sync errors

3. **Multiple Users with Same Email**
   - **Cause**: User created multiple times
   - **Solution**: Check `firebase_uid` - each should be unique

## Quick Verification SQL Query

Run this in Supabase SQL Editor to quickly check for your user:

```sql
-- Replace 'YOUR_EMAIL' with the email you used to sign up
SELECT 
    id,
    firebase_uid,
    email,
    full_name,
    role,
    created_at,
    updated_at
FROM users
WHERE email = 'YOUR_EMAIL'
ORDER BY created_at DESC;
```

## Manual Sync (If User Not Found)

If a user exists in Firebase but not in Supabase, you can manually sync them:

1. **Get Firebase UID** from Firebase Console or app logs
2. **Use Backend API** to create the user (if you have an endpoint)
3. **Or use Supabase SQL Editor**:

```sql
-- Replace with actual values
INSERT INTO users (
    firebase_uid,
    email,
    full_name,
    role,
    created_at,
    updated_at
) VALUES (
    'YOUR_FIREBASE_UID',
    'user@example.com',
    'User Name',
    'owner',
    NOW(),
    NOW()
);
```

## Next Steps

After verifying the user exists:

1. ✅ Check if user profile is complete
2. ✅ Verify role is correct
3. ✅ Test user can sign in
4. ✅ Check if service professional profile exists (if applicable)

## Troubleshooting

### Backend API Not Working
- Make sure backend server is running: `cd backend && node server.js`
- Check backend `.env` file has correct Supabase credentials
- Verify database connection in backend logs

### Supabase SQL Editor Not Working
- Make sure you're logged into Supabase Dashboard
- Check you have the correct project selected
- Verify RLS policies allow you to read the users table

### User Sync Failing
- Check Supabase service is initialized in `main.dart`
- Verify `SUPABASE_ANON_KEY` is set in `.env` file
- Check app logs for specific error messages
- Ensure network connectivity to Supabase

