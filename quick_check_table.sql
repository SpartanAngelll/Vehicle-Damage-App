-- Quick check: Does users table exist?
-- Run this in Supabase SQL Editor

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'users'
        )
        THEN '✅ users table EXISTS'
        ELSE '❌ users table DOES NOT EXIST - Run complete_schema_supabase.sql again'
    END as status;

-- If table exists, show its structure
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

