# PowerShell script to configure PostgreSQL for network access
# Run this as Administrator

$pgHbaPath = "C:\Program Files\PostgreSQL\17\data\pg_hba.conf"
$backupPath = "C:\Program Files\PostgreSQL\17\data\pg_hba.conf.backup"

# Create backup
Copy-Item $pgHbaPath $backupPath

# Read current content
$content = Get-Content $pgHbaPath

# Check if our entry already exists
$entryExists = $content | Select-String "192.168.0.0/24"

if (-not $entryExists) {
    Write-Host "Adding network access entry to pg_hba.conf..."
    
    # Add our entry
    $newEntry = "host    all             all             192.168.0.0/24            md5"
    $content += $newEntry
    
    # Write back to file
    $content | Set-Content $pgHbaPath
    
    Write-Host "Entry added successfully!"
    Write-Host "New entry: $newEntry"
} else {
    Write-Host "Entry already exists in pg_hba.conf"
}

# Reload PostgreSQL configuration
Write-Host "Reloading PostgreSQL configuration..."
$env:PGPASSWORD = "#!Startpos12"
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -c "SELECT pg_reload_conf();"

Write-Host "PostgreSQL configuration updated!"
Write-Host "You can now connect from your Android device using IP: 192.168.0.52"
