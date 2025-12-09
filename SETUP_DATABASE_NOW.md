# Quick Database Setup - Run This Now!

The `users` table doesn't exist yet. Here's how to create it:

## Option 1: Supabase SQL Editor (Easiest - 2 minutes)

1. **Open Supabase SQL Editor:**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

2. **Run the Complete Schema:**
   - Open the file: `database/complete_schema_supabase.sql`
   - Copy ALL the contents (Ctrl+A, Ctrl+C)
   - Paste into the SQL Editor
   - Click **Run** (or press Ctrl+Enter)

3. **Verify it worked:**
   - Run this query in the SQL Editor:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'users';
   ```
   - Should return: `users`

## Option 2: Run Migrations in Order

If you prefer to run migrations one by one:

1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new

2. Run these migrations in order:
   - `supabase/migrations/20240101000000_initial_schema.sql`
   - `supabase/migrations/20240101000001_indexes.sql`
   - `supabase/migrations/20240101000002_triggers.sql`
   - `supabase/migrations/20240101000003_seed_data.sql`
   - `supabase/migrations/20240101000004_firebase_uid_migration.sql`
   - `supabase/migrations/20240101000005_rls_policies.sql`
   - `supabase/migrations/20240101000006_workflow_functions.sql`

## Option 3: Use Supabase CLI (If Installed)

```powershell
# Check if Supabase CLI is available
npx supabase --version

# If available, link and push:
npx supabase link --project-ref rodzemxwopecqpazkjyk
npx supabase db push
```

## After Setup

Once the tables are created, you can verify users:

```powershell
# Check if users table exists
.\verify_user_in_supabase.ps1
```

Or use the backend API:
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/users/stats" | ConvertTo-Json
```

