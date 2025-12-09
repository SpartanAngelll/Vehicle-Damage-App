# Backend Supabase Connection Setup

## Step 1: Get Your Supabase Connection Details

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **Database**
4. Scroll to **Connection string** section
5. Click on **URI** tab
6. You'll see something like:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
   ```

**What you need:**
- **Host**: `db.xxxxx.supabase.co` (the part after `@` and before `:5432`)
- **Port**: `5432` (or `6543` for connection pooling)
- **Database**: `postgres` (default)
- **User**: `postgres` (default)
- **Password**: The password you set when creating the project

## Step 2: Create Backend .env File

1. In the `backend/` folder, create a file named `.env`
2. Copy the template below and fill in your Supabase details:

```env
# Server Configuration
PORT=3000
HOST=0.0.0.0

# Supabase Database Configuration
POSTGRES_HOST=db.xxxxx.supabase.co
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_supabase_password_here
POSTGRES_DB=postgres
POSTGRES_SSL=true

# Optional: Connection Pooling (for production, use port 6543)
# POSTGRES_PORT=6543
```

## Step 3: Test the Connection

1. Make sure you're in the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies (if not already done):
   ```bash
   npm install
   ```

3. Start the server:
   ```bash
   node server.js
   ```

4. You should see:
   ```
   🚀 Cash-out API server running on 0.0.0.0:3000
   📊 Health check: http://localhost:3000/api/health
   ```

5. Test the health endpoint:
   ```bash
   curl http://localhost:3000/api/health
   ```
   
   Or open in browser: http://localhost:3000/api/health
   
   Should return: `{"status":"OK","timestamp":"..."}`

## Step 4: Test Database Connection

Test if the backend can connect to Supabase:

```bash
curl http://localhost:3000/api/professionals/test-professional-id/balance
```

This should return a balance object (even if it's 0 for a new professional).

## Troubleshooting

### Connection Refused
- Check `POSTGRES_HOST` is correct (no `http://` or `https://`)
- Verify port is `5432` (or `6543` for pooling)
- Make sure Supabase project is active

### Authentication Failed
- Double-check `POSTGRES_PASSWORD` is correct
- Verify `POSTGRES_USER` is `postgres`
- Try resetting password in Supabase dashboard

### SSL Error
- Make sure `POSTGRES_SSL=true` is set
- If you get certificate errors, set `POSTGRES_SSL_REJECT_UNAUTHORIZED=false` (not recommended for production)

### Database Not Found
- Use `postgres` as the database name (not `vehicle_damage_payments`)
- Supabase uses `postgres` as the default database

## Next Steps

Once the backend is connected:
1. ✅ Test all API endpoints
2. ✅ Configure Flutter app to use Supabase
3. ✅ Test full workflow (create booking, process payment, etc.)

