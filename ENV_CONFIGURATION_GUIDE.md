# Environment Variables Configuration Guide

This guide explains how to configure all API keys and project secrets in your `.env` file.

## 📁 File Structure

Your project uses environment variables in multiple locations:

1. **Root `.env`** - Main configuration file for Flutter app and backend server
2. **`backend/functions/.env`** - Configuration for Firebase Functions (local development)
3. **`env.example`** - Template file (safe to commit, no actual secrets)

## 🚀 Quick Start

1. **Copy the template:**
   ```bash
   # The .env file already exists with your current values
   # If you need to start fresh, copy from template:
   cp env.example .env
   ```

2. **Fill in missing values:**
   - Open `.env` in your editor
   - Replace all `your_*_here` placeholders with actual values
   - See sections below for where to get each key

3. **Restart your application:**
   - Flutter app: Restart completely (not just hot reload)
   - Backend server: Restart the Node.js server
   - Firebase Functions: Restart emulator or redeploy

## 📋 Required Environment Variables

### ✅ Already Configured

These are already set in your `.env` file:

- ✅ `SUPABASE_URL` - Your Supabase project URL
- ✅ `SUPABASE_ANON_KEY` - Supabase anonymous key
- ✅ `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` - Database connection
- ✅ `FIREBASE_PROJECT_ID` - Firebase project ID
- ✅ `FIREBASE_*_API_KEY` - Firebase API keys (for reference)

### ⚠️ Need to Configure

Replace these placeholders with actual values:

#### 1. Supabase Service Role Key

**Why:** Used by Firebase Functions for admin operations

**Where to get it:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `rodzemxwopecqpazkjyk`
3. Go to **Settings** → **API**
4. Find **"Project API keys"** section
5. Copy the **"service_role"** key (NOT the anon key)

**Set in:**
- Root `.env`: `SUPABASE_SERVICE_ROLE_KEY=...`
- `backend/functions/.env`: `SUPABASE_SERVICE_ROLE_KEY=...`

**⚠️ WARNING:** This key has admin privileges. Never expose it in client-side code!

#### 2. Google Maps API Key

**Why:** Used for maps, geocoding, and location services

**Where to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** → **Credentials**
4. Create or copy your API key
5. Enable these APIs:
   - Maps JavaScript API
   - Geocoding API
   - Places API

**Set in:**
- Root `.env`: `GOOGLE_MAPS_API_KEY=...`

**Security:** Restrict the key to your domain in Google Cloud Console

#### 3. OpenAI API Key

**Why:** Used for AI-powered features (chat, analysis, etc.)

**Where to get it:**
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Navigate to **API Keys**
3. Create a new secret key

**Set in:**
- Root `.env`: `OPENAI_API_KEY=...`
- `backend/functions/.env`: `OPENAI_API_KEY=...` (if used in functions)

**⚠️ WARNING:** Keep this secret! Never expose in client-side code.

#### 4. SendGrid API Key

**Why:** Used by Firebase Functions for sending email notifications

**Where to get it:**
1. Go to [SendGrid Dashboard](https://app.sendgrid.com/)
2. Navigate to **Settings** → **API Keys**
3. Create a new API key with "Full Access" or "Mail Send" permissions

**Set in:**
- Root `.env`: `SENDGRID_API_KEY=...`
- `backend/functions/.env`: `SENDGRID_API_KEY=...`

**⚠️ WARNING:** Keep this secret! Only used in Firebase Functions.

#### 5. Payment Processor API Key (Optional)

**Why:** If you're using Stripe, PayPal, or another payment processor

**Where to get it:**
- Depends on your payment processor
- Usually found in the processor's dashboard under API keys

**Set in:**
- Root `.env`: `PAYMENT_PROCESSOR_API_KEY=...`

## 🔧 How Each Component Uses Environment Variables

### Flutter App (`lib/main.dart`)

The Flutter app loads environment variables using `flutter_dotenv`:

```dart
await dotenv.load(fileName: ".env");
final supabaseUrl = dotenv.env['SUPABASE_URL'];
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
```

**Uses:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY` (via ApiKeyService)
- `OPENAI_API_KEY` (via ApiKeyService)

### Backend Server (`backend/server.js`)

The Node.js server loads environment variables using `dotenv`:

```javascript
require('dotenv').config();
const password = process.env.POSTGRES_PASSWORD;
```

**Uses:**
- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `POSTGRES_SSL`, `POSTGRES_SSL_REJECT_UNAUTHORIZED`
- `PORT`, `HOST`

### Firebase Functions (`backend/functions/index.js`)

Firebase Functions can use either:
1. **Firebase Functions config** (for production): `firebase functions:config:set`
2. **Environment variables** (for local development): `.env` file

**For local development:**
- Uses `backend/functions/.env` file
- Loaded via `process.env.VARIABLE_NAME`

**For production:**
- Use Firebase Functions config:
  ```bash
  firebase functions:config:set \
    supabase.url="https://..." \
    supabase.service_role_key="..." \
    sendgrid.api_key="..."
  ```

**Uses:**
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SENDGRID_API_KEY`
- `OPENAI_API_KEY` (if used)

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Keep `.env` files in `.gitignore` (already configured)
- ✅ Use different keys for development and production
- ✅ Restrict API keys to specific domains/IPs when possible
- ✅ Rotate API keys regularly
- ✅ Use Firebase Functions for sensitive operations
- ✅ Never commit `.env` files to version control

### ❌ DON'T:
- ❌ Commit `.env` files to git
- ❌ Hardcode API keys in source code
- ❌ Expose service role keys in client-side code
- ❌ Share API keys in public repositories
- ❌ Use production keys in development

## 📝 Environment-Specific Files

For different environments, you can create:

- `.env.development` - Development environment
- `.env.staging` - Staging environment
- `.env.production` - Production environment

These are all in `.gitignore` and won't be committed.

## 🧪 Testing Your Configuration

### Test Supabase Connection

```dart
// Run from Flutter app
flutter run lib/verify_supabase_key.dart
```

### Test Database Connection

```bash
# From backend directory
node -e "require('dotenv').config(); console.log('DB Host:', process.env.POSTGRES_HOST);"
```

### Test Firebase Functions Locally

```bash
cd backend/functions
firebase emulators:start --only functions
```

## 🚨 Troubleshooting

### "Environment variable not found" error

1. **Check file location:** `.env` must be in the project root
2. **Check file name:** Must be exactly `.env` (not `.env.txt` or `.env.local`)
3. **Check encoding:** File should be UTF-8 without BOM
4. **Restart app:** Environment variables are loaded at startup

### "Invalid API key" error

1. **Check for spaces:** No spaces before or after `=`
2. **Check for quotes:** Don't use quotes around values
3. **Check key format:** Verify the key is complete and correct
4. **Check key source:** Get a fresh key from the service dashboard

### Firebase Functions not loading variables

1. **Check file location:** `backend/functions/.env` must exist
2. **For production:** Use `firebase functions:config:set` instead
3. **Check variable names:** Must match exactly (case-sensitive)

## 📚 Additional Resources

- [Supabase API Keys Documentation](https://supabase.com/docs/guides/api/api-keys)
- [Firebase Functions Config](https://firebase.google.com/docs/functions/config-env)
- [Flutter Dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [Node.js Dotenv Package](https://www.npmjs.com/package/dotenv)

## ✅ Checklist

Before deploying to production:

- [ ] All required API keys are set in `.env`
- [ ] `SUPABASE_SERVICE_ROLE_KEY` is configured
- [ ] `GOOGLE_MAPS_API_KEY` is configured and restricted
- [ ] `OPENAI_API_KEY` is configured (if using AI features)
- [ ] `SENDGRID_API_KEY` is configured (if using email)
- [ ] Firebase Functions config is set for production
- [ ] All keys are tested and working
- [ ] `.env` is in `.gitignore` (already done)
- [ ] No secrets are hardcoded in source code

---

**Last Updated:** $(Get-Date -Format "yyyy-MM-dd")
**Status:** ✅ Configuration complete - Fill in missing API keys as needed

