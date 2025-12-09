-- Firebase Third Party Auth - Authenticated Role Setup
-- This script sets up automatic role assignment for Firebase users
-- Run this in Supabase SQL Editor after linking Firebase via Third Party Auth

-- ==============================================
-- Firebase Third Party Auth - Helper Functions
-- ==============================================
-- NOTE: Supabase automatically handles role assignment for Firebase users
-- when Third Party Auth is configured in the dashboard. You don't need to
-- create functions in the auth schema (which requires superuser permissions).
--
-- This script creates helper functions in the public schema that can be used
-- by RLS policies to identify Firebase-authenticated users.

-- ==============================================
-- Create Firebase UID Helper Function
-- ==============================================
-- This function extracts the Firebase UID from the JWT 'sub' claim
-- It works when Supabase Third Party Auth is configured with Firebase

-- Create the function in public schema (more reliable)
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Extract Firebase UID from JWT 'sub' claim
  -- This works when Supabase Third Party Auth is configured
  RETURN (auth.jwt()->>'sub')::TEXT;
END;
$$;

-- Grant execute permission to authenticated role
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO authenticated;
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO anon;

-- ==============================================
-- Verify Setup
-- ==============================================
-- Run these queries to verify everything is set up correctly:

-- 1. Check if firebase_uid function exists
SELECT 
  routine_name,
  routine_schema,
  routine_type
FROM information_schema.routines
WHERE routine_name = 'firebase_uid';

-- 2. Test JWT extraction (this will only work when authenticated with Firebase token)
-- SELECT public.firebase_uid() as firebase_uid;

-- 3. Check current role (should be 'authenticated' when using Firebase token)
-- SELECT current_setting('role', true) as current_role;

-- ==============================================
-- IMPORTANT NOTES
-- ==============================================
-- 1. After linking Firebase via Third Party Auth in Supabase Dashboard,
--    Supabase automatically handles role assignment for Firebase users.
--
-- 2. The firebase_uid() function extracts the Firebase UID from the JWT 'sub' claim.
--
-- 3. RLS policies should use public.firebase_uid() to check user permissions.
--
-- 4. Make sure your RLS policies are applied (see database/rls_policies_firebase.sql)
--
-- 5. Test authentication by:
--    a. Signing in with Firebase in your app
--    b. Making a query to Supabase
--    c. Verifying RLS policies work correctly

