# Run Booking Triggers Migration

## Quick Method: Supabase SQL Editor (Recommended - 2 minutes)

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new
   - Or: Dashboard → SQL Editor → New query

2. **Copy the Migration SQL**
   - Open the file: `supabase/migrations/20240101000007_booking_triggers.sql`
   - Copy ALL the contents (Ctrl+A, Ctrl+C)

3. **Paste and Run**
   - Paste into the SQL Editor
   - Click **Run** (or press Ctrl+Enter)

4. **Verify Success**
   - You should see: "Success. No rows returned"
   - The trigger function and trigger should now be created

5. **Test the Trigger** (Optional)
   ```sql
   -- Check if trigger exists
   SELECT trigger_name, event_manipulation, event_object_table
   FROM information_schema.triggers
   WHERE trigger_name = 'trigger_populate_booking_tables';
   
   -- Check if function exists
   SELECT proname, prosrc
   FROM pg_proc
   WHERE proname = 'populate_booking_related_tables';
   ```

## Alternative: Using psql (If you have connection details)

If you have your Supabase database password, you can run:

```powershell
# Get the migration file content and run it
$migrationFile = "supabase\migrations\20240101000007_booking_triggers.sql"
$connectionString = "postgresql://postgres:YOUR_PASSWORD@db.rodzemxwopecqpazkjyk.supabase.co:5432/postgres?sslmode=require"

# Run the migration
Get-Content $migrationFile | psql $connectionString
```

**Note**: Replace `YOUR_PASSWORD` with your actual Supabase database password.

## What This Migration Does

✅ Creates trigger function `populate_booking_related_tables()`
✅ Creates trigger `trigger_populate_booking_tables` on `bookings` table
✅ Automatically populates:
   - Chat rooms
   - Invoices
   - Professional balances
   - Notifications

## After Running

Once the migration is applied, every time a booking is inserted:
- A chat room will be automatically created
- An invoice will be automatically created
- Professional balance will be initialized (if needed)
- Notifications will be sent to customer and professional

No manual intervention needed! 🎉

