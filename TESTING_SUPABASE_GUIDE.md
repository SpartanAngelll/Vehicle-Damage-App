# Testing Your App with Supabase

## 🎯 Quick Test Checklist

Before testing, make sure:
- ✅ Supabase database is set up (tables created)
- ✅ Backend server is running (`node backend/server.js`)
- ✅ Backend is connected to Supabase (test with `/api/health`)

---

## 📱 Testing on Android

### Option 1: Using Environment Variables (Recommended)

**Method 1: Set variables before running**
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_SSL="true"
flutter run -d android
```

**Method 2: Use the script (modify for Android)**
```powershell
.\run_flutter_supabase.ps1
# Then select Android device when prompted
```

### Option 2: Build Configuration (For Production)

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        // ... existing config ...
        
        // Supabase configuration
        buildConfigField "String", "POSTGRES_HOST", "\"db.your-project-id.supabase.co\""
        buildConfigField "String", "POSTGRES_PORT", "\"5432\""
        buildConfigField "String", "POSTGRES_USER", "\"postgres\""
        buildConfigField "String", "POSTGRES_DB", "\"postgres\""
        buildConfigField "String", "POSTGRES_SSL", "\"true\""
    }
}
```

**Note:** Password should be passed at runtime or stored securely.

### Running on Android

1. **Connect your Android device** or start an emulator
2. **Set environment variables** (see Option 1 above)
3. **Run the app:**
   ```powershell
   flutter run -d android
   ```
4. **Or select device when prompted:**
   ```powershell
   flutter run
   # Then select your Android device from the list
   ```

### What to Test on Android

1. ✅ **Create a booking** - Tests PostgreSQL connection
2. ✅ **Send a chat message** - Tests Firestore + notifications
3. ✅ **Check console logs** - Look for:
   ```
   ✅ [PostgresPayment] Connected to PostgreSQL database successfully
   ```
4. ✅ **Verify in Supabase** - Check dashboard to see data

---

## 🌐 Testing on Web

### Option 1: Using Environment Variables

**PowerShell:**
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_SSL="true"
flutter run -d chrome
```

**Or use the script:**
```powershell
.\run_flutter_supabase.ps1
# Then select Chrome/Edge when prompted
```

### Option 2: Web Configuration File

For web, you can also create a configuration file that loads at runtime.

### Running on Web

1. **Set environment variables** (see above)
2. **Run the app:**
   ```powershell
   flutter run -d chrome
   ```
   Or:
   ```powershell
   flutter run -d edge
   ```
3. **The app will open** in your default browser

### What to Test on Web

1. ✅ **Create a booking** - Tests PostgreSQL connection
2. ✅ **Open browser console** (F12) - Check for connection logs
3. ✅ **Test chat functionality** - Verify Firestore works
4. ✅ **Check network tab** - Verify API calls to backend

---

## 🧪 Testing Checklist

### Database Connection Tests

- [ ] **Create a booking**
  - Should connect to Supabase
  - Should create record in `bookings` table
  - Check Supabase dashboard to verify

- [ ] **Create a payment**
  - Should create record in `payment_records` table
  - Should update `professional_balances` table

- [ ] **Create a service package**
  - Should create record in `service_packages` table

### Backend API Tests

- [ ] **Health check**
  ```powershell
  curl http://localhost:3000/api/health
  ```
  Should return: `{"status":"OK","timestamp":"..."}`

- [ ] **Get professional balance**
  ```powershell
  curl http://localhost:3000/api/professionals/test-id/balance
  ```
  Should return balance object

### Firebase Functions Tests

- [ ] **Send notification**
  - Create a chat message
  - Verify notification is sent
  - Check Firestore `notifications` collection

- [ ] **Chat message trigger**
  - Send a chat message
  - Verify recipient gets push notification

---

## 🐛 Troubleshooting

### Android Issues

**Connection Refused:**
- ✅ Check device has internet connection
- ✅ Verify `POSTGRES_HOST` is set correctly
- ✅ Check if device can reach Supabase (try ping from device)

**SSL Errors:**
- ✅ Ensure `POSTGRES_SSL=true` is set
- ✅ Check device time is correct (SSL certificates are time-sensitive)

**Environment Variables Not Working:**
- ✅ Try setting them in the same PowerShell session
- ✅ Or use build configuration method

### Web Issues

**CORS Errors:**
- ✅ Backend CORS is already configured
- ✅ Check backend is running on `http://localhost:3000`

**Connection Errors:**
- ✅ Check browser console for specific error
- ✅ Verify environment variables are set
- ✅ Check network tab for failed requests

**Build Errors:**
```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📊 Verification Steps

### 1. Check Supabase Dashboard

1. Go to Supabase Dashboard
2. Navigate to **Database** → **Tables**
3. Check if data appears when you:
   - Create a booking
   - Process a payment
   - Create a service package

### 2. Check Backend Logs

Look for:
```
✅ Connected to PostgreSQL database successfully
```

### 3. Check Flutter Console

Look for:
```
✅ [PostgresPayment] Connected to PostgreSQL database successfully
✅ [PostgresBooking] Booking created in PostgreSQL: [booking-id]
```

---

## 🚀 Quick Start Commands

### Android
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_SSL="true"
flutter run -d android
```

### Web
```powershell
$env:POSTGRES_HOST="db.your-project-id.supabase.co"
$env:POSTGRES_PASSWORD="your_supabase_password_here"
$env:POSTGRES_SSL="true"
flutter run -d chrome
```

---

## ✅ Success Indicators

You'll know everything is working when:

1. ✅ App starts without connection errors
2. ✅ You can create bookings
3. ✅ Data appears in Supabase dashboard
4. ✅ Backend API responds correctly
5. ✅ Notifications work (Firebase Functions)
6. ✅ Chat messages trigger notifications

---

## 📝 Next Steps After Testing

Once everything works:

1. **Deploy to production** (when ready)
2. **Set up connection pooling** (port 6543 for better performance)
3. **Configure secure password storage** (for production)
4. **Set up monitoring** in Supabase dashboard
5. **Configure backups** (Supabase provides automatic backups)

---

**Ready to test!** 🎉

