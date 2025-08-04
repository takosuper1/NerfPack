# Run as Administrator
# Define log file and app name
$logFile = "C:\Program Files\NerfPack\AppLogs.txt"
$appName = "EdgeSidebarRestorer"


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

# Registry path for Edge policies
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

try {
    # Ensure the Edge policy path exists
    if (-not (Test-Path $edgePolicyPath)) {
        New-Item -Path $edgePolicyPath -Force | Out-Null
    }

    # Enable the Edge sidebar
    Set-ItemProperty -Path $edgePolicyPath -Name "HubsSidebarEnabled" -Value 1 -Type DWord

    # Enable the Copilot icon in the sidebar
    Set-ItemProperty -Path $edgePolicyPath -Name "Microsoft365CopilotChatIconEnabled" -Value 1 -Type DWord

    # Allow Copilot sidebar apps by ID
    $copilotAppIDs = @(
        "nkbndigcebkoaejohleckhekfmcecfja",  # Copilot
        "ofefcgjbeghpigppfmkologfjadafddi"   # Possibly related sidebar app
    )

    $extensionListPath = "$edgePolicyPath\ExtensionInstallAllowlist"
    if (-not (Test-Path $extensionListPath)) {
        New-Item -Path $extensionListPath -Force | Out-Null
    }

    $index = 1
    foreach ($id in $copilotAppIDs) {
        Set-ItemProperty -Path $extensionListPath -Name "$index" -Value $id
        $index++
    }

    Write-Host "Edge sidebar and Copilot have been re-enabled." -ForegroundColor Green
} catch {
    Log-Error "Failed to re-enable Edge sidebar or Copilot: $($_.Exception.Message)"
}
