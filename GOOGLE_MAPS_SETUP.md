# Google Maps API Key Setup

## Issue
The map is not loading because the Google Maps API key is not configured.

## Solution

### Step 1: Get Google Maps API Key

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create a new project** or select an existing one
3. **Enable the Maps SDK for Android**:
   - Go to "APIs & Services" > "Library"
   - Search for "Maps SDK for Android"
   - Click on it and press "Enable"
4. **Create credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the generated API key

### Step 2: Configure the API Key

1. **Open the file**: `android/app/src/main/res/values/strings.xml`
2. **Replace the placeholder**: Change `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key
3. **Save the file**

### Step 3: Test the App

1. **Hot restart** the app (not just hot reload)
2. **Navigate to** the service professional profile
3. **Tap "Set Location"** to open the map picker
4. **The map should now load** and be interactive

## Example

Your `strings.xml` should look like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">vehicle_damage_app</string>
    <string name="google_maps_key">AIzaSyBvOkBw3cJ8X8X8X8X8X8X8X8X8X8X8X8X8</string>
</resources>
```

## Important Notes

- **Never commit your API key** to version control
- **Restrict your API key** to your app's package name and SHA-1 fingerprint
- **Set up billing** on your Google Cloud project (Google Maps requires billing to be enabled)
- **Hot restart** is required after changing the API key (not just hot reload)

## Troubleshooting

If the map still doesn't load:
1. Check that the API key is correct
2. Verify that "Maps SDK for Android" is enabled
3. Check that billing is enabled on your Google Cloud project
4. Restart the app completely
5. Check the Android logs for any error messages
