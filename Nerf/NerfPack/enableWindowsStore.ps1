# Run as Administrator
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "StoreRestorer"
Write-Host `Running $appName...`

# Ensure log file exists
if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

# Logging function
function Log-Error {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$appName] ERROR: $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Re-enable Microsoft Store via Group Policy (HKLM)
try {
    $storePolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
    if (Test-Path $storePolicyKey) {
        Remove-ItemProperty -Path $storePolicyKey -Name "RemoveWindowsStore" -ErrorAction SilentlyContinue
        Write-Host "Microsoft Store policy has been re-enabled." -ForegroundColor Green
    }
} catch {
    Log-Error "Failed to re-enable Microsoft Store via registry: $($_.Exception.Message)"
}

# Reinstall Microsoft Store for all users
try {
    Get-AppxPackage -AllUsers Microsoft.WindowsStore* | Foreach {
        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
    }
    Write-Host "Microsoft Store reinstalled successfully." -ForegroundColor Green
} catch {
    Log-Error "Failed to reinstall Microsoft Store: $($_.Exception.Message)"
}

# Reinstall Microsoft Store dependencies
$dependencies = @(
    "Microsoft.NET.Native.Framework.1.7",
    "Microsoft.NET.Native.Runtime.1.7",
    "Microsoft.VCLibs.140.00",
    "Microsoft.UI.Xaml.2.7"
)

foreach ($dep in $dependencies) {
    try {
        Get-AppxPackage -AllUsers -Name "*$dep*" | Foreach {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
        }
        Write-Host "Dependency $dep reinstalled." -ForegroundColor Cyan
    } catch {
        Log-Error "Failed to reinstall dependency $dep $($_.Exception.Message)"
    }
}

# Restart Microsoft Store Install Service
try {
    $service = Get-Service -Name "InstallService" -ErrorAction SilentlyContinue
    if ($service.Status -eq "Stopped") {
        Start-Service -Name "InstallService"
        Write-Host "InstallService restarted." -ForegroundColor Cyan
    }
} catch {
    Log-Error "Failed to restart InstallService: $($_.Exception.Message)"
}
