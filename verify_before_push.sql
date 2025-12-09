-- Verification queries to run BEFORE pushing migration 20240101000010
-- Run these in Supabase SQL Editor to ensure prerequisites are met

-- 1. Check if firebase_uid() function exists (required dependency)
SELECT 
  proname, 
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'firebase_uid';

-- Expected: Should return one row with return_type = 'text'

-- 2. Check if migration 20240101000004 was applied (changes user_id to VARCHAR)
SELECT 
  column_name, 
  data_type, 
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'audit_logs' 
AND column_name = 'user_id';

-- Expected: 
-- data_type = 'character varying'
-- character_maximum_length = 255

-- 3. Check current get_current_user_id function (to see what we're replacing)
SELECT 
  proname, 
  pg_get_function_result(oid) as return_type,
  pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname = 'get_current_user_id';

-- Expected: May return UUID or TEXT depending on current state

-- 4. Check if audit_trigger_function exists
SELECT 
  proname,
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'audit_trigger_function';

-- Expected: Should return one row

-- 5. Check foreign key constraint on audit_logs.user_id
SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'audit_logs'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name = 'user_id';

-- Expected:
-- foreign_table_name = 'users'
-- foreign_column_name = 'firebase_uid'


