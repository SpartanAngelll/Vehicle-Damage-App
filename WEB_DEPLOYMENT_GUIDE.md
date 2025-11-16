# Web Deployment Guide - Multi-Service Professional Network

This comprehensive guide will walk you through deploying your Flutter web application to production.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Recommended Hosting Stack](#recommended-hosting-stack)
3. [Pre-Deployment Configuration](#pre-deployment-configuration)
4. [Firebase Hosting Deployment (Recommended)](#firebase-hosting-deployment-recommended)
5. [Alternative Hosting Options](#alternative-hosting-options)
6. [Post-Deployment Verification](#post-deployment-verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- **Flutter SDK** (3.7.2 or higher)
  ```bash
  flutter --version
  ```
- **Firebase CLI** (for Firebase Hosting)
  ```bash
  npm install -g firebase-tools
  firebase login
  ```
- **Node.js** (v18 or higher) - for backend functions
- **Git** - for version control

### Required Accounts
- **Firebase Account** - [https://firebase.google.com](https://firebase.google.com)
- **Google Cloud Platform Account** - (linked to Firebase)
- **Domain Name** (optional but recommended)

---

## Recommended Hosting Stack

### Primary Stack: Firebase Hosting + Firebase Functions

**Why This Stack?**
- ✅ **Seamless Integration**: Already using Firebase (Auth, Firestore, Storage)
- ✅ **Zero Configuration**: Works out of the box with your existing setup
- ✅ **Global CDN**: Fast content delivery worldwide
- ✅ **Automatic SSL**: Free SSL certificates
- ✅ **Scalable**: Handles traffic spikes automatically
- ✅ **Cost-Effective**: Generous free tier, pay-as-you-go pricing
- ✅ **Easy Deployment**: Single command deployment

**Architecture:**
```
┌─────────────────┐
│  Firebase       │
│  Hosting        │  ← Flutter Web App (build/web)
│  (CDN + SSL)    │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
┌────────▼────────┐  ┌─────▼──────────┐
│  Firebase       │  │  Firebase      │
│  Functions      │  │  Firestore     │
│  (Backend API)  │  │  (Database)    │
└─────────────────┘  └────────────────┘
```

### Alternative Stacks

#### Option 2: Vercel + Supabase
- **Frontend**: Vercel (excellent Flutter web support)
- **Backend**: Supabase (PostgreSQL + Auth)
- **Best for**: Teams familiar with Vercel ecosystem

#### Option 3: Netlify + AWS Lambda
- **Frontend**: Netlify (easy CI/CD)
- **Backend**: AWS Lambda (serverless functions)
- **Best for**: Enterprise-scale applications

#### Option 4: Self-Hosted (VPS)
- **Frontend**: Nginx + Flutter web build
- **Backend**: Node.js + PostgreSQL on VPS
- **Best for**: Full control, custom infrastructure

**For this guide, we'll use Firebase Hosting (Option 1) as it's the most straightforward for your current setup.**

---

## Pre-Deployment Configuration

### Step 1: Verify Payment Workflow is Disabled

The payment workflow has been disabled for initial launch. Verify this in:
- `lib/services/chat_service.dart` - Payment creation code is commented out

### Step 2: Verify PIN Verification is Active

PIN verification system is active and working. No changes needed.

### Step 3: Verify Job Reviews are Enabled

Review system is enabled. Verify in:
- `lib/services/review_service.dart` - Review submission methods
- `lib/widgets/review_submission_dialog.dart` - Review UI

### Step 4: Configure Firebase Project

1. **Create/Select Firebase Project:**
   ```bash
   firebase projects:list
   firebase use <your-project-id>
   ```

2. **Enable Required Services:**
   - ✅ Authentication (Email/Password, Google)
   - ✅ Firestore Database
   - ✅ Storage
   - ✅ Hosting
   - ✅ Functions

3. **Configure Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Deploy Firestore Indexes:**
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Step 5: Set Up Environment Variables

Create a `.env` file in the project root (copy from `env.example`):
```bash
cp env.example .env
```

Fill in your API keys:
```env
GOOGLE_MAPS_API_KEY=your_actual_google_maps_key
OPENAI_API_KEY=your_actual_openai_key
FIREBASE_PROJECT_ID=your_firebase_project_id
```

**Important**: Never commit `.env` to version control!

### Step 6: Configure Firebase Functions

1. **Navigate to functions directory:**
   ```bash
   cd backend/functions
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set environment variables for functions:**
   ```bash
   firebase functions:config:set \
     openai.api_key="your_openai_key" \
     google.maps_api_key="your_google_maps_key"
   ```

---

## Firebase Hosting Deployment (Recommended)

### Step 1: Build Flutter Web App

1. **Enable web support (if not already):**
   ```bash
   flutter config --enable-web
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build for production:**
   ```bash
   flutter build web --release --no-tree-shake-icons
   ```
   
   **Note**: The `--no-tree-shake-icons` flag is required due to non-constant IconData instances in the codebase.

4. **Verify build output:**
   ```bash
   ls build/web
   ```
   You should see: `index.html`, `main.dart.js`, `assets/`, etc.

### Step 2: Configure Firebase Hosting

Your `firebase.json` is already configured:
```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Step 3: Deploy to Firebase Hosting

1. **Initialize Firebase (if not done):**
   ```bash
   firebase init hosting
   ```
   - Select existing project
   - Public directory: `build/web`
   - Configure as single-page app: **Yes**
   - Set up automatic builds: **No** (we'll do manual for now)

2. **Deploy:**
   ```bash
   firebase deploy --only hosting
   ```

3. **Your app is now live at:**
   ```
   https://<your-project-id>.web.app
   https://<your-project-id>.firebaseapp.com
   ```

### Step 4: Deploy Firebase Functions

1. **Deploy functions:**
   ```bash
   firebase deploy --only functions
   ```

2. **Verify functions are running:**
   ```bash
   firebase functions:list
   ```

### Step 5: Set Up Custom Domain (Optional)

1. **In Firebase Console:**
   - Go to Hosting → Add custom domain
   - Follow the verification steps
   - SSL certificate will be automatically provisioned

2. **Update DNS records** as instructed by Firebase

---

## Alternative Hosting Options

### Option A: Vercel Deployment

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Create `vercel.json`:**
   ```json
   {
     "buildCommand": "flutter build web --release",
     "outputDirectory": "build/web",
     "rewrites": [
       { "source": "/(.*)", "destination": "/index.html" }
     ]
   }
   ```

3. **Deploy:**
   ```bash
   vercel --prod
   ```

### Option B: Netlify Deployment

1. **Install Netlify CLI:**
   ```bash
   npm i -g netlify-cli
   ```

2. **Create `netlify.toml`:**
   ```toml
   [build]
     command = "flutter build web --release"
     publish = "build/web"
   
   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

3. **Deploy:**
   ```bash
   netlify deploy --prod
   ```

### Option C: Self-Hosted (Nginx)

1. **Build the app:**
   ```bash
   flutter build web --release
   ```

2. **Copy to server:**
   ```bash
   scp -r build/web/* user@server:/var/www/html/
   ```

3. **Configure Nginx:**
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;
       
       root /var/www/html;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

---

## Post-Deployment Verification

### 1. Test Core Functionality

- [ ] **Authentication**: Sign up, login, logout
- [ ] **Profile Setup**: Customer and professional profiles
- [ ] **Search**: Search for service professionals
- [ ] **Booking**: Create a booking through chat
- [ ] **PIN Verification**: Start job with PIN
- [ ] **Job Completion**: Mark job as completed
- [ ] **Reviews**: Submit review after job completion
- [ ] **Chat**: Send messages, view chat history

### 2. Test on Multiple Devices

- [ ] Desktop browsers (Chrome, Firefox, Safari, Edge)
- [ ] Mobile browsers (iOS Safari, Chrome Mobile)
- [ ] Tablet devices

### 3. Performance Check

- [ ] **Page Load Time**: < 3 seconds
- [ ] **Time to Interactive**: < 5 seconds
- [ ] **Lighthouse Score**: > 80 (Performance, Accessibility, Best Practices, SEO)

Run Lighthouse:
```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Run audit
lighthouse https://your-app-url.web.app --view
```

### 4. Security Check

- [ ] **HTTPS**: All traffic is encrypted
- [ ] **Firestore Rules**: Properly configured
- [ ] **Storage Rules**: Properly configured
- [ ] **API Keys**: Not exposed in client code
- [ ] **CORS**: Properly configured

### 5. Monitor Firebase Console

- [ ] **Usage**: Check Firestore reads/writes
- [ ] **Errors**: Check Functions logs
- [ ] **Performance**: Monitor response times

---

## Automated Deployment Scripts

### Quick Deploy Script

Create `deploy_web.sh` (Linux/Mac) or `deploy_web.bat` (Windows):

**deploy_web.sh:**
```bash
#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

# Deploy to Firebase
echo "☁️ Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Deployment complete!"
echo "🌐 Your app is live at: https://$(firebase use | grep 'Using' | awk '{print $2}').web.app"
```

**deploy_web.bat:**
```batch
@echo off
echo 🚀 Starting deployment...

echo 📦 Getting Flutter dependencies...
flutter pub get

echo 🔨 Building Flutter web app...
flutter build web --release --web-renderer canvaskit

echo ☁️ Deploying to Firebase...
firebase deploy --only hosting,functions

echo ✅ Deployment complete!
```

Make executable (Linux/Mac):
```bash
chmod +x deploy_web.sh
```

---

## CI/CD Setup (GitHub Actions)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.7.2'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build web app
        run: flutter build web --release --web-renderer canvaskit
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

---

## Troubleshooting

### Issue: Build fails with "web renderer" error

**Solution:**
```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
```

### Issue: Firebase deploy fails with permission error

**Solution:**
```bash
firebase login --reauth
firebase use <your-project-id>
```

### Issue: App loads but shows blank screen

**Check:**
1. Browser console for errors
2. Firebase configuration in `lib/firebase_options.dart`
3. Network tab for failed requests

**Solution:**
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Issue: Functions timeout

**Solution:**
Increase timeout in `backend/functions/index.js`:
```javascript
exports.myFunction = functions
  .runWith({ timeoutSeconds: 60, memory: '512MB' })
  .https.onRequest((req, res) => {
    // Your code
  });
```

### Issue: CORS errors

**Solution:**
Configure CORS in Firebase Functions:
```javascript
const cors = require('cors')({ origin: true });
```

---

## Performance Optimization

### 1. Enable Code Splitting

In `web/index.html`, add:
```html
<script>
  window.flutterConfiguration = {
    canvasKitBaseUrl: "https://unpkg.com/canvaskit-wasm@0.33.0/bin/",
  };
</script>
```

### 2. Optimize Images

- Use WebP format
- Compress images before upload
- Use lazy loading for images

### 3. Enable Caching

Firebase Hosting automatically caches static assets. For custom caching:
```json
{
  "hosting": {
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

---

## Monitoring and Analytics

### 1. Firebase Analytics

Already integrated via `firebase_analytics` package.

### 2. Error Tracking

Consider adding Sentry:
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

### 3. Performance Monitoring

Firebase Performance Monitoring is available for web.

---

## Next Steps

1. ✅ **Deploy to production** using the steps above
2. ✅ **Set up monitoring** and error tracking
3. ✅ **Configure custom domain** for branding
4. ✅ **Set up CI/CD** for automated deployments
5. ✅ **Enable payment gateway** when ready (currently disabled)
6. ✅ **Scale infrastructure** as traffic grows

---

## Support

For issues or questions:
- Check Firebase Console logs
- Review Flutter web documentation
- Check Firebase Hosting documentation

---

**Last Updated**: 2024
**Version**: 1.0.0

