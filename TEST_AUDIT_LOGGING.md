# Testing Audit Logging - Quick Guide

## ✅ What You Just Ran

You executed the audit logging setup script, which created:
- **9 automatic triggers** that log all INSERT, UPDATE, DELETE operations
- **5 helper functions** for logging and user tracking
- **Audit log entries** for any operations you perform

## 🧪 Quick Test Steps

### Option 1: Test in Supabase SQL Editor (Easiest)

1. **Open the test script:**
   - Open `database/test_audit_logging.sql` in your editor
   - Copy the entire file

2. **Run in Supabase SQL Editor:**
   - Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new
   - Paste the test script
   - Run it section by section (or all at once)

3. **Check Results:**
   - Each section shows what to expect
   - Verify you see audit log entries being created

### Option 2: Test with Your App (More Realistic)

1. **Sign in to your app** with a test user

2. **Perform some actions:**
   - Create a job request
   - Update your profile
   - Create a booking
   - Submit an estimate

3. **Check audit logs in Supabase:**
   ```sql
   SELECT 
     action,
     resource_type,
     created_at
   FROM audit_logs
   ORDER BY created_at DESC
   LIMIT 10;
   ```

## 📊 What to Look For

### ✅ Success Indicators:

1. **Triggers Exist:**
   - You should see 9 triggers when you run Step 1
   - One for each table: users, job_requests, estimates, bookings, invoices, payment_records, reviews, service_professionals, service_packages

2. **Functions Exist:**
   - You should see 5 functions when you run Step 2
   - All helper functions should be present

3. **Audit Logs Being Created:**
   - When you INSERT/UPDATE/DELETE records, audit logs should appear
   - Check the `audit_logs` table after performing operations

4. **Log Data is Complete:**
   - Each log should have: action, resource_type, resource_id
   - UPDATE logs should have both old_values and new_values
   - DELETE logs should have old_values

### ⚠️ Common Issues:

**Issue: No audit logs being created**
- **Check:** Are triggers actually created? Run Step 1
- **Solution:** Re-run the setup script if triggers are missing

**Issue: user_id is NULL in logs**
- **This is normal** if you're testing in SQL Editor without Firebase authentication
- **In your app:** user_id will be populated when users are authenticated

**Issue: Functions don't exist**
- **Check:** Run Step 2 to verify
- **Solution:** Re-run the setup script

## 🎯 Next Steps After Testing

### 1. Add Login/Logout Tracking

Update your Flutter authentication service to log logins/logouts:

```dart
// In firebase_auth_service.dart or firebase_auth_service_wrapper.dart

Future<void> logUserLogin() async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('log_user_login');
    debugPrint('✅ User login logged');
  } catch (e) {
    debugPrint('⚠️ Failed to log user login: $e');
  }
}

Future<void> logUserLogout() async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('log_user_logout');
    debugPrint('✅ User logout logged');
  } catch (e) {
    debugPrint('⚠️ Failed to log user logout: $e');
  }
}

// Call after successful sign in:
Future<UserCredential?> signInWithEmailAndPassword({
  required String email,
  required String password,
}) async {
  final credential = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  
  // Add this:
  await logUserLogin();
  
  return credential;
}

// Call before sign out:
Future<void> signOut() async {
  // Add this:
  await logUserLogout();
  
  await _auth.signOut();
  await _supabase.client?.auth.signOut();
}
```

### 2. View Audit Logs in Your App (Optional)

Create a simple admin screen to view audit logs:

```dart
// Example query in your app
Future<List<Map<String, dynamic>>> getAuditLogs({
  int limit = 50,
  String? userId,
}) async {
  final supabase = FirebaseSupabaseService.instance;
  
  var query = supabase.client
      ?.from('audit_logs')
      .select('''
        *,
        users:user_id (
          email,
          full_name
        )
      ''')
      .order('created_at', ascending: false)
      .limit(limit);
  
  if (userId != null) {
    query = query?.eq('user_id', userId);
  }
  
  final response = await query;
  return List<Map<String, dynamic>>.from(response ?? []);
}
```

### 3. Monitor Audit Logs

Set up periodic checks:
- Review audit logs weekly/monthly
- Look for suspicious activity
- Track user engagement patterns

## 📝 Useful Queries

### View Recent Activity
```sql
SELECT 
  al.action,
  al.resource_type,
  u.email,
  al.created_at
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
ORDER BY al.created_at DESC
LIMIT 20;
```

### Count Actions by Type
```sql
SELECT 
  action,
  COUNT(*) as count
FROM audit_logs
GROUP BY action
ORDER BY count DESC;
```

### View All User Logins
```sql
SELECT 
  u.email,
  al.created_at as login_time
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.action = 'user_login'
ORDER BY al.created_at DESC;
```

## ✅ Verification Checklist

After running tests, verify:

- [ ] All 9 triggers are created
- [ ] All 5 functions exist
- [ ] INSERT operations create audit logs
- [ ] UPDATE operations create audit logs with old/new values
- [ ] DELETE operations create audit logs with old values
- [ ] Audit logs table is accessible via RLS
- [ ] Can query audit logs successfully

## 🆘 Need Help?

If something isn't working:

1. **Check Supabase Logs:**
   - Dashboard → Logs → Postgres Logs
   - Look for errors related to triggers or functions

2. **Verify RLS Policies:**
   - Make sure RLS is enabled on audit_logs table
   - Check that policies allow system to INSERT

3. **Test Functions Manually:**
   ```sql
   -- Test the audit function
   SELECT public.create_audit_log(
     'test',
     'test_table',
     NULL,
     NULL,
     NULL,
     NULL
   );
   ```

---

**Status:** Ready to test! Run the test script to verify everything is working.

