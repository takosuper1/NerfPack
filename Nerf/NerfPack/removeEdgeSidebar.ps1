# Run as Administrator if needed for app removal
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "EdgeSidebarRemover"
Write-Host "Running $appName..."

# Ensure log file exists
if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

# Logging functions
function Log-Error {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$appName] ERROR: $message"
    Add-Content -Path $logFile -Value $logEntry
}

function Log-Info {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$appName] INFO: $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Log script start
Log-Info "Script execution started."

# Try to disable Edge sidebar via registry
try {
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    # Create the registry key if it doesn't exist
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
        Write-Host "Created registry path: $registryPath" -ForegroundColor Yellow
        Log-Info "Created registry path: $registryPath"
    }

    # Disable the Hubs Sidebar
    New-ItemProperty -Path $registryPath -Name "HubsSidebarEnabled" -PropertyType DWord -Value 0 -Force
    Log-Info "Set 'HubsSidebarEnabled' to 0"

    # Disable the Standalone Sidebar
    New-ItemProperty -Path $registryPath -Name "StandaloneHubsSidebarEnabled" -PropertyType DWord -Value 0 -Force
    Log-Info "Set 'StandaloneHubsSidebarEnabled' to 0"

    Write-Host "✓ Edge sidebar has been disabled. Please restart Microsoft Edge for changes to take effect." -ForegroundColor Green
    Log-Info "Edge sidebar disabled successfully."
}
catch {
    Log-Error "Failed to modify registry: $($_.Exception.Message)"
    Write-Host "✗ An error occurred. Check the log file at $logFile for details." -ForegroundColor Red
}
