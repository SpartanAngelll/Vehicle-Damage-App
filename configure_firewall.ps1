# PowerShell script to configure Windows Firewall for PostgreSQL
# Run this as Administrator

Write-Host "Configuring Windows Firewall for PostgreSQL..."

# Add inbound rule for PostgreSQL
try {
    New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -Protocol TCP -LocalPort 5432 -Action Allow -Profile Any
    Write-Host "✅ Firewall rule added successfully"
} catch {
    Write-Host "⚠️ Firewall rule might already exist or need administrator privileges"
    Write-Host "Error: $($_.Exception.Message)"
}

# Check if rule exists
$rule = Get-NetFirewallRule -DisplayName "PostgreSQL" -ErrorAction SilentlyContinue
if ($rule) {
    Write-Host "✅ PostgreSQL firewall rule is active"
} else {
    Write-Host "❌ PostgreSQL firewall rule not found"
    Write-Host "💡 You may need to run this script as Administrator"
}

Write-Host "Firewall configuration complete!"
