# How to Check User Logins in Supabase

Since you're using Firebase Third Party Auth, login tracking works differently than native Supabase Auth. Here are several ways to check login activity.

## 🔍 Quick Methods

### Method 1: Check Audit Logs (If Login Tracking is Enabled)

If you've set up login tracking in your app, check audit logs:

```sql
SELECT 
  u.email,
  u.firebase_uid,
  al.created_at as login_time
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.action = 'user_login'
ORDER BY al.created_at DESC
LIMIT 20;
```

### Method 2: Check Users Table (Last Login Timestamp)

Check the `last_login_at` field in the users table:

```sql
SELECT 
  email,
  firebase_uid,
  last_login_at,
  created_at
FROM users
WHERE last_login_at IS NOT NULL
ORDER BY last_login_at DESC
LIMIT 20;
```

### Method 3: Recent Activity (Last 24 Hours)

```sql
SELECT 
  u.email,
  u.last_login_at,
  COUNT(al.id) as login_count
FROM users u
LEFT JOIN audit_logs al ON al.user_id = u.id 
  AND al.action = 'user_login'
  AND al.created_at >= NOW() - INTERVAL '24 hours'
WHERE u.last_login_at >= NOW() - INTERVAL '24 hours'
GROUP BY u.id, u.email, u.last_login_at
ORDER BY u.last_login_at DESC;
```

## 📊 Complete Login Report

Use the queries in `database/check_user_logins.sql` for comprehensive login tracking:

1. **Recent logins** - Last 20 login events
2. **Login activity summary** - Logins per day
3. **Most active users** - Users with most logins
4. **Today's logins** - All logins today
5. **Login status check** - Verify if tracking is working

## ⚠️ Important Notes

### Login Tracking Requires App Code

For login events to appear in audit logs, your app needs to call `log_user_login()`:

**Current Status:**
- ✅ Audit logging setup script exists (`database/audit_logging_setup.sql`)
- ⚠️ App code may not be calling `log_user_login()` yet

### Enable Login Tracking in Your App

Add this to your authentication service:

```dart
// After successful sign in
Future<void> logUserLogin() async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('log_user_login');
    debugPrint('✅ User login logged');
  } catch (e) {
    debugPrint('⚠️ Failed to log user login: $e');
  }
}

// Call it after sign in:
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
```

## 🔧 Alternative: Use last_login_at Field

If you're not using audit logs, you can update `last_login_at` directly:

```sql
-- Update last_login_at when user signs in
UPDATE users
SET last_login_at = NOW(),
    updated_at = NOW()
WHERE firebase_uid = 'USER_FIREBASE_UID';
```

Or add this to your sync code to update it automatically.

## 📈 Login Statistics

### Daily Login Count
```sql
SELECT 
  DATE(created_at) as date,
  COUNT(*) as logins
FROM audit_logs
WHERE action = 'user_login'
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 30;
```

### Active Users This Week
```sql
SELECT COUNT(DISTINCT user_id) as active_users
FROM audit_logs
WHERE action = 'user_login'
  AND created_at >= NOW() - INTERVAL '7 days';
```

## 🐛 Troubleshooting

### No Login Logs Found

**Possible Causes:**
1. `log_user_login()` function doesn't exist
2. App code isn't calling the function
3. RLS policies blocking the insert

**Solutions:**
1. Run `database/audit_logging_setup.sql` to create the function
2. Add login tracking to your app code (see above)
3. Check RLS policies allow audit log inserts

### last_login_at is NULL

**Solution:**
- Update the sync code to set `last_login_at` when users sign in
- Or manually update: `UPDATE users SET last_login_at = NOW() WHERE ...`

## 📝 Quick Reference

**Check recent logins:**
```sql
SELECT * FROM audit_logs 
WHERE action = 'user_login' 
ORDER BY created_at DESC 
LIMIT 10;
```

**Check users with recent logins:**
```sql
SELECT * FROM users 
WHERE last_login_at >= NOW() - INTERVAL '24 hours'
ORDER BY last_login_at DESC;
```

**Count total logins:**
```sql
SELECT COUNT(*) FROM audit_logs 
WHERE action = 'user_login';
```

---

**See:** `database/check_user_logins.sql` for all queries

