# Production Environment Setup Guide

This guide helps you configure environment variables and secrets for production deployment.

## Required Environment Variables

### Firebase Configuration

These are automatically configured when you initialize Firebase, but verify in `lib/firebase_options.dart`:

- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_API_KEY` - Your Firebase API key
- `FIREBASE_APP_ID` - Your Firebase app ID

### API Keys

#### 1. Google Maps API Key

**Where to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" → "Credentials"
4. Create or copy your API key
5. Enable these APIs:
   - Maps JavaScript API
   - Geocoding API
   - Places API

**How to set it:**
- For Flutter web: Set in `lib/services/api_key_service.dart` or via environment variable
- For Firebase Functions: Set via `firebase functions:config:set google.maps_api_key="YOUR_KEY"`

**Security:**
- Restrict API key to your domain in Google Cloud Console
- Add HTTP referrer restrictions:
  ```
  https://your-domain.com/*
  https://*.web.app/*
  https://*.firebaseapp.com/*
  ```

#### 2. OpenAI API Key

**Where to get it:**
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Navigate to "API Keys"
3. Create a new secret key

**How to set it:**
- For Flutter web: Set in `lib/services/api_key_service.dart` or via environment variable
- For Firebase Functions: Set via `firebase functions:config:set openai.api_key="YOUR_KEY"`

**Security:**
- Never expose in client-side code
- Use Firebase Functions for OpenAI API calls when possible
- Set usage limits in OpenAI dashboard

### Database Configuration (Optional - if using PostgreSQL)

If you plan to use PostgreSQL for payment processing (currently disabled):

```env
POSTGRES_HOST=your-postgres-host
POSTGRES_PORT=5432
POSTGRES_DB=vehicle_damage_payments
POSTGRES_USER=your-username
POSTGRES_PASSWORD=your-secure-password
```

**Recommended:** Use Cloud SQL (Google Cloud) or Supabase for managed PostgreSQL.

## Setting Environment Variables

### For Local Development

1. **Create `.env` file** (copy from `env.example`):
   ```bash
   cp env.example .env
   ```

2. **Fill in your values:**
   ```env
   GOOGLE_MAPS_API_KEY=AIzaSy...
   OPENAI_API_KEY=sk-...
   FIREBASE_PROJECT_ID=your-project-id
   ```

3. **Load in your app** (if using a package like `flutter_dotenv`)

### For Firebase Functions

Set environment variables for Firebase Functions:

```bash
firebase functions:config:set \
  openai.api_key="sk-..." \
  google.maps_api_key="AIzaSy..."
```

View current config:
```bash
firebase functions:config:get
```

### For GitHub Actions (CI/CD)

1. Go to your GitHub repository
2. Navigate to "Settings" → "Secrets and variables" → "Actions"
3. Add the following secrets:
   - `FIREBASE_SERVICE_ACCOUNT` - JSON content of Firebase service account
   - `FIREBASE_PROJECT_ID` - Your Firebase project ID
   - `FIREBASE_TOKEN` - Firebase CLI token (optional, for manual deployments)

**To get Firebase Service Account:**
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Copy the entire JSON content to GitHub Secrets

## Security Best Practices

### ✅ DO:
- Use environment variables for all secrets
- Restrict API keys to specific domains/IPs
- Use Firebase Functions for sensitive operations
- Enable Firebase App Check for additional security
- Regularly rotate API keys
- Use different keys for development and production

### ❌ DON'T:
- Commit `.env` files to version control
- Hardcode API keys in source code
- Expose API keys in client-side code
- Share API keys in public repositories
- Use production keys in development

## Verifying Configuration

### Check Firebase Configuration

```bash
firebase projects:list
firebase use <your-project-id>
firebase functions:config:get
```

### Test API Keys

**Google Maps:**
```bash
curl "https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway&key=YOUR_KEY"
```

**OpenAI:**
```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_KEY"
```

## Environment-Specific Configuration

### Development
- Use test API keys with limited quotas
- Enable debug logging
- Use Firebase emulators for local testing

### Staging
- Use staging Firebase project
- Use test API keys with higher quotas
- Enable error tracking

### Production
- Use production API keys
- Disable debug logging
- Enable all security features
- Set up monitoring and alerts

## Troubleshooting

### Issue: API key not working

**Check:**
1. API key is correctly set
2. API is enabled in Google Cloud Console
3. API key restrictions allow your domain
4. Billing is enabled (for Google Maps)

### Issue: Firebase Functions can't access config

**Solution:**
```bash
firebase functions:config:get
# If empty, set config:
firebase functions:config:set openai.api_key="YOUR_KEY"
# Redeploy functions:
firebase deploy --only functions
```

### Issue: CORS errors with API calls

**Solution:**
- Use Firebase Functions as proxy for external APIs
- Configure CORS headers in functions
- Add your domain to API key restrictions

---

**Last Updated**: 2024

