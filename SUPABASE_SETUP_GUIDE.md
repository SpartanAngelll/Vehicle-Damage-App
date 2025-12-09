# Supabase PostgreSQL Setup Guide

This guide will help you migrate your PostgreSQL database to Supabase and configure your application to connect to it.

## 🎯 Overview

Supabase provides a managed PostgreSQL database with:
- **Free tier**: 500 MB database, 2 GB bandwidth
- **SSL connections**: Required for all connections
- **Connection pooling**: Built-in connection pooling
- **Automatic backups**: Daily backups on free tier
- **Web dashboard**: Easy database management

---

## 📋 Step 1: Create Supabase Account and Project

1. **Sign up for Supabase**
   - Go to [https://supabase.com](https://supabase.com)
   - Click "Start your project"
   - Sign up with GitHub, Google, or email

2. **Create a new project**
   - Click "New Project"
   - Fill in:
     - **Name**: `vehicle-damage-app` (or your preferred name)
     - **Database Password**: Create a strong password (save this!)
     - **Region**: Choose closest to your users
     - **Pricing Plan**: Free tier is fine to start

3. **Wait for project setup** (takes 1-2 minutes)

---

## 🔑 Step 2: Get Your Database Credentials

1. **Navigate to Project Settings**
   - In your Supabase dashboard, click the gear icon (⚙️) in the left sidebar
   - Click "Database"

2. **Find Connection String**
   - Scroll to "Connection string" section
   - Click "URI" tab
   - Copy the connection string (it looks like):
     ```
     postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
     ```

3. **Or get individual parameters**:
   - **Host**: `db.xxxxx.supabase.co` (from connection string)
   - **Port**: `5432` (or `6543` for connection pooling)
   - **Database**: `postgres` (default database)
   - **User**: `postgres`
   - **Password**: The password you set during project creation
   - **SSL**: Required (always enabled)

---

## 🗄️ Step 3: Set Up Database Schema

### Option A: Using Supabase SQL Editor (Recommended)

1. **Open SQL Editor**
   - In Supabase dashboard, click "SQL Editor" in left sidebar
   - Click "New query"

2. **Run Schema Script**
   - Open `database/complete_schema.sql` from your project
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - **Important**: Remove or comment out the `\c vehicle_damage_payments;` line (line 5) as Supabase uses the `postgres` database
   - Click "Run" (or press Ctrl+Enter)

3. **Verify Tables Created**
   - In SQL Editor, run:
     ```sql
     SELECT table_name 
     FROM information_schema.tables 
     WHERE table_schema = 'public' 
     ORDER BY table_name;
     ```
   - You should see all your tables listed

### Option B: Using psql Command Line

1. **Install PostgreSQL client** (if not already installed)
   ```bash
   # Windows (using Chocolatey)
   choco install postgresql
   
   # Or download from https://www.postgresql.org/download/windows/
   ```

2. **Connect to Supabase**
   ```bash
   psql "postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres?sslmode=require"
   ```

3. **Run Schema Script**
   ```bash
   # From your project directory
   psql "postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres?sslmode=require" -f database/complete_schema.sql
   ```
   
   **Note**: Remove the `\c vehicle_damage_payments;` line from the schema file first, or modify it to work with Supabase's default database.

---

## ⚙️ Step 4: Configure Backend Server

1. **Create/Update `backend/.env` file**
   ```env
   # Supabase Database Configuration
   POSTGRES_HOST=db.xxxxx.supabase.co
   POSTGRES_PORT=5432
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_supabase_password_here
   POSTGRES_DB=postgres
   POSTGRES_SSL=true
   
   # Server Configuration
   PORT=3000
   HOST=0.0.0.0
   ```

2. **Update Connection Pool Settings** (Optional - for better performance)
   ```env
   # Use connection pooling port (recommended for production)
   POSTGRES_PORT=6543
   ```

3. **Test Backend Connection**
   ```bash
   cd backend
   npm install  # If needed
   node server.js
   ```
   
   You should see:
   ```
   🚀 Cash-out API server running on 0.0.0.0:3000
   📊 Health check: http://localhost:3000/api/health
   ```

4. **Test Health Endpoint**
   ```bash
   curl http://localhost:3000/api/health
   ```

---

## 📱 Step 5: Configure Flutter App

### Update Environment Variables

The Flutter app reads PostgreSQL connection from environment variables. You have two options:

#### Option A: Use Environment Variables (Recommended for Production)

1. **For Android/iOS**: Set environment variables in your build configuration
2. **For Web**: Set in your web deployment environment
3. **For Development**: Use a `.env` file (requires `flutter_dotenv` package)

#### Option B: Update Code Directly (Quick Setup)

The Flutter services will automatically use environment variables if set. Update the default values in:
- `lib/services/postgres_payment_service.dart`
- `lib/services/postgres_booking_service.dart`

**Note**: For Supabase, you'll need to:
- Set `POSTGRES_HOST` to your Supabase host
- Set `POSTGRES_SSL=true` (SSL is required)
- Update connection code to use SSL

---

## 🔒 Step 6: Enable SSL in Flutter

The Flutter `postgres` package supports SSL. Update the connection code:

**In `lib/services/postgres_payment_service.dart`** (around line 143):
```dart
_connection = await Connection.open(
  Endpoint(
    host: _host,
    port: _port,
    database: _database,
    username: _username,
    password: _password,
  ),
  settings: ConnectionSettings(
    sslMode: _useSSL ? SslMode.require : SslMode.disable,
  ),
);
```

**In `lib/services/postgres_booking_service.dart**: Similar update needed.

---

## ✅ Step 7: Verify Connection

### Test Backend Connection
```bash
curl http://localhost:3000/api/health
```

### Test Database Connection from Backend
```bash
curl http://localhost:3000/api/professionals/test-professional-id/balance
```

### Test Flutter App
- Run your Flutter app
- Try creating a booking or payment
- Check console logs for connection success messages

---

## 🔧 Step 8: Connection Pooling (Optional but Recommended)

Supabase provides connection pooling on port **6543**. This is recommended for:
- Production applications
- High-traffic scenarios
- Better connection management

**Update your backend `.env`**:
```env
POSTGRES_PORT=6543  # Connection pooling port
```

**Note**: Connection pooling uses a different connection method. The connection string format is:
```
postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:6543/postgres?pgbouncer=true
```

---

## 🛡️ Step 9: Security Best Practices

1. **Never commit credentials**
   - Add `.env` to `.gitignore`
   - Use environment variables in production

2. **Use Supabase Row Level Security (RLS)**
   - Supabase provides built-in RLS policies
   - Configure in Supabase dashboard under "Authentication" > "Policies"

3. **Rotate passwords regularly**
   - Update password in Supabase dashboard
   - Update all `.env` files

4. **Use connection pooling in production**
   - Reduces connection overhead
   - Better for scalability

---

## 🐛 Troubleshooting

### Connection Refused
- **Check host**: Ensure you're using the correct Supabase host
- **Check port**: Use `5432` for direct connection or `6543` for pooling
- **Check firewall**: Supabase should be accessible from anywhere

### SSL/TLS Errors
- **Ensure SSL is enabled**: Supabase requires SSL
- **Check certificate**: The `postgres` package should handle this automatically
- **Try `SslMode.require`**: Instead of `SslMode.verifyFull`

### Authentication Failed
- **Verify password**: Check Supabase dashboard for correct password
- **Check username**: Should be `postgres` (default)
- **Reset password**: In Supabase dashboard if needed

### Database Not Found
- **Use `postgres` database**: Supabase uses `postgres` as default database
- **Don't create new databases**: Use the default `postgres` database
- **Check schema**: Ensure your tables are in the `public` schema

### Flutter Connection Issues
- **Check environment variables**: Ensure they're set correctly
- **Check SSL mode**: Must be enabled for Supabase
- **Check network**: Ensure device can reach Supabase (internet connection required)

---

## 📊 Step 10: Monitor Your Database

1. **Supabase Dashboard**
   - View database size, connections, and performance
   - Access under "Database" > "Settings"

2. **Query Performance**
   - Use "Database" > "Query Performance" to see slow queries

3. **Connection Pooling Stats**
   - Monitor active connections
   - Check connection pool usage

---

## 🚀 Next Steps

1. **Test all features**: Create bookings, process payments, test cashouts
2. **Set up backups**: Supabase provides automatic backups (daily on free tier)
3. **Monitor usage**: Keep an eye on database size and bandwidth
4. **Scale up**: Upgrade plan if you exceed free tier limits
5. **Set up RLS policies**: Configure row-level security for better data protection

---

## 📝 Quick Reference

### Connection String Format
```
postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres?sslmode=require
```

### Environment Variables Template
```env
POSTGRES_HOST=db.xxxxx.supabase.co
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DB=postgres
POSTGRES_SSL=true
```

### Supabase Dashboard Links
- **Project Dashboard**: https://supabase.com/dashboard/project/[PROJECT-ID]
- **Database Settings**: https://supabase.com/dashboard/project/[PROJECT-ID]/settings/database
- **SQL Editor**: https://supabase.com/dashboard/project/[PROJECT-ID]/sql/new

---

## 💡 Tips

- **Free Tier Limits**: 500 MB database, 2 GB bandwidth per month
- **Connection Pooling**: Use port 6543 for better performance
- **SSL Required**: Always enable SSL for Supabase connections
- **Default Database**: Use `postgres` database (don't create new ones)
- **Schema**: All tables go in `public` schema by default

---

## 📞 Need Help?

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Discord**: https://discord.supabase.com
- **Supabase GitHub**: https://github.com/supabase/supabase

Good luck with your migration! 🎉

