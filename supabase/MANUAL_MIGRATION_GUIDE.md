# Manual Migration Guide

If `npx supabase db push` times out, you can apply migrations manually via Supabase SQL Editor.

## Status Check

Most migrations appear to already be applied. Check what's missing:

1. Go to Supabase Dashboard → SQL Editor
2. Run this query to see applied migrations:

```sql
SELECT * FROM supabase_migrations.schema_migrations 
ORDER BY version DESC;
```

## Remaining Migrations to Apply

Based on the error, these migrations likely need to be applied manually:

### 1. RLS Policies (20240101000005_rls_policies.sql)

**Important:** This enables Row Level Security with Firebase authentication.

1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `supabase/migrations/20240101000005_rls_policies.sql`
3. Click "Run"

**Note:** If you get permission errors on `auth.jwt()`, the function might need to be created differently. Try this alternative:

```sql
-- Alternative Firebase UID function
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT AS $$
BEGIN
  -- Extract 'sub' claim from JWT (Firebase UID)
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'sub')::TEXT,
    (auth.jwt()->>'sub')::TEXT
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

### 2. Workflow Functions (20240101000006_workflow_functions.sql)

1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `supabase/migrations/20240101000006_workflow_functions.sql`
3. Click "Run"

## Verify Setup

After applying migrations, verify:

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'bookings', 'job_requests')
ORDER BY tablename;

-- Check policies exist
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check functions exist
SELECT proname 
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND proname IN ('firebase_uid', 'create_job_request', 'accept_request', 'complete_job', 'record_payment', 'leave_review');
```

## Alternative: Use Direct Database Connection

If CLI continues to timeout, you can use the direct database connection:

1. Get connection string from Supabase Dashboard → Settings → Database
2. Use a PostgreSQL client (pgAdmin, DBeaver, or psql)
3. Connect and run migrations manually

## Troubleshooting Connection Issues

### Option 1: Check Firewall
- Ensure your IP is allowed in Supabase Dashboard → Settings → Database → Connection Pooling
- Or use connection pooling port (6543) instead of direct (5432)

### Option 2: Use SQL Editor
- Supabase SQL Editor is more reliable for manual migrations
- No connection timeout issues
- Can run migrations one at a time

### Option 3: Retry Later
- Network issues might be temporary
- Try again in a few minutes
- Use `npx supabase db push --debug` for more details

