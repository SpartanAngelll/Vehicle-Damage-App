# Get Supabase Credentials Script
# This script helps retrieve Supabase credentials using the Supabase CLI

param(
    [string]$ProjectId = "rodzemxwopecqpazkjyk"
)

Write-Host "🔍 Retrieving Supabase Credentials..." -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "Checking Supabase CLI login status..." -ForegroundColor Yellow
$projects = supabase projects list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not logged in to Supabase CLI" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please login first:" -ForegroundColor Yellow
    Write-Host "   supabase login" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Then link your project:" -ForegroundColor Yellow
    Write-Host "   supabase link --project-ref $ProjectId" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Logged in to Supabase CLI" -ForegroundColor Green
Write-Host ""

# Try to get project info
Write-Host "Project Information:" -ForegroundColor Cyan
Write-Host "   Project ID: $ProjectId" -ForegroundColor White
Write-Host "   Project URL: https://$ProjectId.supabase.co" -ForegroundColor White
Write-Host ""

# Get API keys from Supabase Dashboard
Write-Host "📋 To get your API keys:" -ForegroundColor Cyan
Write-Host "   1. Go to: https://supabase.com/dashboard/project/$ProjectId/settings/api" -ForegroundColor Yellow
Write-Host "   2. Copy the following keys:" -ForegroundColor Yellow
Write-Host "      - anon public (for client-side)" -ForegroundColor White
Write-Host "      - service_role (for server-side, keep secret!)" -ForegroundColor White
Write-Host ""

# Try to get project status
Write-Host "Checking project status..." -ForegroundColor Yellow
$status = supabase projects api-keys --project-ref $ProjectId 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project API keys retrieved:" -ForegroundColor Green
    Write-Host $status
} else {
    Write-Host "⚠️  Could not retrieve API keys via CLI" -ForegroundColor Yellow
    Write-Host "   Please get them from the Supabase Dashboard (link above)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Tip: You can also use the complete_setup.ps1 script to automatically" -ForegroundColor Cyan
Write-Host "   configure your Flutter app with these credentials." -ForegroundColor Cyan
Write-Host ""

