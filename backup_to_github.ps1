# Safe Backup Script - Verifies no secrets before pushing to GitHub
# Run this script: .\backup_to_github.ps1

Write-Host "[*] Checking for secrets..." -ForegroundColor Yellow

# Check if .env exists and is ignored
if (Test-Path .env) {
    $ignored = git check-ignore .env
    if ($ignored) {
        Write-Host "[OK] .env file is properly ignored" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] .env file exists but is NOT ignored!" -ForegroundColor Red
        Write-Host "   Adding .env to .gitignore..." -ForegroundColor Yellow
        Add-Content .gitignore "`n.env"
    }
} else {
    Write-Host "[OK] No .env file found (this is OK)" -ForegroundColor Green
}

# Check for firebase_key files
$firebaseKeyFiles = Get-ChildItem -Path . -Filter "*firebase_key*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike "*node_modules*" }
if ($firebaseKeyFiles) {
    Write-Host "[WARNING] Found firebase_key files:" -ForegroundColor Red
    $firebaseKeyFiles | ForEach-Object { Write-Host "   $($_.FullName)" -ForegroundColor Red }
    Write-Host "   These should be in .gitignore!" -ForegroundColor Yellow
} else {
    Write-Host "[OK] No firebase_key files found" -ForegroundColor Green
}

Write-Host "`n[*] Staging files..." -ForegroundColor Yellow
git add .

Write-Host "`n[*] Verifying no secrets in staged files..." -ForegroundColor Yellow
$stagedFiles = git diff --cached --name-only
$sensitiveFiles = $stagedFiles | Where-Object { 
    $_ -like "*.env" -or 
    $_ -like "*firebase_key*" -or 
    $_ -like "*SECRETS_AUDIT_REPORT.md" -or
    $_ -like "*.key" -or
    $_ -like "*.pem"
}

if ($sensitiveFiles) {
    Write-Host "[ERROR] Sensitive files detected in staging area!" -ForegroundColor Red
    $sensitiveFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    Write-Host "`n   Unstaging sensitive files..." -ForegroundColor Yellow
    git reset HEAD $sensitiveFiles
    Write-Host "   Please add these to .gitignore and try again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "[OK] No sensitive files detected" -ForegroundColor Green
}

Write-Host "`n[*] Committing changes..." -ForegroundColor Yellow
$commitMessage = "Backup: Commit all changes - secrets verified safe"
git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Commit successful" -ForegroundColor Green
    
    Write-Host "`n[*] Pushing to GitHub..." -ForegroundColor Yellow
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[OK] Backup complete! All changes pushed to GitHub safely." -ForegroundColor Green
    } else {
        Write-Host "`n[ERROR] Push failed. Check your network connection and GitHub credentials." -ForegroundColor Red
    }
} else {
    Write-Host "`n[WARNING] No changes to commit (or commit failed)" -ForegroundColor Yellow
    Write-Host "   Current status:" -ForegroundColor Yellow
    git status --short
}

