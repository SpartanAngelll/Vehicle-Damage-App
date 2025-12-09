-- Fixed RLS policies using Firebase UID from JWT
-- This assumes Supabase is configured to extract Firebase UID from JWT 'sub' claim

-- Helper function to get Firebase UID from JWT
-- Note: This requires Supabase JWT secret to be set to Firebase project's secret
CREATE OR REPLACE FUNCTION auth.firebase_uid()
RETURNS TEXT AS $$
BEGIN
  -- Extract 'sub' claim from JWT (Firebase UID)
  RETURN (auth.jwt()->>'sub')::TEXT;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Alternative: If JWT doesn't work, use header-based approach
-- You'll need to create a custom function that reads from request headers
-- This requires Supabase Edge Function or custom middleware

-- For now, use the JWT approach above
-- If that doesn't work, you'll need to:
-- 1. Pass Firebase UID in a custom header
-- 2. Create a function to read from headers
-- 3. Update all policies to use that function

