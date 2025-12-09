# Supabase Database Setup - Step by Step

I've created a Supabase-ready version of your database schema. Here's how to set it up:

## 📋 What I've Prepared

✅ **`database/complete_schema_supabase.sql`** - A Supabase-compatible version of your schema with:
- Removed `\c vehicle_damage_payments;` command (Supabase uses `postgres` database)
- Fixed booking table to use VARCHAR for IDs (matching your Firestore IDs)
- Removed PostGIS-dependent location index (optional, can be added later if needed)
- All extensions, tables, indexes, triggers, and seed data ready to run

## 🚀 Setup Steps

### Step 1: Get Your Supabase Connection Details

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project (or create one if you haven't)
3. Go to **Settings** → **Database**
4. Copy your connection details:
   - **Host**: `db.xxxxx.supabase.co`
   - **Port**: `5432` (or `6543` for connection pooling)
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: (the one you set when creating the project)

### Step 2: Open Supabase SQL Editor

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New query**

### Step 3: Run the Schema

**Option A: Copy-Paste (Easiest)**

1. Open `database/complete_schema_supabase.sql` in your code editor
2. Copy the **entire contents** (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)

**Option B: Upload File**

1. In Supabase SQL Editor, look for an "Upload" or "Import" option
2. Select `database/complete_schema_supabase.sql`

### Step 4: Verify Setup

After running the schema, verify it worked:

```sql
-- Check if tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Should show all your tables including:
-- users, service_professionals, bookings, payments, etc.
```

### Step 5: Check Seed Data

Verify default data was inserted:

```sql
-- Check service categories
SELECT COUNT(*) FROM service_categories;
-- Should return 22

-- Check notification channels
SELECT COUNT(*) FROM notification_channels;
-- Should return 8

-- Check system settings
SELECT COUNT(*) FROM system_settings;
-- Should return 10
```

## ✅ What's Different from Original Schema?

1. **Database Connection**: Removed `\c vehicle_damage_payments;` - Supabase uses `postgres` database
2. **Booking IDs**: Changed from UUID to VARCHAR(255) to match Firestore IDs
3. **Location Index**: Removed `ll_to_earth` index (requires PostGIS extension)
4. **Payment Records**: Made `invoice_id` nullable to match your current implementation
5. **Professional IDs**: Using VARCHAR(255) for Firebase UIDs in relevant tables

## 🔧 Troubleshooting

### Error: "extension already exists"
- This is fine! The `IF NOT EXISTS` clause handles this
- Just continue

### Error: "relation already exists"
- Some tables might already exist
- You can either:
  - Drop existing tables first: `DROP TABLE IF EXISTS table_name CASCADE;`
  - Or skip the CREATE TABLE statements for existing tables

### Error: "permission denied"
- Make sure you're using the `postgres` user
- Check that you have proper permissions in Supabase dashboard

### Tables not showing up
- Make sure you're looking in the `public` schema
- Run: `SELECT * FROM information_schema.tables WHERE table_schema = 'public';`

## 📝 Next Steps After Setup

1. **Update Backend Configuration**
   - Create `backend/.env` with your Supabase credentials
   - Set `POSTGRES_SSL=true`

2. **Update Flutter App**
   - Set `POSTGRES_HOST` environment variable to your Supabase host
   - SSL will be auto-detected

3. **Test Connection**
   - Start your backend: `cd backend && node server.js`
   - Test health endpoint: `curl http://localhost:3000/api/health`

## 🎯 Quick Setup Checklist

- [ ] Created Supabase project
- [ ] Got connection details (host, password, etc.)
- [ ] Opened Supabase SQL Editor
- [ ] Copied and ran `complete_schema_supabase.sql`
- [ ] Verified tables were created (22+ tables)
- [ ] Verified seed data (22 categories, 8 channels, 10 settings)
- [ ] Updated backend `.env` file
- [ ] Tested backend connection

## 💡 Need Help?

If you encounter any issues:
1. Check the error message in Supabase SQL Editor
2. Verify your connection details are correct
3. Make sure you're using the `postgres` database (not creating a new one)
4. Check Supabase dashboard for any service status issues

---

**Ready to go!** Once you've run the schema, your database will be fully set up and ready for your application. 🎉

