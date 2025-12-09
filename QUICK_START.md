# Quick Start - Firebase + Supabase Setup

## 1. Supabase Setup (5 minutes)

### Option A: Using Supabase CLI (Recommended)

1. **Install Supabase CLI (choose one method):**

   **Method 1: Local install (Recommended)**
   ```bash
   npm install supabase --save-dev
   ```

   **Method 2: Scoop (Windows)**
   ```powershell
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

2. **Login and link project:**
   
   **If using local install:**
   ```bash
   npx supabase login
   npx supabase link --project-ref YOUR_PROJECT_REF
   ```
   
   **If using global install:**
   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Push migrations:**
   
   **If using local install:**
   ```bash
   npx supabase db push
   ```
   
   **If using global install:**
   ```bash
   supabase db push
   ```

   **OR use automated script:**
   - Windows: `.\supabase\setup.ps1`
   - macOS/Linux: `./supabase/setup.sh`

### Option B: Manual SQL (Alternative)

1. **Get Supabase credentials:**
   - Go to Supabase Dashboard → Settings → API
   - Copy `Project URL` and `anon public` key

2. **Run database migrations in Supabase SQL Editor:**
   - All migrations are in `supabase/migrations/` folder
   - Run them in order (they're numbered)

3. **Configure JWT (CRITICAL):**
   - Supabase Dashboard → Settings → API → JWT Settings
   - Set JWT Secret to Firebase project secret
   - OR use custom JWT verifier (see `database/supabase_jwt_config.sql`)

## 2. Firebase Setup (2 minutes)

1. **Deploy Firestore rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Verify Firebase project configured:**
   - Check `lib/firebase_options.dart` exists
   - Verify Firebase project ID matches

## 3. Flutter App Setup (3 minutes)

1. **Add Supabase credentials to `lib/main.dart`:**
   ```dart
   await FirebaseSupabaseService.instance.initialize(
     supabaseUrl: 'YOUR_SUPABASE_URL',
     supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run app:**
   ```bash
   flutter run
   ```

## 4. Test Authentication (2 minutes)

1. Sign up new user
2. Check Supabase `users` table for new record
3. Verify `firebase_uid` matches Firebase UID

## Total Time: ~12 minutes

See `TESTING_GUIDE.md` for comprehensive testing.

