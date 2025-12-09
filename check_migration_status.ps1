# Check Migration Status for 20240101000010_fix_audit_trigger_firebase_uid.sql
# This script helps diagnose issues with the audit trigger migration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Migration Status Check" -ForegroundColor Cyan
Write-Host "20240101000010_fix_audit_trigger_firebase_uid.sql" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is available
Write-Host "1. Checking Supabase CLI..." -ForegroundColor Yellow
try {
    $version = npx supabase --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Supabase CLI available: $version" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Supabase CLI not available or error" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Supabase CLI error: $_" -ForegroundColor Red
}

Write-Host ""

# Check migration list
Write-Host "2. Checking applied migrations..." -ForegroundColor Yellow
try {
    $migrations = npx supabase migration list 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Migration list retrieved" -ForegroundColor Green
        Write-Host ""
        Write-Host "   Applied Migrations:" -ForegroundColor Cyan
        $migrations | ForEach-Object {
            if ($_ -match "20240101000010") {
                Write-Host "   ✅ $_" -ForegroundColor Green
            } elseif ($_ -match "202401010000") {
                Write-Host "   $_" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "   ⚠️  Could not retrieve migration list" -ForegroundColor Yellow
        Write-Host "   Error: $migrations" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Error checking migrations: $_" -ForegroundColor Red
}

Write-Host ""

# SQL queries to check migration status
Write-Host "3. SQL Verification Queries" -ForegroundColor Yellow
Write-Host "   Run these in Supabase SQL Editor to verify migration:" -ForegroundColor White
Write-Host ""

$verificationQueries = @"
-- Check if get_current_user_id function exists and returns TEXT
SELECT 
  proname, 
  pg_get_function_result(oid) as return_type,
  pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname = 'get_current_user_id';

-- Check if audit_trigger_function exists
SELECT 
  proname,
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'audit_trigger_function';

-- Check if create_audit_log function exists
SELECT 
  proname,
  pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'create_audit_log';

-- Check audit_logs table structure
SELECT 
  column_name, 
  data_type, 
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'audit_logs' 
AND column_name = 'user_id';

-- Check foreign key constraint
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

-- Check if triggers are attached
SELECT 
  trigger_name, 
  event_object_table, 
  action_timing, 
  event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name LIKE 'audit_%'
ORDER BY event_object_table, trigger_name;
"@

Write-Host $verificationQueries -ForegroundColor Gray
Write-Host ""

# Common errors section
Write-Host "4. Common Errors to Look For:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   ❌ ERROR: cannot drop function get_current_user_id()" -ForegroundColor Red
Write-Host "      → Solution: Migration uses CASCADE, but if this fails," -ForegroundColor White
Write-Host "        manually drop dependencies first" -ForegroundColor White
Write-Host ""
Write-Host "   ❌ ERROR: function firebase_uid() does not exist" -ForegroundColor Red
Write-Host "      → Solution: Run database/firebase_authenticated_role_setup.sql first" -ForegroundColor White
Write-Host ""
Write-Host "   ❌ ERROR: column user_id is of type character varying" -ForegroundColor Red
Write-Host "      → Solution: Ensure migration 20240101000004 was applied first" -ForegroundColor White
Write-Host ""
Write-Host "   ❌ ERROR: violates foreign key constraint" -ForegroundColor Red
Write-Host "      → Solution: This is handled in the migration (sets user_id to NULL)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Check Supabase Dashboard → SQL Editor for error logs" -ForegroundColor White
Write-Host "2. Run the verification queries above" -ForegroundColor White
Write-Host "3. Check Supabase Dashboard → Logs → Postgres Logs" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan


