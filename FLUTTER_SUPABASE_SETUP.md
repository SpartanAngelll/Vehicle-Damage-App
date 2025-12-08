# Flutter App Supabase Configuration Guide

Your Flutter app is now configured to connect to Supabase! Here's how to set it up.

## ✅ What's Already Configured

- ✅ SSL support with auto-detection for Supabase hosts
- ✅ Environment variable support for all connection settings
- ✅ Default database set to `postgres` (Supabase default)
- ✅ Automatic SSL detection for non-localhost hosts

## 🔧 Setup Options

### Option 1: Environment Variables (Recommended)

Set environment variables when running your Flutter app. The app will automatically use them.

#### For Development (Command Line)

**Windows (PowerShell):**
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PORT="5432"
$env:POSTGRES_USER="postgres"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_DB="postgres"
$env:POSTGRES_SSL="true"
flutter run
```

**Windows (CMD):**
```cmd
set POSTGRES_HOST=db.your-project-id.supabase.co
set POSTGRES_PORT=5432
set POSTGRES_USER=postgres
set POSTGRES_PASSWORD=your_supabase_password_here
set POSTGRES_DB=postgres
set POSTGRES_SSL=true
flutter run
```

**macOS/Linux:**
```bash
export POSTGRES_HOST=db.your-project-id.supabase.co
export POSTGRES_PORT=5432
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=your_supabase_password_here
export POSTGRES_DB=postgres
export POSTGRES_SSL=true
flutter run
```

#### For Android Build

Create or update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        // ... existing config ...
        
        // Supabase PostgreSQL configuration
        buildConfigField "String", "POSTGRES_HOST", "\"db.your-project-id.supabase.co\""
        buildConfigField "String", "POSTGRES_PORT", "\"5432\""
        buildConfigField "String", "POSTGRES_USER", "\"postgres\""
        buildConfigField "String", "POSTGRES_DB", "\"postgres\""
        buildConfigField "String", "POSTGRES_SSL", "\"true\""
    }
}
```

**Note:** For Android, you'll need to pass the password at runtime or use a secure storage solution.

#### For iOS Build

Create or update `ios/Runner/Info.plist`:

```xml
<key>POSTGRES_HOST</key>
<string>db.your-project-id.supabase.co</string>
<key>POSTGRES_PORT</key>
<string>5432</string>
<key>POSTGRES_USER</key>
<string>postgres</string>
<key>POSTGRES_DB</key>
<string>postgres</string>
<key>POSTGRES_SSL</key>
<string>true</string>
```

**Note:** For iOS, you'll need to pass the password at runtime or use a secure storage solution.

### Option 2: Update Default Values in Code (Quick Test)

If you want to quickly test without environment variables, you can temporarily update the default values in:

- `lib/services/postgres_payment_service.dart`
- `lib/services/postgres_booking_service.dart`

**⚠️ Warning:** Don't commit passwords to code! This is only for quick testing.

## 🚀 Quick Start (Easiest Method)

For development, the easiest way is to set environment variables before running:

**Windows PowerShell:**
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_SSL="true"
flutter run
```

The app will auto-detect:
- ✅ SSL is required (because host is not localhost)
- ✅ Database is `postgres` (default)
- ✅ Port is `5432` (default)
- ✅ User is `postgres` (default)

## 🧪 Testing the Connection

1. **Run your Flutter app** with environment variables set
2. **Try creating a booking** - this will test the PostgreSQL connection
3. **Check the console logs** - you should see:
   ```
   ✅ [PostgresPayment] Connected to PostgreSQL database successfully
   ```

4. **Verify in Supabase Dashboard:**
   - Go to Supabase Dashboard → Database → Tables
   - Check if data appears in your tables

## 🔒 Security Best Practices

### ✅ DO:
- Use environment variables for all sensitive data
- Store passwords securely (use secure storage packages)
- Use different credentials for development and production
- Never commit `.env` files or passwords to version control

### ❌ DON'T:
- Hardcode passwords in source code
- Commit credentials to Git
- Share credentials publicly
- Use production credentials in development

## 📱 Platform-Specific Notes

### Android
- Environment variables set via command line work for development
- For production, use secure storage or build configuration
- Internet permission is required (already in AndroidManifest.xml)

### iOS
- Environment variables set via command line work for development
- For production, use secure storage or Info.plist
- Internet permission is required (already in Info.plist)

### Web
- Environment variables can be set in your web deployment environment
- Or use a configuration file loaded at runtime

## 🐛 Troubleshooting

### Connection Refused
- ✅ Check `POSTGRES_HOST` is set correctly
- ✅ Verify internet connection (Supabase requires internet)
- ✅ Check if device/emulator can reach Supabase

### SSL/TLS Errors
- ✅ Ensure `POSTGRES_SSL=true` is set
- ✅ The app auto-detects SSL for Supabase hosts
- ✅ Check if device time is correct (SSL certificates are time-sensitive)

### Authentication Failed
- ✅ Verify `POSTGRES_PASSWORD` is correct
- ✅ Check `POSTGRES_USER` is `postgres`
- ✅ Ensure password doesn't have special characters that need escaping

### Database Not Found
- ✅ Use `postgres` as database name (not `vehicle_damage_payments`)
- ✅ Supabase uses `postgres` as the default database

## 📝 Your Supabase Configuration

```
Host: db.your-project-id.supabase.co
Port: 5432
Database: postgres
User: postgres
Password: [Set via environment variable]
SSL: true (auto-detected)
```

## ✅ Next Steps

1. **Set environment variables** (see Quick Start above)
2. **Run your Flutter app**: `flutter run`
3. **Test creating a booking** to verify connection
4. **Check Supabase dashboard** to see your data

---

**Ready to go!** Your Flutter app is configured for Supabase. Just set the environment variables and run! 🎉

