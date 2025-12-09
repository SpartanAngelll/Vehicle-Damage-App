# Supabase Connection Issues - Fix Guide

## Issues Found

### 1. Android: "Network is unreachable"
- **Cause**: Supabase direct connection (port 5432) may be IPv6-only, which Android devices might not support
- **Solution**: Use connection pooling port (6543) which is IPv4 compatible

### 2. Web: "Unsupported operation: Platform._operatingSystem"
- **Cause**: The `postgres` package doesn't work on web platform
- **Solution**: Web now skips direct PostgreSQL and uses backend API

## ✅ Fixes Applied

1. **Web Platform**: Now skips direct PostgreSQL connection (uses backend API instead)
2. **Connection Pooling**: Default port changed to 6543 (IPv4 compatible)
3. **Better Error Handling**: Improved error messages and fallbacks

## 🔧 Configuration Options

### Option 1: Use Connection Pooling (Recommended for Mobile)

The code now defaults to port **6543** (Supabase connection pooling), which:
- ✅ Is IPv4 compatible
- ✅ Works better on mobile devices
- ✅ Handles connections more efficiently

**No changes needed** - this is already set as default.

### Option 2: Use Direct Connection (Port 5432)

If you want to use direct connection, update the port in the code:

**In `lib/services/postgres_payment_service.dart`:**
```dart
int get _port {
  // ... existing code ...
  return 5432; // Direct connection port
}
```

**Note**: Direct connection may not work on all Android devices due to IPv4/IPv6 issues.

### Option 3: Route Through Backend API (Most Reliable)

For maximum compatibility, route all database operations through your backend API:

1. **Backend is already set up** and connected to Supabase ✅
2. **Use API endpoints** instead of direct PostgreSQL connections
3. **Works on all platforms** (Android, iOS, Web)

## 🧪 Testing After Fix

### Android
1. **Hot restart** the app (press `R` in Flutter terminal)
2. **Check console** for connection success:
   ```
   ✅ [PostgresPayment] Connected to PostgreSQL database successfully
   ```
3. **Test creating a booking** - should work now

### Web
1. **Refresh the browser**
2. **Check console** (F12) - should see:
   ```
   ℹ️ [PostgresPayment] Web platform - skipping direct PostgreSQL connection
   ```
3. **Use backend API** for database operations (already configured)

## 🔍 Troubleshooting

### Still Getting "Network is unreachable" on Android?

1. **Check device internet connection**
   - Open browser on device
   - Try visiting a website
   - Verify WiFi/mobile data is working

2. **Try connection pooling port** (already set to 6543)
   - This is IPv4 compatible
   - Should work on all devices

3. **Check Supabase dashboard**
   - Go to Settings → Database
   - Verify your project is active
   - Check if IPv4 add-on is needed

4. **Test from device browser**
   - Try accessing: `https://db.rodzemxwopecqpazkjyk.supabase.co`
   - If this fails, it's a network/DNS issue

### Web Still Having Issues?

- Web now skips direct PostgreSQL automatically
- All database operations should go through backend API
- Make sure backend is running on `http://localhost:3000`

## 📝 Current Configuration

- **Host**: `db.rodzemxwopecqpazkjyk.supabase.co`
- **Port**: `6543` (connection pooling - IPv4 compatible)
- **Database**: `postgres`
- **User**: `postgres`
- **SSL**: Enabled (auto-detected)

## ✅ Next Steps

1. **Hot restart** your Android app
2. **Test connection** - should work now with port 6543
3. **Verify in Supabase** - check dashboard for data
4. **Web should work** - uses backend API automatically

---

**The fixes are applied!** Hot restart your app and test again. 🚀

