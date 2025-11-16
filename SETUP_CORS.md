# Firebase Storage CORS Setup Guide

This guide helps you configure CORS (Cross-Origin Resource Sharing) for Firebase Storage so images load properly on web.

## Quick Setup (Automated)

### Windows (PowerShell)
```powershell
.\setup_cors.ps1
```

### Linux/Mac (Bash)
```bash
chmod +x setup_cors.sh
./setup_cors.sh
```

## Manual Setup

### Prerequisites

1. **Install Google Cloud SDK** (includes gsutil):
   - Windows: https://cloud.google.com/sdk/docs/install-windows
   - Mac: `brew install google-cloud-sdk`
   - Linux: https://cloud.google.com/sdk/docs/install-linux

2. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth login
   ```

3. **Set your Firebase project**:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

### Apply CORS Configuration

1. **The `cors.json` file is already created** in the project root.

2. **Apply CORS using gsutil**:
   ```bash
   gsutil cors set cors.json gs://YOUR_PROJECT_ID.appspot.com
   ```

   Replace `YOUR_PROJECT_ID` with your actual Firebase project ID (found in `.firebaserc`).

3. **Verify CORS is set**:
   ```bash
   gsutil cors get gs://YOUR_PROJECT_ID.appspot.com
   ```

## Alternative: Using Firebase Console

If you prefer using the web interface:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Storage** → **Settings** (gear icon)
4. Look for **CORS configuration** section
5. Add the following CORS rule:
   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET", "HEAD", "OPTIONS"],
       "responseHeader": [
         "Content-Type",
         "Access-Control-Allow-Origin",
         "Access-Control-Allow-Methods",
         "Access-Control-Allow-Headers"
       ],
       "maxAgeSeconds": 3600
     }
   ]
   ```

## Troubleshooting

### Error: "gsutil: command not found"
- Install Google Cloud SDK (see Prerequisites above)
- Make sure `gsutil` is in your PATH

### Error: "Access Denied"
- Make sure you're authenticated: `gcloud auth login`
- Verify you have Storage Admin permissions in Google Cloud Console

### Error: "Bucket not found"
- Check your project ID in `.firebaserc`
- Verify Firebase Storage is enabled in Firebase Console

### Images still not loading after CORS setup
1. Clear browser cache
2. Check browser console for CORS errors
3. Verify the CORS configuration:
   ```bash
   gsutil cors get gs://YOUR_PROJECT_ID.appspot.com
   ```
4. Make sure Firebase Storage security rules allow read access

## Security Note

The current CORS configuration allows all origins (`"origin": ["*"]`). For production, consider restricting to your specific domains:

```json
{
  "origin": [
    "https://your-domain.com",
    "https://*.web.app",
    "https://*.firebaseapp.com"
  ],
  ...
}
```

## Testing

After setting up CORS:

1. Open your web app
2. Open browser DevTools (F12)
3. Go to Network tab
4. Try loading an image
5. Check for CORS errors in Console tab
6. Images should load without CORS errors

