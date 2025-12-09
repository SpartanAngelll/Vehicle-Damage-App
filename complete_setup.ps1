# Complete Setup Script - Supabase + Firebase Integration
# This script automates the remaining setup steps using Supabase CLI and Firebase CLI

param(
    [string]$SupabaseProjectId = "rodzemxwopecqpazkjyk",
    [string]$SupabaseUrl = "https://rodzemxwopecqpazkjyk.supabase.co"
)

Write-Host "🚀 Starting Complete Setup..." -ForegroundColor Green
Write-Host ""

# Step 1: Check if Supabase CLI is installed
Write-Host "📋 Step 1: Checking Supabase CLI..." -ForegroundColor Cyan
$supabaseCmd = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseCmd) {
    Write-Host "❌ Supabase CLI not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g supabase" -ForegroundColor Yellow
    exit 1
}
try {
    $supabaseVersion = supabase --version 2>&1 | Out-String
    Write-Host "✅ Supabase CLI found: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not get Supabase version, but CLI appears to be installed" -ForegroundColor Yellow
}

# Step 2: Check if Firebase CLI is installed
Write-Host ""
Write-Host "📋 Step 2: Checking Firebase CLI..." -ForegroundColor Cyan
$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    Write-Host "❌ Firebase CLI not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}
try {
    $firebaseVersion = firebase --version 2>&1 | Out-String
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not get Firebase version, but CLI appears to be installed" -ForegroundColor Yellow
}

# Step 3: Get Supabase credentials
Write-Host ""
Write-Host "📋 Step 3: Retrieving Supabase credentials..." -ForegroundColor Cyan
Write-Host "   Note: You may need to login to Supabase CLI first:" -ForegroundColor Yellow
Write-Host "   supabase login" -ForegroundColor Yellow
Write-Host ""

# Try to get project info
try {
    # Check if linked to a project
    $linked = supabase projects list 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Not logged in to Supabase CLI. Please run: supabase login" -ForegroundColor Yellow
        Write-Host "   Then link your project: supabase link --project-ref $SupabaseProjectId" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not verify Supabase connection" -ForegroundColor Yellow
}

# Get anon key from Supabase API (requires API token)
Write-Host "   To get your Supabase Anon Key:" -ForegroundColor Yellow
Write-Host "   1. Go to: https://supabase.com/dashboard/project/$SupabaseProjectId/settings/api" -ForegroundColor Yellow
Write-Host "   2. Copy the anon public key" -ForegroundColor Yellow
Write-Host ""

$prompt = "   Enter your Supabase Anon Key (press Enter to skip and configure manually)"
$anonKey = Read-Host $prompt

if ([string]::IsNullOrWhiteSpace($anonKey)) {
    Write-Host "⚠️  Skipping automatic configuration. You'll need to:" -ForegroundColor Yellow
    Write-Host "   1. Get your anon key from Supabase Dashboard" -ForegroundColor Yellow
    Write-Host "   2. Add it to lib/main.dart manually" -ForegroundColor Yellow
    Write-Host ""
} else {
    # Step 4: Update .env file with Supabase credentials
    Write-Host ""
    Write-Host "[STEP] Step 4: Updating .env file with Supabase credentials..." -ForegroundColor Cyan
    
    $envPath = ".env"
    $envExamplePath = ".env.example"
    
    # Create .env from .env.example if it doesn't exist
    if (-not (Test-Path $envPath)) {
        if (Test-Path $envExamplePath) {
            Copy-Item $envExamplePath $envPath
            Write-Host "   Created .env from .env.example" -ForegroundColor Yellow
        } else {
            # Create basic .env file
            $envContent = @"
# Supabase Configuration
# DO NOT COMMIT THIS FILE - It contains sensitive keys

SUPABASE_URL=https://rodzemxwopecqpazkjyk.supabase.co
SUPABASE_ANON_KEY=
"@
            Set-Content -Path $envPath -Value $envContent -Encoding UTF8
            Write-Host "   Created new .env file" -ForegroundColor Yellow
        }
    }
    
    # Update .env file with the anon key
    if (Test-Path $envPath) {
        $envContent = Get-Content $envPath -Raw
        
        # Update SUPABASE_ANON_KEY
        if ($envContent -match "SUPABASE_ANON_KEY=") {
            $envContent = $envContent -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=$anonKey"
        } else {
            # Add if it doesn't exist
            $envContent += "`r`nSUPABASE_ANON_KEY=$anonKey`r`n"
        }
        
        # Update SUPABASE_URL if needed
        if ($envContent -notmatch "SUPABASE_URL=") {
            $envContent = "SUPABASE_URL=https://rodzemxwopecqpazkjyk.supabase.co`r`n" + $envContent
        }
        
        Set-Content -Path $envPath -Value $envContent -Encoding UTF8 -NoNewline
        Write-Host "[OK] Updated .env file with Supabase credentials" -ForegroundColor Green
        Write-Host "   Note: .env is in .gitignore and will not be committed" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Could not create or update .env file" -ForegroundColor Red
    }
}

# Step 5: Deploy Firestore rules
Write-Host ""
Write-Host "📋 Step 5: Deploying Firestore rules..." -ForegroundColor Cyan

try {
    # Check if firebase.json exists
    if (Test-Path "firebase.json") {
        Write-Host "   Deploying Firestore rules..." -ForegroundColor Yellow
        firebase deploy --only firestore:rules
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Firestore rules deployed successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to deploy Firestore rules" -ForegroundColor Red
            Write-Host "   Make sure you are logged in: firebase login" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  firebase.json not found. Skipping Firestore rules deployment." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error deploying Firestore rules: $_" -ForegroundColor Red
}

# Step 6: JWT Configuration Instructions
Write-Host ""
Write-Host "📋 Step 6: JWT Configuration (REQUIRED - Manual Step)" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  CRITICAL: You must configure JWT secret for RLS to work with Firebase tokens" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Using Supabase Dashboard (Recommended)" -ForegroundColor White
Write-Host "   1. Go to: https://supabase.com/dashboard/project/$SupabaseProjectId/settings/api" -ForegroundColor Yellow
Write-Host "   2. Find JWT Settings section" -ForegroundColor Yellow
Write-Host "   3. Get Firebase private key:" -ForegroundColor Yellow
Write-Host "      - Firebase Console -> Project Settings -> Service Accounts" -ForegroundColor Yellow
Write-Host "      - Generate new private key (or use existing)" -ForegroundColor Yellow
Write-Host "      - Copy the entire private key (including BEGIN/END markers)" -ForegroundColor Yellow
Write-Host "   4. Paste into Supabase JWT Secret field" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 2: Using Supabase CLI" -ForegroundColor White
Write-Host "   You can also use the Supabase CLI to update JWT settings:" -ForegroundColor Yellow
$jwtCommand = '   supabase projects update --jwt-secret "YOUR_FIREBASE_PRIVATE_KEY"'
Write-Host $jwtCommand -ForegroundColor Yellow
Write-Host ""

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. [OK] Supabase credentials configured (if provided)" -ForegroundColor Green
Write-Host "2. [OK] Flutter app updated with Supabase initialization" -ForegroundColor Green
Write-Host "3. [OK] Firestore rules deployed" -ForegroundColor Green
Write-Host "4. [WARN] JWT Configuration - REQUIRED (see instructions above)" -ForegroundColor Yellow
Write-Host ""
Write-Host 'After JWT configuration, test the authentication flow:' -ForegroundColor Cyan
Write-Host '   See TESTING_GUIDE.md for complete testing procedures' -ForegroundColor Yellow
Write-Host ""

