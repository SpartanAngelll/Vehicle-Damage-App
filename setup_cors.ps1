# PowerShell script to configure CORS for Firebase Storage
Write-Host "🔧 Setting up CORS for Firebase Storage..." -ForegroundColor Cyan

# Check if gsutil is installed
$gsutilCheck = Get-Command gsutil -ErrorAction SilentlyContinue
if (-not $gsutilCheck) {
    Write-Host "❌ gsutil is not installed" -ForegroundColor Red
    Write-Host "📦 Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    Write-Host "   Then run: gcloud auth login" -ForegroundColor Yellow
    exit 1
}

# Get project ID from .firebaserc
Write-Host "📋 Reading project configuration..." -ForegroundColor Cyan
if (-not (Test-Path ".firebaserc")) {
    Write-Host "❌ .firebaserc not found!" -ForegroundColor Red
    exit 1
}

$jsonContent = Get-Content .firebaserc -Raw
$config = $jsonContent | ConvertFrom-Json
$projectId = $config.projects.default

if (-not $projectId) {
    Write-Host "❌ Could not find project ID" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Project ID: $projectId" -ForegroundColor Green

# Ensure cors.json exists
if (-not (Test-Path "cors.json")) {
    Write-Host "📝 Creating cors.json..." -ForegroundColor Yellow
    $corsContent = '[{"origin":["*"],"method":["GET","HEAD","OPTIONS"],"responseHeader":["Content-Type","Access-Control-Allow-Origin","Access-Control-Allow-Methods","Access-Control-Allow-Headers"],"maxAgeSeconds":3600}]'
    $corsContent | Out-File -FilePath "cors.json" -Encoding UTF8 -NoNewline
    Write-Host "✅ Created cors.json" -ForegroundColor Green
}

# Apply CORS
Write-Host ""
Write-Host "🚀 Applying CORS to: gs://$projectId.appspot.com" -ForegroundColor Cyan
$bucket = "gs://$projectId.appspot.com"

& gsutil cors set cors.json $bucket

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ CORS configured successfully!" -ForegroundColor Green
    Write-Host "📝 Verifying..." -ForegroundColor Cyan
    & gsutil cors get $bucket
    Write-Host ""
    Write-Host "🎉 Done! Images should now load on web." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Failed to apply CORS" -ForegroundColor Red
    Write-Host "💡 Run these commands:" -ForegroundColor Yellow
    Write-Host "   gcloud auth login" -ForegroundColor Yellow
    Write-Host "   gcloud config set project $projectId" -ForegroundColor Yellow
    exit 1
}
