# Fix "Invalid API key" Error

## Problem
You're getting `{"message":"Invalid API key"}` errors when trying to use Supabase with Firebase Third Party Auth.

## Solution Steps

### Step 1: Verify Your API Key

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project: `rodzemxwopecqpazkjyk`

2. **Get Your API Keys**
   - Go to **Settings** → **API**
   - Find the **"Project API keys"** section
   - Copy the **"anon public"** key (NOT the service_role key)

3. **Check Your .env File**
   - Open `.env` in your project root
   - Find the line: `SUPABASE_ANON_KEY=...`
   - Make sure:
     - ✅ The key starts with `eyJ` (JWT format)
     - ✅ No spaces before or after the `=`
     - ✅ No quotes around the key
     - ✅ The entire key is on one line

### Step 2: Common Issues

#### Issue: API Key Has Spaces
```env
# ❌ WRONG
SUPABASE_ANON_KEY= eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ✅ CORRECT
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Issue: API Key Has Quotes
```env
# ❌ WRONG
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# ✅ CORRECT
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Issue: API Key is Expired or Regenerated
- If you regenerated your API keys in Supabase, the old key won't work
- Get a fresh key from the Dashboard and update `.env`

### Step 3: Verify Third Party Auth Setup

For Firebase Third Party Auth to work, you need:

1. **Link Firebase in Supabase Dashboard**
   - Go to **Authentication** → **Providers**
   - Find **"Third Party Auth"** or **"Custom JWT"**
   - Link your Firebase project
   - See `FIREBASE_THIRD_PARTY_AUTH_SETUP.md` for details

2. **Configure JWT Secret**
   - Go to **Settings** → **API** → **JWT Settings**
   - Set JWT Secret to your Firebase Service Account private key
   - See `JWT_CONFIGURATION_GUIDE.md` for details

### Step 4: Test the Fix

After updating your `.env` file:

1. **Restart your app completely** (not just hot reload)
2. **Run the RLS test again** from Settings screen
3. **Check the output** - you should see:
   - ✅ API Key is valid
   - ✅ Can query your own user profile
   - ✅ RLS policies working correctly

### Step 5: Quick Verification Script

Run this to verify your API key:

```dart
// You can run verify_supabase_key.dart to check your key
```

## Still Having Issues?

If you're still getting "Invalid API key" errors:

1. **Double-check the key** - Copy it fresh from Supabase Dashboard
2. **Check for hidden characters** - Make sure there are no invisible characters
3. **Verify project URL** - Make sure `SUPABASE_URL` matches your project
4. **Check Supabase project status** - Make sure your project is active
5. **Try regenerating the key** - In Supabase Dashboard, you can regenerate API keys

## Expected API Key Format

A valid Supabase anon key looks like:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXItcHJvamVjdC1pZCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzYzOTIwMzMwLCJleHAiOjIwNzk0OTYzMzB9.example_signature_here
```

- Starts with `eyJ`
- Has 3 parts separated by `.`
- Usually 200+ characters long
- No spaces or special formatting

