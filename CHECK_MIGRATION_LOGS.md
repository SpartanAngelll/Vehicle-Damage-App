# Checking Migration 20240101000010 Logs from Localhost

## Issue Found: .env File Problem

Your `.env` file has an encoding issue (unexpected character '»'). This prevents Supabase CLI from working.

**Quick Fix:**
1. Open `.env` file in a text editor
2. Check for any special characters (especially at the start of variable names)
3. Save as UTF-8 encoding without BOM
4. Or recreate the file with clean variable names

## How to Check Migration Logs

### Method 1: Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - URL: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk

2. **Check SQL Editor History**
   - Go to **SQL Editor** → **History**
   - Look for execution of `20240101000010_fix_audit_trigger_firebase_uid.sql`
   - Check for any error messages

3. **Check Postgres Logs**
   - Go to **Logs** → **Postgres Logs**
   - Filter by time when you ran the migration
   - Look for ERROR or WARNING messages

4. **Check Migration Status**
   - Go to **Database** → **Migrations**
   - Look for `20240101000010_fix_audit_trigger_firebase_uid`
   - Check if it shows as "Applied" or has errors

### Method 2: Run Verification Queries

Run these in Supabase SQL Editor to check if migration was applied:

```sql
-- 1. Check if get_current_user_id returns TEXT (not UUID)
SELECT 
  proname, 
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'get_current_user_id';

-- Expected: return_type should be 'text' or 'character varying'

-- 2. Check if audit_trigger_function exists
SELECT 
  proname,
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'audit_trigger_function';

-- Expected: Should return one row

-- 3. Check if create_audit_log function exists
SELECT 
  proname,
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'create_audit_log';

-- Expected: Should return one row

-- 4. Check audit_logs.user_id column type
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

-- 5. Check foreign key constraint
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

-- 6. Check if migration was recorded
SELECT * 
FROM supabase_migrations.schema_migrations 
WHERE name LIKE '%20240101000010%'
ORDER BY version DESC;
```

### Method 3: Test the Migration Functions

```sql
-- Test 1: Try to call get_current_user_id (should return TEXT, may be NULL if not authenticated)
SELECT public.get_current_user_id() as user_id;

-- Test 2: Try to create an audit log manually
SELECT public.create_audit_log(
  'test_action',
  'test_table',
  NULL,
  NULL,
  '{"test": "value"}'::JSONB,
  '{"source": "manual_test"}'::JSONB
) as log_id;

-- Test 3: Check if audit log was created
SELECT * FROM audit_logs 
WHERE action = 'test_action' 
ORDER BY created_at DESC 
LIMIT 1;
```

## Common Errors in Terminal Logs

### Error 1: Function Dependency
```
ERROR: cannot drop function get_current_user_id() because other objects depend on it
DETAIL: function audit_trigger_function() depends on function get_current_user_id()
```

**What it means:** The CASCADE didn't work as expected.

**Solution:** The migration should handle this, but if it fails:
```sql
-- Manually drop in order
DROP FUNCTION IF EXISTS public.audit_trigger_function() CASCADE;
DROP FUNCTION IF EXISTS public.get_current_user_id() CASCADE;
-- Then re-run the migration
```

### Error 2: Missing firebase_uid() Function
```
ERROR: function firebase_uid() does not exist
```

**What it means:** The `firebase_uid()` function wasn't created in an earlier migration.

**Solution:** Run this first:
```sql
-- Create firebase_uid function if missing
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

### Error 3: Type Mismatch
```
ERROR: column "user_id" is of type character varying but expression is of type uuid
```

**What it means:** Migration 20240101000004 wasn't applied first, or the column type wasn't changed.

**Solution:** Ensure migration 20240101000004 was applied:
```sql
-- Check current type
SELECT data_type 
FROM information_schema.columns 
WHERE table_name = 'audit_logs' AND column_name = 'user_id';

-- If it's still UUID, run migration 20240101000004 first
```

### Error 4: Foreign Key Constraint
```
ERROR: insert or update on table "audit_logs" violates foreign key constraint "audit_logs_user_id_fkey"
```

**What it means:** Trying to insert a user_id that doesn't exist in users table.

**Solution:** This is handled in the migration (sets user_id to NULL), but if you see this:
- The user doesn't exist in users table yet (this is OK, migration handles it)
- Or the foreign key constraint wasn't updated correctly

### Error 5: Syntax Error
```
ERROR: syntax error at or near "..."
```

**What it means:** There might be a SQL syntax issue in the migration file.

**Solution:** Check the migration file for syntax errors, or run it section by section.

## What Success Looks Like

When the migration runs successfully, you should see:

1. **No error messages** in the SQL Editor output
2. **All three functions created/replaced:**
   - `get_current_user_id()` returns TEXT
   - `audit_trigger_function()` exists
   - `create_audit_log()` exists
3. **Verification queries return expected results** (see Method 2 above)
4. **Test audit log creation works** (see Method 3 above)

## Next Steps

1. **Fix the .env file** encoding issue first
2. **Check Supabase Dashboard** for logs and migration status
3. **Run verification queries** to confirm migration was applied
4. **Test the functions** to ensure they work correctly

## If Migration Failed

1. Check the exact error message from Supabase SQL Editor
2. Review the error against the "Common Errors" section above
3. Apply the suggested fix
4. Re-run the migration or the specific failing part

## Getting Help

If you're still having issues:
1. Copy the exact error message from Supabase SQL Editor
2. Note which step failed (function creation, etc.)
3. Check the timestamp in Postgres Logs for more details


