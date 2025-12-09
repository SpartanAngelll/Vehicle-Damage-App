-- Quick Check: Verify Your Account in Supabase
-- Run this FIRST to check table structure, then use the results

-- ==============================================
-- Step 1: Check Table Structure
-- ==============================================
-- First, let's see what columns exist in users table
SELECT 
  'users' as table_name,
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users' 
ORDER BY ordinal_position;

-- Check service_professionals structure
SELECT 
  'service_professionals' as table_name,
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'service_professionals' 
ORDER BY ordinal_position;

-- ==============================================
-- Step 2: Check All Users (Simple)
-- ==============================================
-- This should work regardless of table structure
SELECT 
  firebase_uid,
  email,
  full_name,
  role,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- ==============================================
-- Step 3: Check Service Professionals (Simple)
-- ==============================================
-- Check all service professional profiles
SELECT 
  id,
  user_id,
  business_name,
  years_of_experience,
  created_at
FROM service_professionals
ORDER BY created_at DESC
LIMIT 10;

-- ==============================================
-- Step 4: Find Your Account by Email
-- ==============================================
-- Replace 'your-email@example.com' with your actual email
SELECT 
  firebase_uid,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE email = 'your-email@example.com';  -- Replace with your email

-- ==============================================
-- Step 5: Check if Profile Exists (Using Subquery)
-- ==============================================
-- This avoids JOIN issues
SELECT 
  u.firebase_uid,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM service_professionals sp 
      WHERE sp.user_id = (SELECT id FROM users WHERE firebase_uid = u.firebase_uid)
    ) THEN '✅ Has Profile'
    ELSE '❌ No Profile'
  END as profile_status
FROM users u
WHERE u.email = 'your-email@example.com';  -- Replace with your email

-- ==============================================
-- Step 6: Get Your Profile Details (If Exists)
-- ==============================================
-- Replace 'your-email@example.com' with your actual email
-- This gets your user ID first, then finds the profile
WITH user_info AS (
  SELECT id, firebase_uid, email, full_name
  FROM users
  WHERE email = 'your-email@example.com'  -- Replace with your email
)
SELECT 
  sp.*,
  ui.firebase_uid,
  ui.email,
  ui.full_name
FROM user_info ui
LEFT JOIN service_professionals sp ON sp.user_id = ui.id;

