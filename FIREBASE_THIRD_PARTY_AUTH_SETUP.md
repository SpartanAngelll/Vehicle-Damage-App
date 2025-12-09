# Firebase Third Party Auth Setup Guide

## ✅ What You've Completed

You've successfully linked your Firebase project (`vehicle-damage-app`) to Supabase using Third Party Auth. This is a critical step that allows Supabase to accept Firebase JWT tokens.

## 🔧 Next Steps Required

According to Supabase's documentation, after linking Firebase via Third Party Auth, you need to:

1. ✅ **Link Firebase Project** (COMPLETED)
   - Firebase Project ID: `vehicle-damage-app`
   - Status: Enabled

2. ⚠️ **Set Up RLS Policies** (NEEDS VERIFICATION)
   - RLS policies must be configured for all tables
   - Policies should use Firebase UID from JWT tokens

3. ⚠️ **Set Authenticated Role** (NEEDS SETUP)
   - Custom code needed to grant `authenticated` role to Firebase users
   - This ensures RLS policies work correctly

4. ⚠️ **Configure JWT Secret** (MAY BE NEEDED)
   - Some setups require JWT secret configuration
   - Check if this is needed for your setup

---

## 📋 Step-by-Step Setup Instructions

### Step 1: Run Authenticated Role Setup

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new

2. **Run the Role Setup Script**
   - Copy and paste the contents of `database/firebase_authenticated_role_setup.sql`
   - Click "Run" to execute

3. **Verify Setup**
   - The script will create functions needed for role mapping
   - Check for any errors in the output

### Step 2: Verify RLS Policies

1. **Check if RLS is Enabled**
   - Run this query in Supabase SQL Editor:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename IN ('users', 'bookings', 'job_requests', 'estimates');
   ```
   - All tables should show `rowsecurity = true`

2. **Apply RLS Policies (if not already done)**
   - Run `database/rls_policies_firebase.sql` in Supabase SQL Editor
   - This will create all necessary RLS policies

3. **Verify Policies Exist**
   ```sql
   SELECT schemaname, tablename, policyname 
   FROM pg_policies 
   WHERE schemaname = 'public'
   ORDER BY tablename, policyname;
   ```

### Step 3: Test Authentication Flow

1. **Test in Your Flutter App**
   ```dart
   // Sign in with Firebase
   final auth = FirebaseAuthServiceWrapper.instance;
   final user = await auth.signInWithEmailAndPassword(
     email: 'test@example.com',
     password: 'password123',
   );
   
   // Query Supabase - should work with RLS
   final supabase = FirebaseSupabaseService.instance;
   final result = await supabase.query(
     table: 'users',
     filters: {'firebase_uid': user?.uid},
   );
   ```

2. **Verify in Supabase Dashboard**
   - Go to Authentication → Users
   - You should see Firebase users appearing (if using Supabase Auth sync)
   - Or check the `users` table directly

### Step 4: Verify JWT Configuration (Optional)

If RLS policies aren't working, you may need to configure JWT:

1. **Check JWT Settings**
   - Go to Supabase Dashboard → Settings → API → JWT Settings
   - Verify if JWT secret needs to be set
   - See `JWT_CONFIGURATION_GUIDE.md` for detailed instructions

2. **Test JWT Extraction**
   - After authenticating with Firebase, run this in SQL Editor:
   ```sql
   SELECT public.firebase_uid() as firebase_uid;
   ```
   - This should return your Firebase UID

---

## 🔍 Troubleshooting

### Issue: RLS Policies Blocking All Queries

**Symptoms:**
- All Supabase queries return empty results
- RLS policy violations in logs

**Solution:**
1. Verify `firebase_uid()` function exists:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_name = 'firebase_uid';
   ```

2. Test JWT extraction:
   ```sql
   SELECT auth.jwt()->>'sub' as firebase_uid;
   ```

3. If this returns NULL, JWT configuration may be needed (see `JWT_CONFIGURATION_GUIDE.md`)

### Issue: "Role 'authenticated' does not exist"

**Solution:**
- Run `database/firebase_authenticated_role_setup.sql`
- This creates the necessary role mapping functions

### Issue: Firebase Users Not Appearing in Supabase

**Note:** With Third Party Auth, Firebase users don't automatically appear in Supabase Auth. They exist only in your `users` table.

**Solution:**
- This is expected behavior
- Users are synced to the `users` table via your app code
- Check the `users` table, not Authentication → Users

---

## 📝 Important Notes

1. **Third Party Auth vs Supabase Auth**
   - Firebase users authenticate with Firebase, not Supabase Auth
   - Supabase only verifies the Firebase JWT token
   - Users exist in your `users` table, not Supabase Auth

2. **RLS Policy Function**
   - Use `public.firebase_uid()` in RLS policies
   - This extracts the Firebase UID from the JWT `sub` claim
   - The function is created by `firebase_authenticated_role_setup.sql`

3. **Token Passing**
   - Your Flutter app should pass Firebase ID tokens to Supabase
   - The `FirebaseSupabaseService` handles this automatically
   - Tokens are passed in the `Authorization` header

4. **Role Assignment**
   - Supabase automatically assigns the `authenticated` role when Third Party Auth is configured
   - The setup script ensures this works correctly

---

## ✅ Verification Checklist

After completing setup, verify:

- [ ] `firebase_uid()` function exists in `public` schema
- [ ] RLS is enabled on all tables
- [ ] RLS policies exist for all tables
- [ ] Can authenticate with Firebase in app
- [ ] Can query Supabase tables with RLS working
- [ ] `auth.jwt()->>'sub'` returns Firebase UID when authenticated
- [ ] No RLS policy violations in Supabase logs

---

## 📚 Related Documentation

- `JWT_CONFIGURATION_GUIDE.md` - Detailed JWT setup (if needed)
- `database/rls_policies_firebase.sql` - RLS policies
- `database/firebase_authenticated_role_setup.sql` - Role setup
- `TESTING_GUIDE.md` - Testing procedures

---

## 🆘 Need Help?

If you encounter issues:

1. Check Supabase logs: Dashboard → Logs → Postgres Logs
2. Check RLS policy violations: Dashboard → Logs → API Logs
3. Verify Firebase token is being passed correctly
4. Test JWT extraction in SQL Editor
5. Review `JWT_CONFIGURATION_GUIDE.md` for JWT setup

---

**Last Updated:** After Firebase Third Party Auth linking
**Status:** Setup in progress - follow steps above

