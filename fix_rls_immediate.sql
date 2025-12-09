-- Immediate Fix for RLS Policy Violation
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

-- Step 1: Create the firebase_uid() function
-- This function extracts the Firebase UID from the JWT token
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Extract Firebase UID from JWT 'sub' claim
  -- This will work once JWT secret is configured
  RETURN (auth.jwt()->>'sub')::TEXT;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO authenticated;
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO anon;

-- Step 2: Verify the function was created
SELECT 
  routine_name,
  routine_schema,
  routine_type
FROM information_schema.routines
WHERE routine_name = 'firebase_uid';

-- Expected result: Should return one row with routine_schema = 'public'

-- Step 3: Test (will return NULL until JWT secret is configured)
-- This will return NULL until you configure the JWT secret in Supabase Dashboard
SELECT auth.jwt()->>'sub' as firebase_uid;
SELECT public.firebase_uid() as firebase_uid;

-- Note: These will return NULL until JWT secret is configured
-- See JWT_CONFIGURATION_GUIDE.md for next steps

