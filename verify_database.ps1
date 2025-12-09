# Verify database tables via Backend API
Write-Host "🔍 Verifying database via Backend API..." -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -ErrorAction Stop
    Write-Host "✅ Backend is running" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Backend is not running or not accessible" -ForegroundColor Red
    Write-Host "   Please start the backend:" -ForegroundColor Yellow
    Write-Host "   cd backend" -ForegroundColor Gray
    Write-Host "   node server.js" -ForegroundColor Gray
    exit 1
}

# Check users table
Write-Host "Checking users table..." -ForegroundColor Yellow
try {
    $stats = Invoke-RestMethod -Uri "http://localhost:3000/api/users/stats" -ErrorAction Stop
    
    if ($stats.success) {
        Write-Host "✅ Users table EXISTS!" -ForegroundColor Green
        Write-Host "   Total users: $($stats.total_users)" -ForegroundColor Cyan
        Write-Host "   Users by role:" -ForegroundColor Cyan
        $stats.by_role | ForEach-Object {
            Write-Host "     - $($_.role): $($_.count)" -ForegroundColor White
        }
        Write-Host ""
        
        # Get recent users
        $users = Invoke-RestMethod -Uri "http://localhost:3000/api/users" -ErrorAction Stop
        
        if ($users.success -and $users.count -gt 0) {
            Write-Host "📝 Recent users:" -ForegroundColor Cyan
            $users.users | Select-Object -First 5 | ForEach-Object {
                Write-Host "   - Email: $($_.email)" -ForegroundColor White
                Write-Host "     Role: $($_.role)" -ForegroundColor Gray
                Write-Host "     Firebase UID: $($_.firebase_uid)" -ForegroundColor Gray
                Write-Host "     Created: $($_.created_at)" -ForegroundColor Gray
                Write-Host ""
            }
        } elseif ($users.success -and $users.count -eq 0) {
            Write-Host "📝 No users found in database yet" -ForegroundColor Yellow
            Write-Host "   This is normal if you just created the tables." -ForegroundColor Gray
            Write-Host "   Try creating a new user in the app to test." -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Error: $($stats.error)" -ForegroundColor Red
    }
} catch {
    $errorMsg = $_.Exception.Message
    if ($errorMsg -like "*relation*users*does not exist*") {
        Write-Host "❌ Users table DOES NOT EXIST" -ForegroundColor Red
        Write-Host "   Please run the schema in Supabase SQL Editor:" -ForegroundColor Yellow
        Write-Host "   1. Go to: https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/sql/new" -ForegroundColor Gray
        Write-Host "   2. Copy contents of: database/complete_schema_supabase.sql" -ForegroundColor Gray
        Write-Host "   3. Paste and run it" -ForegroundColor Gray
    } else {
        Write-Host "❌ Error: $errorMsg" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Verification complete!" -ForegroundColor Green

