# Google Maps API Security Fix

## 🔍 **Issue Identified**
The "Unknown calling package name" error occurs because the Google Maps API key restrictions don't match the app's actual package name and SHA-1 fingerprint.

## 📋 **App Information**
- **Package Name**: `com.example.vehicle_damage_app`
- **SHA-1 Fingerprint**: `03:FB:F8:98:DC:90:0C:A5:F6:AC:BE:80:C9:06:6A:D1:67:AE:CD:2F`
- **Current API Key**: `AIzaSyDf_kWsC-UjIrP6iDqv2iHGV3oVVXjm2Ik`

## 🛠️ **Solution Steps**

### Step 1: Update Google Cloud Console API Key Restrictions

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Navigate to APIs & Services > Credentials**
3. **Find your API key**: `AIzaSyDf_kWsC-UjIrP6iDqv2iHGV3oVVXjm2Ik`
4. **Click on the key to edit it**

### Step 2: Configure Application Restrictions

1. **Select "Android apps"** as the restriction type
2. **Add the following restriction**:
   - **Package name**: `com.example.vehicle_damage_app`
   - **SHA-1 certificate fingerprint**: `03:FB:F8:98:DC:90:0C:A5:F6:AC:BE:80:C9:06:6A:D1:67:AE:CD:2F`

### Step 3: Configure API Restrictions

1. **Select "Restrict key"**
2. **Choose "Maps SDK for Android"** from the API list
3. **Save the changes**

### Step 4: Wait for Propagation

- **Wait 5-10 minutes** for the changes to propagate
- **Test the app** to verify the fix

## 🔧 **Alternative: Create New API Key (If Needed)**

If the current key has too many restrictions, create a new one:

1. **Create new API key** in Google Cloud Console
2. **Configure restrictions** as above
3. **Update `android/local.properties`**:
   ```properties
   GOOGLE_MAPS_API_KEY=your_new_api_key_here
   ```
4. **Hot restart the app**

## ✅ **Verification Steps**

1. **Hot restart** the app (not just hot reload)
2. **Navigate to** service professional profile
3. **Tap "Set Location"** to open map picker
4. **Verify map loads** without security errors

## 🚨 **Common Issues & Solutions**

### Issue: "This API key is not authorized"
- **Solution**: Ensure "Maps SDK for Android" is enabled in Google Cloud Console

### Issue: "Billing account required"
- **Solution**: Enable billing on your Google Cloud project

### Issue: "Package name mismatch"
- **Solution**: Double-check package name in build.gradle.kts matches Google Cloud Console

### Issue: "SHA-1 fingerprint mismatch"
- **Solution**: Verify SHA-1 fingerprint matches exactly (including colons)

## 📱 **Testing Commands**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check signing report
cd android
./gradlew signingReport
```

## 🔒 **Security Best Practices**

- ✅ **Restrict API key** to specific package name and SHA-1
- ✅ **Enable only required APIs** (Maps SDK for Android)
- ✅ **Monitor usage** in Google Cloud Console
- ✅ **Set up billing alerts** to avoid unexpected charges
- ✅ **Use different keys** for development and production

## 📞 **Support**

If issues persist:
1. Check Google Cloud Console for error details
2. Verify billing is enabled
3. Ensure Maps SDK for Android is enabled
4. Check Android logs for specific error messages
