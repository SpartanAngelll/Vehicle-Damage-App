# Verify Database Tables via CLI
# This script checks if tables exist and verifies users

Write-Host "🔍 Verifying Database Tables..." -ForegroundColor Cyan
Write-Host ""

# Method 1: Check via Backend API (if backend is running)
Write-Host "Method 1: Checking via Backend API..." -ForegroundColor Yellow
try {
    $stats = Invoke-RestMethod -Uri "http://localhost:3000/api/users/stats" -Method Get -ErrorAction Stop
    Write-Host "✅ Backend API is working!" -ForegroundColor Green
    Write-Host "   Total users: $($stats.total_users)" -ForegroundColor White
    Write-Host "   Users by role:" -ForegroundColor White
    $stats.by_role | ForEach-Object {
        Write-Host "     - $($_.role): $($_.count)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Get all users
    $users = Invoke-RestMethod -Uri "http://localhost:3000/api/users" -Method Get
    if ($users.success -and $users.count -gt 0) {
        Write-Host "✅ Found $($users.count) users:" -ForegroundColor Green
        $users.users | Select-Object -First 5 | ForEach-Object {
            Write-Host "   - $($_.email) ($($_.role))" -ForegroundColor White
            Write-Host "     Created: $($_.created_at)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  No users found in database" -ForegroundColor Yellow
    }
    exit 0
} catch {
    Write-Host "❌ Backend API not available: $_" -ForegroundColor Red
    Write-Host ""
}

# Method 2: Use Supabase CLI to check migrations
Write-Host "Method 2: Checking via Supabase CLI..." -ForegroundColor Yellow
try {
    $migrations = npx supabase migration list 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Supabase CLI connection working" -ForegroundColor Green
        Write-Host ""
        Write-Host "Migration Status:" -ForegroundColor Cyan
        Write-Host $migrations
        Write-Host ""
        
        # Check if initial schema migration was applied
        if ($migrations -match "20240101000000.*20240101000000") {
            Write-Host "✅ Initial schema migration (20240101000000) has been applied" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Initial schema migration may not be applied" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Could not check migrations: $migrations" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Supabase CLI error: $_" -ForegroundColor Red
    Write-Host ""
}

# Method 3: Instructions
Write-Host "Method 3: Manual Verification" -ForegroundColor Yellow
Write-Host ""
Write-Host "If needed, verify in Supabase SQL Editor:" -ForegroundColor White
Write-Host "1. Go to Supabase Dashboard SQL Editor" -ForegroundColor Gray
Write-Host "2. Open verify_tables_exist.sql and run those queries" -ForegroundColor Gray
Write-Host ""
