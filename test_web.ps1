# PowerShell script to test Flutter app on Web with Supabase
# Usage: .\test_web.ps1

Write-Host "Setting up Web test environment..." -ForegroundColor Green

# Set Supabase environment variables
# IMPORTANT: Replace these with your actual Supabase credentials from .env file
$env:POSTGRES_HOST = $env:POSTGRES_HOST ?? "db.your-project-id.supabase.co"
$env:POSTGRES_PORT = $env:POSTGRES_PORT ?? "5432"
$env:POSTGRES_USER = $env:POSTGRES_USER ?? "postgres"
$env:POSTGRES_PASSWORD = $env:POSTGRES_PASSWORD ?? "your_supabase_password_here"
$env:POSTGRES_DB = $env:POSTGRES_DB ?? "postgres"
$env:POSTGRES_SSL = $env:POSTGRES_SSL ?? "true"

if ($env:POSTGRES_PASSWORD -eq "your_supabase_password_here") {
    Write-Host "⚠️  WARNING: Using placeholder password. Set POSTGRES_PASSWORD environment variable or update this script." -ForegroundColor Yellow
}

Write-Host "Environment variables set:" -ForegroundColor Green
Write-Host "   POSTGRES_HOST: $env:POSTGRES_HOST"
Write-Host "   POSTGRES_DB: $env:POSTGRES_DB"
Write-Host "   POSTGRES_SSL: $env:POSTGRES_SSL"
Write-Host ""

# Check if Chrome is available
Write-Host "Starting Flutter app on Web (Chrome)..." -ForegroundColor Cyan
Write-Host "Note: The app will open in your default browser" -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome

