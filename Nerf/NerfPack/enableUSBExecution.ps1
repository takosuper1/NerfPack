# Run as Administrator
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "USBExecutionRestorer"
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

# Registry path for USB execution control
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"

try {
    # Remove the Deny_Execute value if it exists
    if (Test-Path $regPath) {
        Remove-ItemProperty -Path $regPath -Name "Deny_Execute" -ErrorAction SilentlyContinue
        Write-Host "USB execution has been re-enabled." -ForegroundColor Green
    } else {
        Write-Host "USB execution policy not found. No changes made." -ForegroundColor Yellow
    }
} catch {
    Log-Error "Failed to re-enable USB execution: $($_.Exception.Message)"
}
