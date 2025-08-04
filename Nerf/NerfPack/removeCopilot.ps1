# Run as Administrator
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "CopilotRemover"
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

# === Disable Windows Copilot via Registry ===
Write-Host "`n=== Disabling Windows Copilot via Registry ===" -ForegroundColor Cyan
$copilotMachineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"

try {
    if (-not (Test-Path $copilotMachineKey)) {
        New-Item -Path $copilotMachineKey -Force | Out-Null
        Write-Host "Created registry path: $copilotMachineKey" -ForegroundColor Yellow
        Log-Info "Created registry path: $copilotMachineKey"
    }

    Set-ItemProperty -Path $copilotMachineKey -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $copilotMachineKey -Name "SetCopilotHardwareKey" -Value 1 -Type DWord -Force

    Write-Host "✓ Copilot has been disabled for all users." -ForegroundColor Green
    Log-Info "Registry keys set to disable Windows Copilot."
} catch {
    Write-Host "✗ Failed to modify registry for Copilot." -ForegroundColor Red
    Log-Error "Failed to set machine-wide registry keys: $($_.Exception.Message)"
}

# === Uninstall Microsoft Copilot App ===
Write-Host "`n=== Uninstalling Microsoft Copilot App ===" -ForegroundColor Cyan
try {
    Get-AppxPackage -AllUsers -Name "Microsoft.Copilot" | Remove-AppxPackage -AllUsers
    Write-Host "✓ Microsoft Copilot App uninstalled." -ForegroundColor Green
    Log-Info "Uninstalled Microsoft Copilot App for all users."
} catch {
    Write-Host "✗ Failed to uninstall Microsoft Copilot App." -ForegroundColor Red
    Log-Error "Failed to uninstall Microsoft Copilot App for all users: $($_.Exception.Message)"
}

# === Uninstall Microsoft 365 Copilot (Office Hub) ===
Write-Host "`n=== Uninstalling Microsoft 365 Copilot (Office Hub) ===" -ForegroundColor Cyan
try {
    $officeHub = Get-AppxPackage -AllUsers -Name "Microsoft.MicrosoftOfficeHub*" | Select-Object -ExpandProperty PackageFullName
    if ($officeHub) {
        Write-Host "Uninstalling Microsoft 365 Copilot (Office Hub): $officeHub" -ForegroundColor White
        Remove-AppxPackage -Package $officeHub -AllUsers
        Write-Host "✓ Microsoft 365 Copilot (Office Hub) uninstalled." -ForegroundColor Green
        Log-Info "Uninstalled Microsoft 365 Copilot (Office Hub): $officeHub"
    } else {
        Write-Host "⚠ Microsoft 365 Copilot (Office Hub) not found." -ForegroundColor Yellow
        Log-Info "Microsoft 365 Copilot (Office Hub) not found."
    }
} catch {
    Write-Host "✗ Failed to uninstall Microsoft 365 Copilot (Office Hub)." -ForegroundColor Red
    Log-Error "Failed to uninstall Microsoft 365 Copilot (Office Hub): $($_.Exception.Message)"
}

# === Remove Provisioned Copilot Packages ===
Write-Host "`n=== Removing Provisioned Copilot Packages ===" -ForegroundColor Cyan
try {
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Copilot*" | ForEach-Object {
        Write-Host "Removing provisioned package: $($_.DisplayName)" -ForegroundColor White
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName
        Write-Host "✓ Removed provisioned package: $($_.DisplayName)" -ForegroundColor Green
        Log-Info "Removed provisioned package: $($_.DisplayName)"
    }
} catch {
    Write-Host "✗ Failed to remove provisioned Copilot packages." -ForegroundColor Red
    Log-Error "Failed to remove provisioned Copilot packages: $($_.Exception.Message)"
}

# Log script end
Log-Info "Script execution completed."
