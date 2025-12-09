-- Verify User Account in Supabase
-- Run this in Supabase SQL Editor to check if your new account was synced
-- Replace 'YOUR_FIREBASE_UID' with your actual Firebase UID from the app logs

-- ==============================================
-- Step 1: Find Your Firebase UID
-- ==============================================
-- Look in your app logs for a line like:
-- "✅ [FirebaseAuth] User synced to Supabase: zcD6sKY3OrTKaQHJbrsllcsIUnF3"
-- That's your Firebase UID - use it in the queries below

-- ==============================================
-- Step 2: Check Users Table
-- ==============================================
-- Replace 'YOUR_FIREBASE_UID' with your actual Firebase UID
SELECT 
  id,
  firebase_uid,
  email,
  full_name,
  phone_number,
  role,
  is_verified,
  is_active,
  created_at,
  updated_at
FROM users
WHERE firebase_uid = 'YOUR_FIREBASE_UID';  -- Replace with your Firebase UID

-- Or search by email if you know it:
-- WHERE email = 'your-email@example.com';

-- ==============================================
-- Step 3: Check Service Professionals Table
-- ==============================================
-- This checks if your service professional profile was created
-- First, let's check what columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Then check service_professionals structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'service_professionals' 
ORDER BY ordinal_position;

-- Now check if service professional profile exists
-- Try joining by user_id UUID first
SELECT 
  sp.id,
  sp.user_id,
  u.firebase_uid,
  u.email,
  sp.business_name,
  sp.business_address,
  sp.years_of_experience,
  sp.average_rating,
  sp.is_available,
  sp.service_areas,
  sp.specializations,
  sp.service_category_ids,
  sp.created_at,
  sp.updated_at
FROM service_professionals sp
JOIN users u ON sp.user_id = u.id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID';  -- Replace with your Firebase UID

-- Alternative: If the above fails, try this (in case user_id is Firebase UID)
SELECT 
  sp.*,
  u.firebase_uid,
  u.email
FROM service_professionals sp
JOIN users u ON sp.user_id::TEXT = u.firebase_uid
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID';  -- Replace with your Firebase UID

-- ==============================================
-- Step 4: Check All Recent Users
-- ==============================================
-- See all users created recently (last 24 hours)
SELECT 
  firebase_uid,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- ==============================================
-- Step 5: Check Audit Logs for Your Account
-- ==============================================
-- See what actions were logged for your account
SELECT 
  al.id,
  al.action,
  al.resource_type,
  al.resource_id,
  al.created_at,
  u.email,
  u.firebase_uid
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID'  -- Replace with your Firebase UID
   OR al.metadata->>'firebase_uid' = 'YOUR_FIREBASE_UID'  -- Also check metadata
ORDER BY al.created_at DESC
LIMIT 20;

-- ==============================================
-- Step 6: Quick Summary Check
-- ==============================================
-- Get a summary of your account status
SELECT 
  'User Account' as check_type,
  CASE 
    WHEN EXISTS (SELECT 1 FROM users WHERE firebase_uid = 'YOUR_FIREBASE_UID') 
    THEN '✅ Found'
    ELSE '❌ Not Found'
  END as status,
  (SELECT COUNT(*) FROM users WHERE firebase_uid = 'YOUR_FIREBASE_UID') as count
UNION ALL
SELECT 
  'Service Professional Profile' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM service_professionals sp
      JOIN users u ON sp.user_id = u.id
      WHERE u.firebase_uid = 'YOUR_FIREBASE_UID'
    )
    THEN '✅ Found'
    ELSE '❌ Not Found'
  END as status,
  (SELECT COUNT(*) FROM service_professionals sp
   JOIN users u ON sp.user_id = u.id
   WHERE u.firebase_uid = 'YOUR_FIREBASE_UID') as count
UNION ALL
SELECT 
  'Audit Logs' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      WHERE u.firebase_uid = 'YOUR_FIREBASE_UID'
         OR al.metadata->>'firebase_uid' = 'YOUR_FIREBASE_UID'
    )
    THEN '✅ Found'
    ELSE '❌ Not Found'
  END as status,
  (SELECT COUNT(*) FROM audit_logs al
   LEFT JOIN users u ON al.user_id = u.id
   WHERE u.firebase_uid = 'YOUR_FIREBASE_UID'
      OR al.metadata->>'firebase_uid' = 'YOUR_FIREBASE_UID') as count;

-- ==============================================
-- Alternative: Search by Email
-- ==============================================
-- If you don't know your Firebase UID, search by email:
-- Replace 'your-email@example.com' with your actual email

-- First check if users table has id column
SELECT 
  u.firebase_uid,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM service_professionals sp 
      WHERE sp.user_id = u.id
    ) THEN '✅ Has Service Professional Profile'
    ELSE '❌ No Service Professional Profile'
  END as profile_status
FROM users u
WHERE u.email = 'your-email@example.com';  -- Replace with your email

-- Also show the profile if it exists
SELECT 
  sp.*,
  u.firebase_uid,
  u.email,
  u.full_name
FROM users u
LEFT JOIN service_professionals sp ON sp.user_id = u.id
WHERE u.email = 'your-email@example.com';  -- Replace with your email

