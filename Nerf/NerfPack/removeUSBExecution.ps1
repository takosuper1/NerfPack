# Run as Administrator if needed for registry modification
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "USBExecutionRemover"
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

# Registry path and key
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"
$keyName = "Deny_Execute"

Write-Host "`n=== Modifying Registry to Deny USB Execution ===" -ForegroundColor Cyan

try {
    # Create the registry path if it doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "Created registry path: $regPath" -ForegroundColor Yellow
        Log-Info "Created registry path: $regPath"
    }

    # Set the Deny_Execute value
    Set-ItemProperty -Path $regPath -Name $keyName -Value 1 -Type DWord -Force
    Write-Host "✓ Registry key '$keyName' set to 1 at '$regPath'" -ForegroundColor Green
    Log-Info "Registry key '$keyName' set to 1 at '$regPath'"
}
catch {
    Write-Host "✗ Failed to set registry key." -ForegroundColor Red
    Log-Error "Failed to set registry key '$keyName' at '$regPath'. Error: $($_.Exception.Message)"
}

# Log script end
Log-Info "Script execution completed."
