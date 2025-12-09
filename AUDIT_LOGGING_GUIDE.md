# Audit Logging Guide

## Overview

Your Supabase database now has automatic audit logging capabilities. This system tracks user actions and changes to important data.

## ✅ What's Set Up

### Automatic Logging
The following tables automatically log all INSERT, UPDATE, and DELETE operations:
- `users` - User profile changes
- `job_requests` - Service request creation/updates
- `estimates` - Estimate submissions and changes
- `bookings` - Booking creation and status changes
- `invoices` - Invoice creation and updates
- `payment_records` - Payment transactions
- `reviews` - Review submissions and edits
- `service_professionals` - Professional profile updates
- `service_packages` - Package creation/updates

### What Gets Logged
Each audit log entry contains:
- **User ID** - The UUID of the user who performed the action
- **Action** - Type of action (e.g., `create_users`, `update_bookings`)
- **Resource Type** - The table name
- **Resource ID** - The ID of the affected record
- **Old Values** - Previous state (for updates/deletes)
- **New Values** - New state (for creates/updates)
- **Metadata** - Additional info including Firebase UID
- **Timestamp** - When the action occurred

## 📋 Setup Instructions

### Step 1: Run the Audit Logging Setup Script

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new

2. **Run the Setup Script**
   - Copy and paste the contents of `database/audit_logging_setup.sql`
   - Click "Run" to execute

3. **Verify Setup**
   - Check for any errors in the output
   - Run the verification queries at the bottom of the script

### Step 2: Test Audit Logging

1. **Create a Test Record**
   ```sql
   -- This will automatically create an audit log entry
   INSERT INTO users (firebase_uid, email, role) 
   VALUES ('test-uid-123', 'test@example.com', 'owner');
   ```

2. **Check Audit Logs**
   ```sql
   SELECT * FROM audit_logs 
   WHERE resource_type = 'users' 
   ORDER BY created_at DESC 
   LIMIT 5;
   ```

3. **Update a Record**
   ```sql
   UPDATE users 
   SET full_name = 'Test User' 
   WHERE firebase_uid = 'test-uid-123';
   ```

4. **View the Update Log**
   ```sql
   SELECT 
     action,
     old_values,
     new_values,
     created_at
   FROM audit_logs 
   WHERE resource_type = 'users' 
   AND action = 'update_users'
   ORDER BY created_at DESC 
   LIMIT 1;
   ```

## 🔧 Application-Level Logging

### Login/Logout Tracking

To track user login and logout events, call these functions from your Flutter app:

**In your authentication service:**
```dart
// After successful Firebase sign in
Future<void> logUserLogin() async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('log_user_login');
    debugPrint('✅ User login logged');
  } catch (e) {
    debugPrint('⚠️ Failed to log user login: $e');
  }
}

// Before Firebase sign out
Future<void> logUserLogout() async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('log_user_logout');
    debugPrint('✅ User logout logged');
  } catch (e) {
    debugPrint('⚠️ Failed to log user logout: $e');
  }
}
```

**Update your sign in method:**
```dart
Future<UserCredential?> signInWithEmailAndPassword({
  required String email,
  required String password,
}) async {
  final credential = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  
  // Log the login
  await logUserLogin();
  
  return credential;
}
```

**Update your sign out method:**
```dart
Future<void> signOut() async {
  // Log the logout before signing out
  await logUserLogout();
  
  await _auth.signOut();
  await _supabase.client?.auth.signOut();
}
```

### Custom Action Logging

For custom actions not covered by automatic triggers, use the `create_audit_log` function:

```dart
Future<void> logCustomAction({
  required String action,
  required String resourceType,
  String? resourceId,
  Map<String, dynamic>? metadata,
}) async {
  try {
    final supabase = FirebaseSupabaseService.instance;
    await supabase.client?.rpc('create_audit_log', params: {
      'p_action': action,
      'p_resource_type': resourceType,
      'p_resource_id': resourceId,
      'p_metadata': metadata,
    });
  } catch (e) {
    debugPrint('⚠️ Failed to log custom action: $e');
  }
}

// Example usage:
await logCustomAction(
  action: 'view_profile',
  resourceType: 'users',
  resourceId: otherUserId,
  metadata: {'viewed_from': 'search_results'},
);
```

## 📊 Querying Audit Logs

### View Recent Activity
```sql
SELECT 
  al.id,
  al.action,
  al.resource_type,
  u.email,
  u.full_name,
  al.created_at
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
ORDER BY al.created_at DESC
LIMIT 20;
```

### View Activity for a Specific User
```sql
SELECT 
  action,
  resource_type,
  resource_id,
  created_at
FROM audit_logs
WHERE user_id = (
  SELECT id FROM users WHERE firebase_uid = 'USER_FIREBASE_UID'
)
ORDER BY created_at DESC;
```

### View Changes to a Specific Record
```sql
SELECT 
  action,
  old_values,
  new_values,
  created_at
FROM audit_logs
WHERE resource_type = 'bookings'
AND resource_id = 'BOOKING_ID'
ORDER BY created_at DESC;
```

### View All Login Events
```sql
SELECT 
  u.email,
  u.full_name,
  al.created_at as login_time
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.action = 'user_login'
ORDER BY al.created_at DESC;
```

### Activity Summary by User
```sql
SELECT 
  u.email,
  COUNT(*) as total_actions,
  COUNT(DISTINCT DATE(al.created_at)) as active_days,
  MIN(al.created_at) as first_action,
  MAX(al.created_at) as last_action
FROM audit_logs al
JOIN users u ON al.user_id = u.id
GROUP BY u.id, u.email
ORDER BY total_actions DESC;
```

## 🔒 Security & Privacy

### RLS Policies
- Users can only view their own audit logs
- System can create audit logs (via triggers)
- Admins can view all audit logs (if you add admin role check)

### Data Retention
Consider implementing a cleanup policy for old audit logs:

```sql
-- Delete audit logs older than 1 year
DELETE FROM audit_logs
WHERE created_at < NOW() - INTERVAL '1 year';
```

Or create a scheduled job to run this periodically.

## 🎯 Best Practices

1. **Don't Log Sensitive Data**
   - Audit logs capture full record data
   - Consider excluding sensitive fields (passwords, tokens) from logs
   - Use metadata field for additional context instead of storing sensitive info

2. **Monitor Log Size**
   - Audit logs can grow large quickly
   - Implement retention policies
   - Consider archiving old logs

3. **Use for Compliance**
   - Audit logs help with GDPR, HIPAA, and other compliance requirements
   - Keep logs for required retention periods
   - Ensure proper access controls

4. **Performance Considerations**
   - Triggers add slight overhead to write operations
   - Indexes on audit_logs help query performance
   - Consider partitioning for very large tables

## 🐛 Troubleshooting

### Issue: No Audit Logs Being Created

**Check:**
1. Verify triggers are created:
   ```sql
   SELECT trigger_name, event_object_table
   FROM information_schema.triggers
   WHERE trigger_name LIKE 'audit_%';
   ```

2. Verify functions exist:
   ```sql
   SELECT routine_name
   FROM information_schema.routines
   WHERE routine_name IN ('audit_trigger_function', 'create_audit_log');
   ```

3. Test manually:
   ```sql
   SELECT public.create_audit_log(
     'test_action',
     'test_table',
     NULL,
     NULL,
     NULL,
     '{"test": true}'::JSONB
   );
   ```

### Issue: User ID is NULL in Audit Logs

**Cause:** The user might not exist in the `users` table yet, or Firebase UID isn't being extracted correctly.

**Solution:**
1. Verify user exists:
   ```sql
   SELECT * FROM users WHERE firebase_uid = 'FIREBASE_UID';
   ```

2. Test Firebase UID extraction:
   ```sql
   SELECT public.firebase_uid();
   ```

3. Ensure user is synced to Supabase before performing actions

### Issue: Too Many Audit Logs

**Solution:**
- Implement retention policies
- Consider logging only important actions
- Disable triggers on less critical tables

## 📚 Related Files

- `database/audit_logging_setup.sql` - Setup script
- `database/rls_policies_firebase.sql` - RLS policies for audit_logs
- `database/complete_schema_supabase.sql` - Audit logs table definition

---

**Last Updated:** After Firebase Third Party Auth setup
**Status:** Ready to use after running setup script

