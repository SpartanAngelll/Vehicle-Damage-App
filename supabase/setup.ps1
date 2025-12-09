# Supabase CLI Setup Script for Windows PowerShell

Write-Host "🚀 Setting up Supabase with CLI..." -ForegroundColor Cyan

# Check if Supabase CLI is installed
$supabaseInstalled = $false

# Check if installed globally (via Scoop or direct install)
try {
    $null = Get-Command supabase -ErrorAction Stop
    $supabaseInstalled = $true
    Write-Host "✅ Supabase CLI found (global)" -ForegroundColor Green
} catch {
    # Check if installed locally
    if (Test-Path "node_modules\.bin\supabase.cmd") {
        $supabaseInstalled = $true
        Write-Host "✅ Supabase CLI found (local)" -ForegroundColor Green
    } else {
        Write-Host "❌ Supabase CLI not found. Installing locally..." -ForegroundColor Yellow
        npm install supabase --save-dev
        $supabaseInstalled = $true
    }
}

# Determine command prefix
if (Test-Path "node_modules\.bin\supabase.cmd") {
    $supabaseCmd = "npx supabase"
} else {
    $supabaseCmd = "supabase"
}

# Link to existing project
Write-Host "📋 Linking to Supabase project..." -ForegroundColor Cyan
$projectRef = Read-Host "Enter your Supabase project reference ID (press Enter to skip)"

if ($projectRef -and $projectRef.Trim() -ne "") {
    try {
        Invoke-Expression "$supabaseCmd link --project-ref $projectRef" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Linked to project: $projectRef" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to link project. You may need to run manually." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Error linking project: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Skipping project link. Run '$supabaseCmd link' manually later." -ForegroundColor Yellow
}

# Check if project is linked before pushing migrations
$configPath = ".\.supabase\config.toml"
if (-not (Test-Path $configPath)) {
    Write-Host "⚠️  Project not linked. Skipping migration push." -ForegroundColor Yellow
    Write-Host "   Run: $supabaseCmd link --project-ref YOUR_PROJECT_REF" -ForegroundColor Yellow
    Write-Host "   Then: $supabaseCmd db push" -ForegroundColor Yellow
} else {
    # Push migrations
    Write-Host "📤 Pushing database migrations..." -ForegroundColor Cyan
    try {
        Invoke-Expression "$supabaseCmd db push"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Migrations pushed successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Migration push failed. Check errors above." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Error pushing migrations: $_" -ForegroundColor Yellow
    }
}

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure JWT secret in Supabase Dashboard → Settings → API"
Write-Host "2. Deploy Firestore rules: firebase deploy --only firestore:rules"
Write-Host "3. Initialize Supabase in your Flutter app (see QUICK_START.md)"

