# Define log file path
# Use current directory if PSScriptRoot is empty (when running interactively)
if ($PSScriptRoot) {
    $logFile = "$PSScriptRoot\NerfLogs.txt"
} else {
    $logFile = "$(Get-Location)\NerfLogs.txt"
}

# Debug: Show what path we're trying to use
Write-Host "Script Root: $PSScriptRoot" -ForegroundColor Cyan
Write-Host "Log File Path: $logFile" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "Running as Administrator: $isAdmin" -ForegroundColor Cyan

# Create the log file if it doesn't exist
if (-not (Test-Path $logFile)) {
    Write-Host "Log file does not exist. Creating..." -ForegroundColor Yellow
    try {
        # Create the directory if it doesn't exist
        $logDir = Split-Path $logFile -Parent
        Write-Host "Log directory: $logDir" -ForegroundColor Cyan
        
        if (-not (Test-Path $logDir)) {
            Write-Host "Creating directory: $logDir" -ForegroundColor Yellow
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        } else {
            Write-Host "Directory already exists: $logDir" -ForegroundColor Green
        }
        
        # Create the log file
        Write-Host "Creating log file: $logFile" -ForegroundColor Yellow
        New-Item -Path $logFile -ItemType File -Force | Out-Null
        
        # Verify file was created
        if (Test-Path $logFile) {
            Write-Host "Log file created successfully!" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Log file was not created!" -ForegroundColor Red
        }

        # Set permissions: Full control to Administrators only (only if running as admin)
        if ($isAdmin) {
            Write-Host "Setting admin-only permissions..." -ForegroundColor Yellow
            $acl = Get-Acl $logFile
            $adminGroup = New-Object System.Security.Principal.NTAccount("Administrators")
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $adminGroup, "FullControl", "Allow"
            )

            $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance
            $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }  # Remove all existing rules
            $acl.AddAccessRule($accessRule)  # Add admin-only rule
            Set-Acl -Path $logFile -AclObject $acl
            Write-Host "Permissions set to admin-only." -ForegroundColor Green
        } else {
            Write-Host "Warning: Not running as Administrator. Log file created with default permissions." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error creating log file: $_" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Continuing without log file..." -ForegroundColor Yellow
        $logFile = $null  # Disable logging
    }
} else {
    Write-Host "Log file already exists: $logFile" -ForegroundColor Green
}

function Log-Result {
    param (
        [string]$Message,
        [string]$Status
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message [$Status]"
    
    # Display to console
    if ($Status -eq "active") {
        Write-Host "$Message [active]" -ForegroundColor Red
    } elseif ($Status -eq "disabled") {
        Write-Host "$Message [disabled]" -ForegroundColor Green
    } else {
        Write-Host "$Message [$Status]" -ForegroundColor Yellow
    }
    
    # Try to write to log file (only if logFile is not null)
    if ($logFile) {
        try {
            Add-Content -Path $logFile -Value $logEntry -Force -ErrorAction Stop
        } catch {
            # Only show this error once per session
            if (-not $script:logWarningShown) {
                Write-Host "Note: Cannot write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
                $script:logWarningShown = $true
            }
        }
    }
}

function Execute-ExternalScript {
    param (
        [string]$ScriptName,
        [string]$Description
    )
    
    $scriptPath = "$PSScriptRoot\$ScriptName"
    
    try {
        if (Test-Path $scriptPath) {
            Write-Host "Executing $Description..." -ForegroundColor Yellow
            & $scriptPath
            Log-Result "$Description executed successfully" "success"
        } else {
            Log-Result "$Description script not found at $scriptPath" "warning"
        }
    } catch {
        Log-Result "Error executing $Description : $($_.Exception.Message)" "error"
    }
}

function Check-StandardAccounts {
    try {
        # Get all enabled local users
        $localUsers = Get-LocalUser | Where-Object { $_.Enabled }

        # Check if running as Administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Write-Host "Running as Administrator: $isAdmin" -ForegroundColor Cyan

        if ($isAdmin){
            try {
                # Get the current user's account name properly
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $userName = $currentUser.Split('\')[-1]  # Get just the username part
                
                Write-Host "Attempting to remove user: $userName" -ForegroundColor Yellow
                Write-Host "Full identity: $currentUser" -ForegroundColor Cyan
                
                # Try with just the username first
                Remove-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction Stop
                Log-Result "Successfully removed current user ($userName) from Administrators group" "success"
            } catch {
                # If that fails, try with the full domain\username format
                try {
                    Write-Host "Retrying with full identity: $currentUser" -ForegroundColor Yellow
                    Remove-LocalGroupMember -Group "Administrators" -Member $currentUser -ErrorAction Stop
                    Log-Result "Successfully removed current user ($currentUser) from Administrators group" "success"
                } catch {
                    Log-Result "Failed to remove admin privileges for user $userName (tried both $userName and $currentUser): $($_.Exception.Message)" "error"
                }
            }
        }

        # Re-check admin status after removal attempt
        $isAdminAfter = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdminAfter) {
            Log-Result "WARNING: Current user still has admin privileges!" "warning"
        } else {
            Log-Result "Current user has a Standard Account" "success"
        }

        # Get all members of the Administrators group (local + domain)
        $adminGroupMembers = Get-LocalGroupMember -Group "Administrators"

        $adminUserNames = @()
        $standardUserNames = @()

        # Add local users to admin or standard lists
        foreach ($user in $localUsers) {
            $isAdmin = $adminGroupMembers | Where-Object { $_.Name -eq $user.Name -and $_.ObjectClass -eq "User" }
            if ($isAdmin) {
                $adminUserNames += $user.Name
            } else {
                $standardUserNames += $user.Name
            }
        }

        # Include domain users from Administrators group
        $domainAdmins = $adminGroupMembers | Where-Object { $_.ObjectClass -eq "User" -and $_.Name -notin $adminUserNames }
        foreach ($admin in $domainAdmins) {
            $adminUserNames += $admin.Name
        }

        # Get current user and ensure it's included
        $currentUserFull = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $currentUserShort = $currentUserFull.Split('\')[-1]

        if (-not ($adminUserNames -contains $currentUserShort) -and -not ($standardUserNames -contains $currentUserShort)) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                $adminUserNames += $currentUserShort
            } else {
                $standardUserNames += $currentUserShort
            }
        }

        Log-Result "Enabled Admin Accounts (Local + Domain): $($adminUserNames -join ', ')" "info"
        Log-Result "Enabled Standard Accounts (Local): $($standardUserNames -join ', ')" "info"
    } catch {
        Log-Result "Error checking user accounts: $_" "error"
    }
}

function Check-CopilotInstalled {
    try {
        $copilot = Get-AppxPackage -Name "*Copilot*" -ErrorAction SilentlyContinue
        if ($copilot) {
            Log-Result "Copilot is installed" "active"
            Execute-ExternalScript "removeCopilot.ps1" "Copilot removal script"
        } else {
            Log-Result "Copilot is not installed" "disabled"
        }
    } catch {
        Log-Result "Error checking Copilot installation: $_" "error"
    }
}

function Check-MicrosoftStoreInstalled {
    try {
        $store = Get-AppxPackage -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue
        if ($store) {
            Log-Result "Microsoft Store is installed" "active"
            Execute-ExternalScript "removeWindowsStore.ps1" "Windows Store removal script"
        } else {
            Log-Result "Microsoft Store is not installed" "disabled"
        }
    } catch {
        Log-Result "Error checking Microsoft Store installation: $_" "error"
    }
}

function Check-EdgeSidebarActive {
    try {
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

        # Create the registry key if it doesn't exist
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "Created registry path: $registryPath" -ForegroundColor Yellow
            Log-Result "Created registry path: $registryPath"
        }

        # Ensure required values exist with defaults
        $defaultEdgeValues = @{
            HubsSidebarEnabled = 0
            StandaloneHubsSidebarEnabled = 0
        }

        foreach ($name in $defaultEdgeValues.Keys) {
            if (-not (Get-ItemProperty -Path $registryPath -Name $name -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $registryPath -Name $name -Value $defaultEdgeValues[$name] -PropertyType DWord -Force | Out-Null
                Log-Result "$name not found. Created with default value: $($defaultEdgeValues[$name])" "info"
            }
        }

        $hubsSidebar = Get-ItemProperty -Path $registryPath -Name "HubsSidebarEnabled" -ErrorAction SilentlyContinue
        $standaloneSidebar = Get-ItemProperty -Path $registryPath -Name "StandaloneHubsSidebarEnabled" -ErrorAction SilentlyContinue

        Write-Debug "HubsSidebarEnabled: $($hubsSidebar.HubsSidebarEnabled)"
        Write-Debug "StandaloneHubsSidebarEnabled: $($standaloneSidebar.StandaloneHubsSidebarEnabled)"

        if ($hubsSidebar.HubsSidebarEnabled -eq 1 -or $standaloneSidebar.StandaloneHubsSidebarEnabled -eq 1) {
            Log-Result "Edge sidebar is enabled" "active"
            Execute-ExternalScript "$PSScriptRoot\removeEdgeSidebar.ps1" "Edge sidebar removal script"
        } elseif ($hubsSidebar.HubsSidebarEnabled -eq 0 -and $standaloneSidebar.StandaloneHubsSidebarEnabled -eq 0) {
            Log-Result "Edge sidebar is disabled" "disabled"
        } else {
            Log-Result "Edge sidebar status is unknown or not configured" "unknown"
        }
    } catch {
        Log-Result "Error checking Edge sidebar status: $_" "error"
    }
}


function Check-StickyKeysDisabled {
   try {
        $flagsKey = 'HKCU\Control Panel\Accessibility\StickyKeys'
        $currentFlags = Get-ItemProperty -Path "Registry::$flagsKey" -Name Flags -ErrorAction Stop

        if ($currentFlags.Flags -eq 506) {
            Log-Result "Sticky Keys are disabled for current user" "disabled"
        } else {
            Log-Result "Sticky Keys are enabled for current user" "active"

            # Disable Sticky Keys by setting Flags to 506
            Set-ItemProperty -Path "Registry::$flagsKey" -Name Flags -Value 506
            Log-Result "Sticky Keys have been disabled for current user" "success"
        }
    } catch {
        Log-Result "Error checking or modifying Sticky Keys settings: $_" "error"
    }
}

function Check-USBExecutionStatus {
    try {
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"

        # Create the registry path if it doesn't exist
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "Created registry path: $registryPath" -ForegroundColor Yellow
            Log-Result "Created registry path: $registryPath"
        }

        # Ensure Deny_Execute value exists
        $denyExecute = Get-ItemProperty -Path $registryPath -Name "Deny_Execute" -ErrorAction SilentlyContinue
        if (-not $denyExecute) {
            New-ItemProperty -Path $registryPath -Name "Deny_Execute" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Result "Deny_Execute not found. Created with default value: 1" "info"
        }

        $denyExecute = Get-ItemProperty -Path $registryPath -Name "Deny_Execute" -ErrorAction Stop
        Write-Debug "Value of Deny_Execute: $($denyExecute.Deny_Execute)"

        if ($denyExecute.Deny_Execute -eq 1) {
            Log-Result "USB execution is disabled" "disabled"
        } elseif ($denyExecute.Deny_Execute -eq 0) {
            Log-Result "USB execution is enabled" "active"
            Execute-ExternalScript "$PSScriptRoot\removeUSBExecution.ps1" "USB execution removal script"
        } else {
            Log-Result "USB execution status is unknown or not configured" "unknown"
        }
    } catch {
        Log-Result "Error checking USB execution status: $_" "error"
    }
}



# Run checks
Log-Result "Running Nerf Check****************************************************************" "info"
Check-CopilotInstalled
Check-MicrosoftStoreInstalled
Check-EdgeSidebarActive
Check-StickyKeysDisabled
Check-USBExecutionStatus
# Run Check-StandardAccounts last as it removes admin privileges
Check-StandardAccounts
Log-Result "End of Nerf Check****************************************************************" "info"