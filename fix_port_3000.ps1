# Script to fix port 3000 conflict
# This will find and optionally kill the process using port 3000

Write-Host "Checking port 3000..." -ForegroundColor Cyan

$connections = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

if ($connections) {
    $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
    
    Write-Host "Found process(es) using port 3000:" -ForegroundColor Yellow
    foreach ($processId in $pids) {
        $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  - $($proc.ProcessName) (PID: $processId)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "1. Kill the process(es) and start fresh"
    Write-Host "2. Use the existing server (if it's your backend)"
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1 or 2)"
    
    if ($choice -eq "1") {
        Write-Host "Stopping process(es)..." -ForegroundColor Yellow
        foreach ($processId in $pids) {
            try {
                Stop-Process -Id $processId -Force
                Write-Host "  Stopped PID: $processId" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to stop PID: $processId" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Host "Port 3000 is now free. You can start the backend with:" -ForegroundColor Green
        Write-Host "  cd backend" -ForegroundColor White
        Write-Host "  node server.js" -ForegroundColor White
    } else {
        Write-Host "Keeping existing process. Test if it's working:" -ForegroundColor Green
        Write-Host "  curl http://localhost:3000/api/health" -ForegroundColor White
    }
} else {
    Write-Host "Port 3000 is free. You can start the backend normally." -ForegroundColor Green
}

