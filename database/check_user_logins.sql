-- Check User Logins in Supabase
-- Run these queries to see login activity

-- ==============================================
-- Method 1: Check Audit Logs for Login Events
-- ==============================================
-- If you're using the log_user_login() function, check audit logs
SELECT 
  al.id,
  al.action,
  al.resource_type,
  u.email,
  u.firebase_uid,
  al.metadata->>'firebase_uid' as metadata_firebase_uid,
  al.created_at as login_time
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
WHERE al.action = 'user_login'
ORDER BY al.created_at DESC
LIMIT 20;

-- ==============================================
-- Method 2: Check Users Table for Last Login
-- ==============================================
-- Check users with recent last_login_at timestamps
SELECT 
  firebase_uid,
  email,
  full_name,
  role,
  last_login_at,
  created_at,
  CASE 
    WHEN last_login_at >= NOW() - INTERVAL '24 hours' THEN '✅ Active (last 24h)'
    WHEN last_login_at >= NOW() - INTERVAL '7 days' THEN '🟡 Active (last week)'
    WHEN last_login_at IS NULL THEN '❌ Never logged in'
    ELSE '⚪ Inactive'
  END as login_status
FROM users
ORDER BY last_login_at DESC NULLS LAST
LIMIT 20;

-- ==============================================
-- Method 3: Recent Logins (Last 24 Hours)
-- ==============================================
SELECT 
  u.email,
  u.firebase_uid,
  u.full_name,
  u.last_login_at,
  COUNT(al.id) as login_count_today
FROM users u
LEFT JOIN audit_logs al ON al.user_id = u.id 
  AND al.action = 'user_login'
  AND al.created_at >= CURRENT_DATE
WHERE u.last_login_at >= NOW() - INTERVAL '24 hours'
GROUP BY u.id, u.email, u.firebase_uid, u.full_name, u.last_login_at
ORDER BY u.last_login_at DESC;

-- ==============================================
-- Method 4: Login Activity Summary
-- ==============================================
SELECT 
  DATE(al.created_at) as login_date,
  COUNT(*) as total_logins,
  COUNT(DISTINCT al.user_id) as unique_users
FROM audit_logs al
WHERE al.action = 'user_login'
  AND al.created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(al.created_at)
ORDER BY login_date DESC;

-- ==============================================
-- Method 5: Check All Recent Activity (Logins + Other Actions)
-- ==============================================
SELECT 
  al.action,
  al.resource_type,
  u.email,
  u.firebase_uid,
  al.created_at,
  CASE 
    WHEN al.action = 'user_login' THEN '🔐 Login'
    WHEN al.action = 'user_logout' THEN '🚪 Logout'
    WHEN al.action LIKE 'create_%' THEN '➕ Create'
    WHEN al.action LIKE 'update_%' THEN '✏️ Update'
    WHEN al.action LIKE 'delete_%' THEN '🗑️ Delete'
    ELSE '📝 Other'
  END as action_type
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
WHERE al.action IN ('user_login', 'user_logout')
   OR al.resource_type = 'authentication'
ORDER BY al.created_at DESC
LIMIT 50;

-- ==============================================
-- Method 6: Users Who Logged In Today
-- ==============================================
SELECT 
  u.email,
  u.firebase_uid,
  u.full_name,
  u.role,
  u.last_login_at,
  (SELECT COUNT(*) 
   FROM audit_logs al2 
   WHERE al2.user_id = u.id 
     AND al2.action = 'user_login'
     AND DATE(al2.created_at) = CURRENT_DATE
  ) as logins_today
FROM users u
WHERE u.last_login_at >= CURRENT_DATE
   OR EXISTS (
     SELECT 1 
     FROM audit_logs al 
     WHERE al.user_id = u.id 
       AND al.action = 'user_login'
       AND DATE(al.created_at) = CURRENT_DATE
   )
ORDER BY u.last_login_at DESC;

-- ==============================================
-- Method 7: Most Active Users (by login count)
-- ==============================================
SELECT 
  u.email,
  u.firebase_uid,
  u.full_name,
  COUNT(al.id) as total_logins,
  MAX(al.created_at) as last_login,
  MIN(al.created_at) as first_login
FROM users u
LEFT JOIN audit_logs al ON al.user_id = u.id 
  AND al.action = 'user_login'
GROUP BY u.id, u.email, u.firebase_uid, u.full_name
HAVING COUNT(al.id) > 0
ORDER BY total_logins DESC
LIMIT 20;

-- ==============================================
-- Method 8: Check if Login Tracking is Working
-- ==============================================
-- This checks if the log_user_login function exists and if there are any login logs
SELECT 
  'Login Function Exists' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_name = 'log_user_login'
    ) THEN '✅ Yes'
    ELSE '❌ No - Run database/audit_logging_setup.sql'
  END as status
UNION ALL
SELECT 
  'Login Logs Found' as check_type,
  CASE 
    WHEN EXISTS (SELECT 1 FROM audit_logs WHERE action = 'user_login')
    THEN CONCAT('✅ Yes (', COUNT(*)::TEXT, ' logins)')
    ELSE '❌ No - Users may not be calling log_user_login()'
  END as status
FROM audit_logs
WHERE action = 'user_login';

-- ==============================================
-- Quick Check: Recent Logins (Simple)
-- ==============================================
-- Just show the most recent login attempts
SELECT 
  u.email,
  al.created_at as login_time,
  al.metadata
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.action = 'user_login'
ORDER BY al.created_at DESC
LIMIT 10;

