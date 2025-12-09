-- Complete setup script for Firebase + Supabase integration
-- Run these in order:

-- 1. Run complete_schema_supabase.sql first
-- 2. Run firebase_uid_migration.sql
-- 3. Run rls_policies_firebase.sql
-- 4. Run workflow_functions.sql

-- Verify setup:
SELECT 
  'Tables created' as check_type,
  COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';

SELECT 
  'RLS enabled' as check_type,
  COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public' 
  AND rowsecurity = true;

SELECT 
  'Policies created' as check_type,
  COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public';

SELECT 
  'Functions created' as check_type,
  COUNT(*) as count
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname IN ('create_job_request', 'accept_request', 'complete_job', 'record_payment', 'leave_review');

