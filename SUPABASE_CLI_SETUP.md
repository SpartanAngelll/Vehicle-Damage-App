# Supabase CLI Setup Guide

Complete setup using Supabase CLI - no manual SQL needed!

## Prerequisites

### Option 1: Install Locally (Recommended)

1. **Install Supabase CLI as dev dependency:**
   ```bash
   npm install supabase --save-dev
   ```

2. **Use npx to run commands:**
   ```bash
   npx supabase login
   npx supabase db push
   ```

### Option 2: Install via Scoop (Windows)

1. **Install Scoop (if not installed):**
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex
   ```

2. **Install Supabase CLI:**
   ```powershell
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

3. **Then use directly:**
   ```powershell
   supabase login
   supabase db push
   ```

### Option 3: Direct Download (Windows)

1. Download from: https://github.com/supabase/cli/releases
2. Extract and add to PATH
3. Use: `supabase login`

## Quick Setup (Automated)

### Windows (PowerShell)
```powershell
.\supabase\setup.ps1
```

### macOS/Linux
```bash
chmod +x supabase/setup.sh
./supabase/setup.sh
```

## Manual Setup

### Step 1: Link to Your Project

**If using local install (npx):**
```bash
# Link to existing Supabase project
npx supabase link --project-ref YOUR_PROJECT_REF

# Or initialize new local project
npx supabase init
```

**If using global install:**
```bash
# Link to existing Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# Or initialize new local project
supabase init
```

**Get your project reference:**
- Go to Supabase Dashboard → Settings → General
- Copy "Reference ID"

### Step 2: Push Migrations

**If using local install (npx):**
```bash
# Push all migrations to remote database
npx supabase db push

# Or push specific migration
npx supabase migration up
```

**If using global install:**
```bash
# Push all migrations to remote database
supabase db push

# Or push specific migration
supabase migration up
```

### Step 3: Verify Setup

**If using local install (npx):**
```bash
# Check migration status
npx supabase migration list

# View database schema
npx supabase db diff
```

**If using global install:**
```bash
# Check migration status
supabase migration list

# View database schema
supabase db diff
```

## Migration Files

All migrations are in `supabase/migrations/`:

1. `20240101000000_initial_schema.sql` - Core tables
2. `20240101000001_indexes.sql` - Performance indexes
3. `20240101000002_triggers.sql` - Auto-update triggers
4. `20240101000003_seed_data.sql` - Initial data
5. `20240101000004_firebase_uid_migration.sql` - Firebase UID migration
6. `20240101000005_rls_policies.sql` - Row Level Security
7. `20240101000006_workflow_functions.sql` - SQL functions

## Configuration

### JWT Configuration (Required)

1. Go to Supabase Dashboard → Settings → API
2. Find "JWT Settings"
3. Set JWT Secret to your Firebase project secret:
   - Firebase Console → Project Settings → Service Accounts
   - Copy the private key

**OR** use custom JWT verifier (see `database/supabase_jwt_config.sql`)

### Environment Variables

Create `.env` file:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
```

## Useful Commands

**If installed locally (using npx):**
```bash
# Start local Supabase (for development)
npx supabase start

# Stop local Supabase
npx supabase stop

# Reset local database
npx supabase db reset

# Create new migration
npx supabase migration new migration_name

# Generate TypeScript types
npx supabase gen types typescript --local > types/supabase.ts

# View logs
npx supabase logs

# Push migrations
npx supabase db push

# Link to project
npx supabase link --project-ref YOUR_PROJECT_REF
```

**If installed globally (Scoop/direct):**
```bash
# Use commands directly without npx
supabase start
supabase db push
supabase link --project-ref YOUR_PROJECT_REF
```

## Troubleshooting

### Migration Fails
```bash
# Check migration status
supabase migration list

# Rollback last migration
supabase migration down

# Fix and retry
supabase db push
```

### RLS Policies Not Working
- Verify JWT secret is configured
- Check `auth.firebase_uid()` function exists
- Test with: `SELECT auth.firebase_uid();`

### Connection Issues
```bash
# Verify project link
supabase projects list

# Re-link if needed
supabase link --project-ref YOUR_PROJECT_REF
```

## Next Steps

After setup:
1. ✅ Configure JWT secret (see above)
2. ✅ Deploy Firestore rules: `firebase deploy --only firestore:rules`
3. ✅ Initialize in Flutter app (see `QUICK_START.md`)
4. ✅ Run tests (see `TESTING_GUIDE.md`)

## Production Deployment

```bash
# Push to production
supabase db push --db-url "postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres"

# Or use project link
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

