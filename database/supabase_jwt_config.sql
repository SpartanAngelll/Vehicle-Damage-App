-- Configure Supabase to accept Firebase JWT tokens
-- This requires setting JWT secret in Supabase dashboard
-- Go to Settings > API > JWT Settings

-- The JWT secret should be your Firebase project's JWT secret
-- You can get this from Firebase Console > Project Settings > Service Accounts

-- After setting the JWT secret, Supabase will be able to decode Firebase tokens
-- and extract the 'sub' claim (Firebase UID) using auth.jwt()->>'sub'

-- Verify JWT configuration:
SELECT 
  current_setting('app.settings.jwt_secret', true) as jwt_secret_configured;

-- Note: The actual JWT secret must be set in Supabase dashboard, not via SQL

