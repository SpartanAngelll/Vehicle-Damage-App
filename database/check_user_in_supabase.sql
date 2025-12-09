-- Check if a user was created in Supabase
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new

-- 1. List all users in the database
SELECT 
    id,
    firebase_uid,
    email,
    full_name,
    display_name,
    role,
    phone_number,
    is_verified,
    is_active,
    created_at,
    updated_at
FROM users
ORDER BY created_at DESC
LIMIT 20;

-- 2. Count total users
SELECT COUNT(*) as total_users FROM users;

-- 3. Count users by role
SELECT 
    role,
    COUNT(*) as count
FROM users
GROUP BY role
ORDER BY count DESC;

-- 4. Check for recent users (last 24 hours)
SELECT 
    id,
    firebase_uid,
    email,
    full_name,
    role,
    created_at
FROM users
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 5. Check if a specific Firebase UID exists (replace 'YOUR_FIREBASE_UID' with actual UID)
-- SELECT 
--     id,
--     firebase_uid,
--     email,
--     full_name,
--     role,
--     created_at,
--     updated_at
-- FROM users
-- WHERE firebase_uid = 'YOUR_FIREBASE_UID';

-- 6. Check for users without Firebase UID (should be none if migration worked)
SELECT 
    id,
    email,
    full_name,
    role,
    created_at
FROM users
WHERE firebase_uid IS NULL OR firebase_uid = '';

-- 7. Check service_professionals table for extended profiles
SELECT 
    sp.id,
    sp.user_id,
    u.email,
    u.full_name,
    sp.business_name,
    sp.created_at
FROM service_professionals sp
JOIN users u ON sp.user_id = u.id
ORDER BY sp.created_at DESC
LIMIT 10;

