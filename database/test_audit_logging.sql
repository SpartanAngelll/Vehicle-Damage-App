-- Test Audit Logging Setup
-- Run these queries one by one to verify audit logging is working

-- ==============================================
-- Step 1: Verify Triggers Are Created
-- ==============================================
SELECT 
  trigger_name, 
  event_object_table, 
  action_timing, 
  event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name LIKE 'audit_%'
ORDER BY event_object_table, trigger_name;

-- Expected: You should see triggers for:
-- - audit_users_trigger
-- - audit_job_requests_trigger
-- - audit_estimates_trigger
-- - audit_bookings_trigger
-- - audit_invoices_trigger
-- - audit_payment_records_trigger
-- - audit_reviews_trigger
-- - audit_service_professionals_trigger
-- - audit_service_packages_trigger

-- ==============================================
-- Step 2: Verify Functions Exist
-- ==============================================
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
  'audit_trigger_function',
  'create_audit_log',
  'get_current_user_id',
  'log_user_login',
  'log_user_logout'
)
ORDER BY routine_name;

-- Expected: You should see all 5 functions listed

-- ==============================================
-- Step 3: Test Audit Logging with a Test Record
-- ==============================================
-- First, check if you have any existing users
SELECT firebase_uid, email FROM users LIMIT 5;

-- If you have a user, use their ID for testing
-- Otherwise, create a test user (this will create an audit log)
-- NOTE: Replace 'your-firebase-uid-here' with an actual Firebase UID from your app
-- Or skip this if you already have users

-- ==============================================
-- Step 4: Test INSERT Logging
-- ==============================================
-- Create a test service category (if it doesn't exist)
-- This will automatically create an audit log
INSERT INTO service_categories (name, description, icon_name)
VALUES ('Test Category', 'Test category for audit logging', 'test')
ON CONFLICT DO NOTHING;

-- Check if audit log was created
SELECT 
  id,
  action,
  resource_type,
  resource_id,
  created_at
FROM audit_logs
WHERE resource_type = 'service_categories'
ORDER BY created_at DESC
LIMIT 1;

-- Expected: You should see a log entry with action like 'create_service_categories'

-- ==============================================
-- Step 5: Test UPDATE Logging
-- ==============================================
-- Update the test category
UPDATE service_categories
SET description = 'Updated test category'
WHERE name = 'Test Category';

-- Check the audit log for the update
SELECT 
  id,
  action,
  resource_type,
  old_values,
  new_values,
  created_at
FROM audit_logs
WHERE resource_type = 'service_categories'
AND action = 'update_service_categories'
ORDER BY created_at DESC
LIMIT 1;

-- Expected: You should see:
-- - action: 'update_service_categories'
-- - old_values: JSON with previous description
-- - new_values: JSON with updated description

-- ==============================================
-- Step 6: View Recent Audit Logs
-- ==============================================
SELECT 
  al.id,
  al.action,
  al.resource_type,
  al.resource_id,
  u.email,
  al.created_at
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.firebase_uid
ORDER BY al.created_at DESC
LIMIT 10;

-- Expected: You should see recent audit log entries
-- Note: user_id might be NULL if you're not authenticated with a Firebase token

-- ==============================================
-- Step 7: Test Manual Audit Log Creation
-- ==============================================
-- Test the create_audit_log function directly
-- This should work even without authentication
SELECT public.create_audit_log(
  'test_action',
  'test_table',
  NULL,
  NULL,
  '{"test": "value"}'::JSONB,
  '{"source": "manual_test"}'::JSONB
) as log_id;

-- Check if the log was created
SELECT 
  id,
  action,
  resource_type,
  new_values,
  metadata
FROM audit_logs
WHERE action = 'test_action'
ORDER BY created_at DESC
LIMIT 1;

-- Expected: You should see a log entry with your test data

-- ==============================================
-- Step 8: Test Login/Logout Functions (Optional)
-- ==============================================
-- These require authentication with a Firebase token
-- You'll need to call these from your Flutter app, not SQL Editor
-- But you can verify they exist:

SELECT routine_name 
FROM information_schema.routines
WHERE routine_name IN ('log_user_login', 'log_user_logout');

-- Expected: Both functions should exist

-- ==============================================
-- Verification Summary
-- ==============================================
-- Run this to see a summary of your audit logging setup:

SELECT 
  'Triggers' as component,
  COUNT(*)::TEXT as count
FROM information_schema.triggers
WHERE trigger_name LIKE 'audit_%'
UNION ALL
SELECT 
  'Functions' as component,
  COUNT(*)::TEXT as count
FROM information_schema.routines
WHERE routine_name IN (
  'audit_trigger_function',
  'create_audit_log',
  'get_current_user_id',
  'log_user_login',
  'log_user_logout'
)
UNION ALL
SELECT 
  'Audit Log Entries' as component,
  COUNT(*)::TEXT as count
FROM audit_logs;

-- Expected: 
-- - Triggers: 9 (one for each table)
-- - Functions: 5
-- - Audit Log Entries: Should be > 0 if you ran the tests above

