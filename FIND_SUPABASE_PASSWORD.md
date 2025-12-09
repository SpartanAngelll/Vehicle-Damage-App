# Where to Find Your Supabase Database Password

## Primary Location: Supabase Dashboard

**Direct Link:**
https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database

**Steps:**
1. Go to Supabase Dashboard
2. Select your project: `rodzemxwopecqpazkjyk`
3. Navigate to **Settings** → **Database**
4. Look for **Database Password** section
5. You can:
   - **View** the password (if you have access)
   - **Reset** the password if needed
   - **Copy** the connection string which includes the password

## Secondary Location: .env File

The password might be stored in your `.env` file as `POSTGRES_PASSWORD`:

**File Location:** `.env` (in project root)

**Note:** The `.env` file is gitignored, so it won't be in version control.

**To check:**
```powershell
# View .env file (if it exists)
Get-Content .env | Select-String "POSTGRES_PASSWORD"
```

## If You Don't Have the Password

### Option 1: Reset Password in Dashboard
1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database
2. Click **Reset Database Password**
3. Copy the new password
4. Update your `.env` file if needed

### Option 2: Use Connection String from Dashboard
1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database
2. Find **Connection string** section
3. Copy the connection string (format: `postgresql://postgres:[PASSWORD]@...`)
4. Extract the password from the connection string

## For Supabase CLI

The CLI will prompt you for the password when needed. You can also:

1. **Set it as environment variable** (temporary):
   ```powershell
   $env:SUPABASE_DB_PASSWORD="your_password_here"
   ```

2. **Use connection string directly**:
   ```powershell
   npx supabase db push --db-url "postgresql://postgres:[PASSWORD]@db.rodzemxwopecqpazkjyk.supabase.co:5432/postgres"
   ```

## Quick Access Links

- **Database Settings**: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database
- **SQL Editor**: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new
- **Connection Pooling**: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database#connection-pooling

## Security Note

⚠️ **Never commit passwords to Git!**
- The `.env` file should be in `.gitignore` (it is)
- Don't hardcode passwords in source files
- Use environment variables or secure storage


