# Run as Administrator if needed for full app removal
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "MSStoreRemover"
Write-Host "Running $appName..."

# Ensure log file exists
if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

# Logging functions
function Log-Error {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$appName] ERROR: $message"
    Add-Content -Path $logFile -Value $logEntry
}

function Log-Info {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$appName] INFO: $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Log script start
Log-Info "Script execution started."

Write-Host "Starting Microsoft Store removal for all users..." -ForegroundColor Yellow

# Define package names to remove
$storePackages = @(
    "Microsoft.Services.Store.Engagement",
    "Microsoft.StorePurchaseApp", 
    "Microsoft.WindowsStore"
)

# Remove installed packages for all users
Write-Host "`n=== Removing Installed Packages for All Users ===" -ForegroundColor Cyan
foreach ($packageName in $storePackages) {
    try {
        $packages = Get-AppxPackage -AllUsers -Name $packageName
        foreach ($package in $packages) {
            Write-Host "Removing: $($package.Name) - $($package.Version)" -ForegroundColor White
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "✓ Successfully removed: $($package.Name)" -ForegroundColor Green
            Log-Info "Successfully removed package: $($package.Name)"
        }
    } catch {
        Log-Error "Failed to remove installed package '$packageName': $($_.Exception.Message)"
        Write-Host "✗ Error removing $packageName" -ForegroundColor Red
    }
}

# Add machine-wide registry entries to prevent reinstallation
Write-Host "`n=== Adding Registry Entries to Prevent Reinstallation (All Users) ===" -ForegroundColor Cyan
$machineRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"

try {
    if (-not (Test-Path $machineRegPath)) {
        New-Item -Path $machineRegPath -Force | Out-Null
        Write-Host "Created registry path: $machineRegPath" -ForegroundColor Yellow
        Log-Info "Created registry path: $machineRegPath"
    }

    Set-ItemProperty -Path $machineRegPath -Name "RemoveWindowsStore" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $machineRegPath -Name "DisableStoreApps" -Value 1 -Type DWord -Force

    Write-Host "✓ Registry entries added to prevent Store reinstallation (All Users)" -ForegroundColor Green
    Log-Info "Registry entries added to prevent Store reinstallation"
} catch {
    Log-Error "Failed to add registry entries: $($_.Exception.Message)"
}

# Verify removal
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
try {
    $remainingPackages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*Store*" }
    if ($remainingPackages.Count -eq 0) {
        Write-Host "✓ No Store packages found - removal successful!" -ForegroundColor Green
        Log-Info "Verification passed: No Store packages found"
    } else {
        Write-Host "⚠ Some Store packages may still remain:" -ForegroundColor Yellow
        $remainingPackages | Format-Table Name, Version -AutoSize
        Log-Info "Verification warning: Some Store packages still present"
    }
} catch {
    Log-Error "Failed during verification step: $($_.Exception.Message)"
}
