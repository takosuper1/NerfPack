# Run as Administrator
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "CopilotRestorer"
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

# Re-enable Windows Copilot for all users
$copilotMachineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"

try {
    if (Test-Path $copilotMachineKey) {
        Remove-ItemProperty -Path $copilotMachineKey -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $copilotMachineKey -Name "SetCopilotHardwareKey" -ErrorAction SilentlyContinue
        Write-Host "Copilot has been re-enabled for all users." -ForegroundColor Green
    }
} catch {
    Log-Error "Failed to re-enable Copilot via registry: $($_.Exception.Message)"
}

# Reinstall Copilot App (Microsoft.Copilot)
try {
    Add-AppxPackage -Register "C:\Program Files\WindowsApps\Microsoft.Copilot_*\AppxManifest.xml" -DisableDevelopmentMode
} catch {
    Log-Error "Failed to reinstall Microsoft Copilot App: $($_.Exception.Message)"
}

# Reinstall Microsoft 365 Copilot (Office Hub)
try {
    Add-AppxPackage -Register "C:\Program Files\WindowsApps\Microsoft.MicrosoftOfficeHub_*\AppxManifest.xml" -DisableDevelopmentMode
} catch {
    Log-Error "Failed to reinstall Microsoft 365 Copilot (Office Hub): $($_.Exception.Message)"
}

# Restore provisioned packages (if needed)
# Note: This assumes you have the .appx or .appxbundle files available
# You can download them from Microsoft Store for Business or use DISM if available

# Example (if you have the package):
# DISM /Online /Add-ProvisionedAppxPackage /PackagePath:"C:\Path\To\Microsoft.Copilot.appxbundle" /SkipLicense

# Optional: Log that restoration script completed
Write-Host "Copilot restoration script completed." -ForegroundColor Cyan
