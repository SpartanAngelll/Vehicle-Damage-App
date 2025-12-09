# Script to create .env file for Supabase password
# Run this: .\create_env_file.ps1

$envContent = @"
# Supabase Database Configuration
# Paste your Supabase database password below

POSTGRES_PASSWORD=PASTE_YOUR_SUPABASE_PASSWORD_HERE

# Supabase Connection Details
POSTGRES_HOST=db.rodzemxwopecqpazkjyk.supabase.co
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_DB=postgres
POSTGRES_SSL=true

# Supabase API Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# API Keys (add as needed)
# GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
# OPENAI_API_KEY=your_openai_api_key_here
"@

# Write to .env file as UTF-8 without BOM (to avoid encoding issues)
[System.IO.File]::WriteAllText("$PWD\.env", $envContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "✅ .env file created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "File Location:" -ForegroundColor Cyan
Write-Host "  $PWD\.env" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open the .env file:" -ForegroundColor White
Write-Host "     notepad .env" -ForegroundColor Cyan
Write-Host "  2. Replace 'PASTE_YOUR_SUPABASE_PASSWORD_HERE' with your actual Supabase password" -ForegroundColor White
Write-Host "  3. Save the file" -ForegroundColor White
Write-Host ""
Write-Host "To get your password:" -ForegroundColor Cyan
Write-Host "  https://supabase.com/dashboard/project/rodzemxwopecqpazkjyk/settings/database" -ForegroundColor White

