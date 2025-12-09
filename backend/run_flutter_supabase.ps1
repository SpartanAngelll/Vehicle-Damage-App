# PowerShell script to run Flutter app with Supabase environment variables
# IMPORTANT: Replace these with your actual Supabase credentials from .env file
$env:POSTGRES_HOST = if ($env:POSTGRES_HOST) { $env:POSTGRES_HOST } else { "db.your-project-id.supabase.co" }
$env:POSTGRES_PORT = if ($env:POSTGRES_PORT) { $env:POSTGRES_PORT } else { "5432" }
$env:POSTGRES_USER = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$env:POSTGRES_PASSWORD = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "your_supabase_password_here" }
$env:POSTGRES_DB = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "postgres" }
$env:POSTGRES_SSL = if ($env:POSTGRES_SSL) { $env:POSTGRES_SSL } else { "true" }

if ($env:POSTGRES_PASSWORD -eq "your_supabase_password_here") {
    Write-Host "⚠️  WARNING: Using placeholder password. Set POSTGRES_PASSWORD environment variable or update this script." -ForegroundColor Yellow
}
Write-Host "âœ… Environment variables set" -ForegroundColor Green
Write-Host "ðŸ“± Starting Flutter app..." -ForegroundColor Cyan
flutter run
