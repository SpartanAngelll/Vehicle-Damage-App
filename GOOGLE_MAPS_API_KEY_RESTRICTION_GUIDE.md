# Google Maps API Key Restriction Guide

This guide helps you restrict your Google Maps API key to production domains for security.

## ⚠️ Why Restrict API Keys?

API key restrictions prevent unauthorized usage and protect against:
- Unauthorized API calls from other domains
- Unexpected billing charges
- API quota exhaustion
- Security vulnerabilities

## 🔍 Step 1: Find Your Google Maps API Key

### For Android:
1. Check `android/local.properties`:
   ```properties
   GOOGLE_MAPS_API_KEY=your_key_here
   ```

### For Web:
1. Check environment variables or Firebase Functions config
2. Or check `lib/services/api_key_service.dart` (if used)

## 🔒 Step 2: Restrict the API Key

### For Web (Production)

1. **Go to Google Cloud Console**
   - Navigate to: https://console.cloud.google.com/
   - Select your project: `vehicle-damage-app`
   - Go to **APIs & Services** → **Credentials**

2. **Find Your Google Maps API Key**
   - Look for the key used in your web deployment
   - Click on the key name to edit

3. **Set Application Restrictions**
   - Under **Application restrictions**: Select **HTTP referrers (web sites)**
   - In **Website restrictions**, add these referrers (one per line):
     ```
     https://vehicle-damage-app.web.app/*
     https://vehicle-damage-app.firebaseapp.com/*
     ```
   - **Important**: Do NOT include `http://localhost:*` for production keys
   - If you have a custom domain, add it:
     ```
     https://yourdomain.com/*
     https://www.yourdomain.com/*
     ```

4. **Set API Restrictions**
   - Under **API restrictions**: Select **Restrict key**
   - Select only these APIs:
     - ✅ Maps JavaScript API
     - ✅ Geocoding API
     - ✅ Places API (if you use Places)
   - Click **Save**

### For Android (Production)

1. **Go to Google Cloud Console**
   - Navigate to: https://console.cloud.google.com/
   - Select your project: `vehicle-damage-app`
   - Go to **APIs & Services** → **Credentials**

2. **Find Your Google Maps API Key**
   - Look for the key used in your Android app
   - Click on the key name to edit

3. **Set Application Restrictions**
   - Under **Application restrictions**: Select **Android apps**
   - Click **Add an item**
   - Enter your package name: `com.example.vehicle_damage_app`
   - Get your SHA-1 certificate fingerprint:
     ```bash
     # For debug keystore
     keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # For release keystore (if you have one)
     keytool -list -v -keystore android/app/release.keystore -alias your-alias
     ```
   - Copy the SHA-1 fingerprint (looks like: `AA:BB:CC:DD:EE:FF:...`)
   - Paste it in the **SHA-1 certificate fingerprint** field

4. **Set API Restrictions**
   - Under **API restrictions**: Select **Restrict key**
   - Select only these APIs:
     - ✅ Maps SDK for Android
     - ✅ Geocoding API
     - ✅ Places API (if you use Places)
   - Click **Save**

### For iOS (if using Google Maps)

1. **Go to Google Cloud Console**
   - Navigate to: https://console.cloud.google.com/
   - Select your project: `vehicle-damage-app`
   - Go to **APIs & Services** → **Credentials**

2. **Find Your Google Maps API Key**
   - Look for the key used in your iOS app
   - Click on the key name to edit

3. **Set Application Restrictions**
   - Under **Application restrictions**: Select **iOS apps**
   - Click **Add an item**
   - Enter your bundle ID: `com.example.vehicleDamageApp`

4. **Set API Restrictions**
   - Under **API restrictions**: Select **Restrict key**
   - Select only these APIs:
     - ✅ Maps SDK for iOS
     - ✅ Geocoding API
     - ✅ Places API (if you use Places)
   - Click **Save**

## 🧪 Step 3: Test the Restrictions

### For Web:
1. Deploy your app to production
2. Test map functionality
3. Try accessing the API key from a different domain (should fail)
4. Check Google Cloud Console → APIs & Services → Credentials → API key → Usage

### For Android:
1. Build a release APK
2. Install on a device
3. Test map functionality
4. Try using the key from a different app (should fail)

## 🔄 Step 4: Create Separate Development Keys (Recommended)

For better security, create separate API keys for development and production:

### Development Key:
- **Web**: Include `http://localhost:*` in referrers
- **Android**: Use debug keystore SHA-1
- **Restrictions**: Less strict (for easier development)

### Production Key:
- **Web**: Only production domains
- **Android**: Use release keystore SHA-1
- **Restrictions**: Strict (production only)

## 📊 Step 5: Monitor Usage

1. **Set Up Alerts**
   - Go to Google Cloud Console → APIs & Services → Dashboard
   - Set up billing alerts
   - Monitor API usage

2. **Review Usage Regularly**
   - Check API key usage in Google Cloud Console
   - Look for unusual patterns
   - Review billing statements

## ✅ Verification Checklist

- [ ] API key restricted to production domains/apps only
- [ ] API restrictions set to only required APIs
- [ ] Development key created (if needed)
- [ ] Production key tested and working
- [ ] Usage monitoring set up
- [ ] Billing alerts configured

## 🚨 Troubleshooting

### Issue: Maps not loading after restrictions
**Solution**: 
- Verify the domain/app matches exactly
- Check for typos in package name or domain
- Wait 5-10 minutes for changes to propagate
- Check browser console for API key errors

### Issue: Development not working
**Solution**:
- Create a separate development key with localhost allowed
- Use different keys for dev and production
- Update your local configuration

### Issue: API key quota exceeded
**Solution**:
- Check usage in Google Cloud Console
- Verify restrictions are working
- Consider enabling billing and setting quotas
- Review for unauthorized usage

## 📚 Additional Resources

- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Maps JavaScript API Documentation](https://developers.google.com/maps/documentation/javascript)
- [Maps SDK for Android Documentation](https://developers.google.com/maps/documentation/android-sdk)

---

**Status**: Guide created - Follow steps to restrict your API keys
**Last Updated**: Security audit

