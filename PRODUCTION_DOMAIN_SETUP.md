# Production Domain Setup Guide

This comprehensive guide will walk you through setting up custom production domains for your Vehicle Damage App.

## Table of Contents
1. [Overview](#overview)
2. [Firebase Hosting Custom Domain](#firebase-hosting-custom-domain)
3. [Supabase Domain Configuration](#supabase-domain-configuration)
4. [API Key Domain Restrictions](#api-key-domain-restrictions)
5. [DNS Configuration](#dns-configuration)
6. [SSL Certificate Setup](#ssl-certificate-setup)
7. [Post-Setup Verification](#post-setup-verification)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Your app needs domain configuration in three main areas:

1. **Firebase Hosting** - For serving your web app
2. **Supabase** - For authentication redirect URLs
3. **API Keys** - For security restrictions (Google Maps, etc.)

### Default Domains

Before custom domain setup, your app is available at:
- `https://vehicle-damage-app.web.app`
- `https://vehicle-damage-app.firebaseapp.com`

After setup, you'll have:
- `https://yourdomain.com` (primary)
- `https://www.yourdomain.com` (optional)

---

## Firebase Hosting Custom Domain

### Step 1: Add Custom Domain in Firebase Console

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `vehicle-damage-app`

2. **Navigate to Hosting**
   - Click **Hosting** in the left sidebar
   - Click **Add custom domain**

3. **Enter Your Domain**
   - Type your domain (e.g., `yourdomain.com`)
   - Click **Continue**

4. **Choose Domain Type**
   - **Primary domain**: `yourdomain.com` (recommended)
   - **Subdomain**: `www.yourdomain.com` (optional, can add later)

### Step 2: Verify Domain Ownership

Firebase will provide you with verification options:

#### Option A: HTML File Upload (Recommended)
1. Download the HTML verification file
2. Upload it to your domain's root directory
3. Access it at: `https://yourdomain.com/firebase-verification.html`
4. Click **Verify** in Firebase Console

#### Option B: DNS TXT Record
1. Add a TXT record to your DNS:
   ```
   Type: TXT
   Name: @ (or yourdomain.com)
   Value: [verification code from Firebase]
   TTL: 3600
   ```
2. Wait for DNS propagation (5-60 minutes)
3. Click **Verify** in Firebase Console

### Step 3: Configure DNS Records

After verification, Firebase will provide DNS records to add:

#### For Root Domain (yourdomain.com)

Add an **A record**:
```
Type: A
Name: @ (or yourdomain.com)
Value: [IP addresses from Firebase - usually 2-4 IPs]
TTL: 3600
```

**Example Firebase A records:**
```
151.101.1.195
151.101.65.195
```

#### For WWW Subdomain (www.yourdomain.com)

Add a **CNAME record**:
```
Type: CNAME
Name: www
Value: [hosting value from Firebase, e.g., vehicle-damage-app.web.app]
TTL: 3600
```

### Step 4: Wait for SSL Certificate

1. **Firebase automatically provisions SSL**
   - This usually takes 10-60 minutes
   - You'll see "Provisioning" status in Firebase Console

2. **Check Status**
   - Go to Hosting → Custom domains
   - Status should change from "Provisioning" to "Connected"

3. **SSL Certificate Details**
   - Firebase uses Let's Encrypt
   - Automatically renews every 90 days
   - No manual configuration needed

### Step 5: Update Firebase Configuration

After domain is connected, update your app configuration:

1. **Update `firebase.json`** (if needed):
   ```json
   {
     "hosting": {
       "public": "build/web",
       "site": "yourdomain.com",
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```

2. **Redeploy** (if you changed firebase.json):
   ```bash
   firebase deploy --only hosting
   ```

---

## Supabase Domain Configuration

### Step 1: Add Redirect URLs

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project: `rodzemxwopecqpazkjyk`

2. **Navigate to Authentication Settings**
   - Go to **Authentication** → **URL Configuration**

3. **Add Site URL**
   - **Site URL**: `https://yourdomain.com`
   - This is the default redirect URL after authentication

4. **Add Redirect URLs**
   - Click **Add URL**
   - Add these URLs (one per line):
     ```
     https://yourdomain.com
     https://www.yourdomain.com
     https://yourdomain.com/**
     https://www.yourdomain.com/**
     ```
   - Also keep existing Firebase URLs:
     ```
     https://vehicle-damage-app.web.app
     https://vehicle-damage-app.firebaseapp.com
     ```

### Step 2: Update Supabase Client Configuration

Update your Supabase client initialization in Flutter:

**File: `lib/services/supabase_service.dart`** (or wherever you initialize Supabase)

```dart
final supabaseUrl = kIsWeb 
  ? 'https://yourdomain.com' // Production domain
  : 'https://rodzemxwopecqpazkjyk.supabase.co'; // Supabase project URL

final supabase = SupabaseClient(
  supabaseUrl,
  supabaseAnonKey,
);
```

**Note**: For web, you might want to use environment variables:

```dart
final supabaseUrl = kIsWeb 
  ? const String.fromEnvironment('SUPABASE_URL', 
      defaultValue: 'https://rodzemxwopecqpazkjyk.supabase.co')
  : 'https://rodzemxwopecqpazkjyk.supabase.co';
```

### Step 3: Update Email Templates (Optional)

If you're using Supabase email templates:

1. Go to **Authentication** → **Email Templates**
2. Update any hardcoded URLs in templates
3. Replace `vehicle-damage-app.web.app` with `yourdomain.com`

---

## API Key Domain Restrictions

### Google Maps API Key

#### Step 1: Find Your API Key

1. **Check your configuration:**
   - `lib/services/api_key_service.dart`
   - Environment variables
   - Firebase Functions config

2. **Or get from Google Cloud Console:**
   - Go to: https://console.cloud.google.com/
   - Navigate to **APIs & Services** → **Credentials**

#### Step 2: Restrict API Key to Production Domains

1. **Go to Google Cloud Console**
   - Navigate to: https://console.cloud.google.com/
   - Select project: `vehicle-damage-app`
   - Go to **APIs & Services** → **Credentials**

2. **Click on your Google Maps API Key**

3. **Set Application Restrictions**
   - Under **Application restrictions**: Select **HTTP referrers (web sites)**
   - Add these referrers (one per line):
     ```
     https://yourdomain.com/*
     https://www.yourdomain.com/*
     https://vehicle-damage-app.web.app/*
     https://vehicle-damage-app.firebaseapp.com/*
     ```
   - **Important**: Include the `/*` wildcard to allow all paths

4. **Set API Restrictions**
   - Under **API restrictions**: Select **Restrict key**
   - Select only these APIs:
     - ✅ Maps JavaScript API
     - ✅ Geocoding API
     - ✅ Places API (if used)
   - Click **Save**

#### Step 3: Test API Key

After restrictions are set:

1. **Test from production domain:**
   ```bash
   curl "https://maps.googleapis.com/maps/api/geocode/json?address=test&key=YOUR_KEY"
   ```

2. **Verify it works in your app:**
   - Visit `https://yourdomain.com`
   - Test map functionality
   - Check browser console for errors

### Other API Keys

If you use other API keys (OpenAI, etc.), apply similar restrictions:

1. **OpenAI API Key** (if exposed to client)
   - Usually kept server-side only
   - If client-side, restrict by domain

2. **Firebase API Keys**
   - These are meant to be public
   - Security comes from Firebase project settings
   - No domain restrictions needed

---

## DNS Configuration

### Complete DNS Setup Example

Here's a complete example for a domain registrar (e.g., GoDaddy, Namecheap, Cloudflare):

#### For Root Domain (yourdomain.com)

```
Type    Name    Value                    TTL
A       @       151.101.1.195           3600
A       @       151.101.65.195          3600
TXT     @       firebase-verification   3600
```

#### For WWW Subdomain

```
Type    Name    Value                                    TTL
CNAME   www     vehicle-damage-app.web.app              3600
```

#### Additional Records (Optional)

```
Type    Name    Value                    TTL
MX      @       mail.yourdomain.com     3600
TXT     @       v=spf1 include:_spf...  3600
```

### DNS Propagation

- **Typical wait time**: 5-60 minutes
- **Maximum wait time**: Up to 48 hours (rare)
- **Check propagation**: Use https://dnschecker.org/

### Common DNS Providers

#### Cloudflare
1. Add site to Cloudflare
2. Update nameservers at your registrar
3. Add A and CNAME records in Cloudflare dashboard

#### GoDaddy
1. Go to DNS Management
2. Add/Edit records
3. Save changes

#### Namecheap
1. Go to Domain List → Manage
2. Advanced DNS tab
3. Add/Edit records

---

## SSL Certificate Setup

### Firebase Automatic SSL

Firebase automatically provisions SSL certificates via Let's Encrypt:

1. **Automatic Provisioning**
   - Happens after domain verification
   - Usually completes in 10-60 minutes
   - No manual steps required

2. **Certificate Details**
   - **Provider**: Let's Encrypt
   - **Type**: Domain Validated (DV)
   - **Auto-renewal**: Every 90 days
   - **Coverage**: Both root and www subdomain

3. **Check Certificate Status**
   - Firebase Console → Hosting → Custom domains
   - Status should show "Connected" (green checkmark)

### Manual SSL (If Needed)

If you need to use your own SSL certificate:

1. **Generate Certificate**
   - Use Let's Encrypt: `certbot certonly --manual`
   - Or use your CA's certificate

2. **Upload to Firebase**
   - Firebase Console → Hosting → Custom domains
   - Click on your domain
   - Upload certificate files

**Note**: Firebase's automatic SSL is recommended and easier.

---

## Post-Setup Verification

### 1. Test Domain Accessibility

```bash
# Test root domain
curl -I https://yourdomain.com

# Test www subdomain
curl -I https://www.yourdomain.com

# Should return HTTP 200
```

### 2. Test SSL Certificate

```bash
# Check SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Or use online tool
# https://www.ssllabs.com/ssltest/
```

### 3. Test Authentication Flow

1. **Visit**: `https://yourdomain.com`
2. **Sign up/Login**: Test authentication
3. **Check redirects**: Should redirect back to your domain
4. **Check console**: No CORS or domain errors

### 4. Test API Keys

1. **Google Maps**: Verify maps load correctly
2. **Check browser console**: No API key errors
3. **Test from different locations**: Ensure restrictions work

### 5. Test Firebase Functions

```bash
# List functions
firebase functions:list

# Test a function
curl https://yourdomain.com/api/your-function
```

### 6. Performance Check

```bash
# Run Lighthouse audit
lighthouse https://yourdomain.com --view

# Check Core Web Vitals
# Use Google PageSpeed Insights
```

---

## Troubleshooting

### Issue: Domain Not Resolving

**Symptoms:**
- Domain shows "This site can't be reached"
- DNS lookup fails

**Solutions:**
1. **Check DNS records** are correct
2. **Wait for propagation** (can take up to 48 hours)
3. **Verify nameservers** are correct
4. **Check DNS checker**: https://dnschecker.org/

### Issue: SSL Certificate Not Provisioning

**Symptoms:**
- Domain shows "Not Secure"
- SSL status stuck on "Provisioning"

**Solutions:**
1. **Wait longer** (can take up to 24 hours)
2. **Check DNS records** are correct
3. **Verify domain ownership** is still valid
4. **Contact Firebase support** if stuck > 24 hours

### Issue: Authentication Redirects Not Working

**Symptoms:**
- Users redirected to wrong URL after login
- "Redirect URI mismatch" errors

**Solutions:**
1. **Check Supabase redirect URLs** include your domain
2. **Verify Site URL** in Supabase settings
3. **Check Firebase Auth domains** in Firebase Console
4. **Clear browser cache** and cookies

### Issue: API Keys Not Working

**Symptoms:**
- Maps not loading
- "API key not valid" errors

**Solutions:**
1. **Check domain restrictions** include your domain
2. **Verify API key** is correct
3. **Check API is enabled** in Google Cloud Console
4. **Test from production domain** (not localhost)

### Issue: CORS Errors

**Symptoms:**
- "CORS policy" errors in console
- API calls failing

**Solutions:**
1. **Check Firebase Functions CORS** configuration
2. **Verify allowed origins** include your domain
3. **Check Supabase CORS** settings
4. **Update backend CORS** headers

### Issue: Mixed Content Warnings

**Symptoms:**
- Browser shows "Mixed Content" warnings
- Some resources load over HTTP instead of HTTPS

**Solutions:**
1. **Ensure all URLs** use HTTPS
2. **Check Firebase Hosting** forces HTTPS
3. **Update hardcoded HTTP URLs** in code
4. **Use relative URLs** where possible

---

## Environment-Specific Configuration

### Development

Keep localhost URLs for development:
```
http://localhost:3000
http://127.0.0.1:3000
```

### Staging

Use a staging subdomain:
```
https://staging.yourdomain.com
```

### Production

Use your main domain:
```
https://yourdomain.com
https://www.yourdomain.com
```

### Environment Variables

Create environment-specific configs:

**`.env.production`:**
```env
SUPABASE_URL=https://rodzemxwopecqpazkjyk.supabase.co
SITE_URL=https://yourdomain.com
GOOGLE_MAPS_API_KEY=your_production_key
```

**`.env.development`:**
```env
SUPABASE_URL=https://rodzemxwopecqpazkjyk.supabase.co
SITE_URL=http://localhost:3000
GOOGLE_MAPS_API_KEY=your_dev_key
```

---

## Security Checklist

After domain setup, verify:

- [ ] **HTTPS is enforced** (no HTTP access)
- [ ] **SSL certificate is valid** and auto-renewing
- [ ] **API keys are restricted** to production domains
- [ ] **Supabase redirect URLs** only include your domains
- [ ] **Firebase Auth domains** are configured correctly
- [ ] **CORS is properly configured** for your domain
- [ ] **No hardcoded URLs** in code (use environment variables)
- [ ] **DNS records are correct** and propagated
- [ ] **Domain ownership verified** in Firebase
- [ ] **Backup domains** (web.app, firebaseapp.com) still work

---

## Maintenance

### Regular Tasks

1. **Monitor SSL certificate** renewal (automatic with Firebase)
2. **Review API key restrictions** quarterly
3. **Check domain expiration** annually
4. **Update redirect URLs** when adding new features
5. **Monitor DNS propagation** after changes

### Updates

When making changes:
1. **Test in staging** first
2. **Update DNS records** during low-traffic periods
3. **Monitor for 24-48 hours** after changes
4. **Keep backup domains** active

---

## Quick Reference

### Firebase Hosting Commands

```bash
# Deploy to custom domain
firebase deploy --only hosting

# List hosting sites
firebase hosting:sites:list

# View domain status
firebase hosting:sites:get yourdomain.com
```

### DNS Check Commands

```bash
# Check DNS resolution
nslookup yourdomain.com
dig yourdomain.com

# Check SSL certificate
openssl s_client -connect yourdomain.com:443
```

### Verification URLs

- **DNS Checker**: https://dnschecker.org/
- **SSL Checker**: https://www.ssllabs.com/ssltest/
- **Firebase Console**: https://console.firebase.google.com/
- **Supabase Dashboard**: https://supabase.com/dashboard

---

## Support

If you encounter issues:

1. **Check Firebase Console** for error messages
2. **Review DNS records** with your registrar
3. **Test with DNS checker** tools
4. **Contact Firebase support** for hosting issues
5. **Contact Supabase support** for auth issues
6. **Check Google Cloud Console** for API key issues

---

**Last Updated**: 2024
**Version**: 1.0.0

