-- Quick verification query to check if tables were created
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

-- 1. Check if users table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')
        THEN '✅ users table EXISTS'
        ELSE '❌ users table DOES NOT EXIST'
    END as users_table_status;

-- 2. List all tables in public schema
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 3. If users table exists, show its structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 4. Count rows in users table (if it exists)
SELECT COUNT(*) as user_count FROM users;

