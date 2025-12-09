# Verify User in Supabase Database
# This script helps verify if a user was created in Supabase

param(
    [string]$BackendUrl = "http://localhost:3000",
    [string]$FirebaseUid = "",
    [string]$Email = ""
)

Write-Host "🔍 Verifying User in Supabase Database..." -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking backend server..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "$BackendUrl/api/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Backend server is running" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Backend server is not running or not accessible" -ForegroundColor Red
    Write-Host "   Please start the backend server first:" -ForegroundColor Yellow
    Write-Host "   cd backend && node server.js" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Or use Method 1 (Supabase SQL Editor) from VERIFY_USER_IN_SUPABASE.md" -ForegroundColor Yellow
    exit 1
}

# Get user statistics
Write-Host "📊 User Statistics:" -ForegroundColor Cyan
try {
    $stats = Invoke-RestMethod -Uri "$BackendUrl/api/users/stats" -Method Get
    Write-Host "   Total Users: $($stats.total_users)" -ForegroundColor White
    Write-Host "   Users by Role:" -ForegroundColor White
    foreach ($role in $stats.by_role) {
        Write-Host "     - $($role.role): $($role.count)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "⚠️  Could not get user statistics: $_" -ForegroundColor Yellow
    Write-Host ""
}

# Get all users (last 10)
Write-Host "👥 Recent Users (last 10):" -ForegroundColor Cyan
try {
    $users = Invoke-RestMethod -Uri "$BackendUrl/api/users" -Method Get
    if ($users.success -and $users.count -gt 0) {
        $recentUsers = $users.users | Select-Object -First 10
        foreach ($user in $recentUsers) {
            Write-Host "   - $($user.email) ($($user.role))" -ForegroundColor White
            Write-Host "     Firebase UID: $($user.firebase_uid)" -ForegroundColor Gray
            Write-Host "     Created: $($user.created_at)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "   No users found in database" -ForegroundColor Yellow
        Write-Host ""
    }
} catch {
    Write-Host "⚠️  Could not get users: $_" -ForegroundColor Yellow
    Write-Host ""
}

# Check specific user if Firebase UID provided
if ($FirebaseUid -ne "") {
    Write-Host "🔍 Checking specific user (Firebase UID: $FirebaseUid)..." -ForegroundColor Cyan
    try {
        $user = Invoke-RestMethod -Uri "$BackendUrl/api/users/firebase/$FirebaseUid" -Method Get
        if ($user.success) {
            Write-Host "✅ User found in Supabase!" -ForegroundColor Green
            Write-Host "   Email: $($user.user.email)" -ForegroundColor White
            Write-Host "   Role: $($user.user.role)" -ForegroundColor White
            Write-Host "   Full Name: $($user.user.full_name)" -ForegroundColor White
            Write-Host "   Created: $($user.user.created_at)" -ForegroundColor White
            Write-Host "   Active: $($user.user.is_active)" -ForegroundColor White
        }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "❌ User NOT found in Supabase database" -ForegroundColor Red
            Write-Host "   The user may not have been synced yet." -ForegroundColor Yellow
            Write-Host "   Try signing in again to trigger sync." -ForegroundColor Yellow
        } else {
            Write-Host "⚠️  Error checking user: $_" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Instructions
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "   - To check a specific user, use: -FirebaseUid 'YOUR_UID'" -ForegroundColor White
Write-Host "   - To see all users, check the output above" -ForegroundColor White
Write-Host "   - For more options, see VERIFY_USER_IN_SUPABASE.md" -ForegroundColor White
Write-Host ""

