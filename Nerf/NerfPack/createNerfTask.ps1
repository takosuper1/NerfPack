# PowerShell Script to Create a Scheduled Task that runs at Login
# This script creates a task that executes another PowerShell script when a user logs in

# Configuration Variables
$TaskName = "runNerfCheck"
$TaskDescription = "Runs NerfCheck PowerShell script at user login"
$ScriptPath = "C:\Program Files\NerfPack\runNerfCheck.ps1"
$TaskFolder = "\"  # Root folder, or specify like "\MyTasks\"
$Cred = Get-Credential  # Prompt for admin credentials
$AdminUsername = $Cred.UserName  # Change this to your actual admin username (e.g., "COMPUTERNAME\AdminUser" or "DOMAIN\AdminUser")
$Password = $Cred.GetNetworkCredential().Password

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator to create scheduled tasks."
    exit 1
}

# Verify the target script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Warning "Target script not found at: $ScriptPath"
    Write-Host "Please update the `$ScriptPath variable with the correct path to your script."
    exit 1
}

try {
    # Create the scheduled task action
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    # Create the trigger for user logon
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Create task settings (hidden and allow elevated execution)
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
    
    # Create the principal (run as specified admin user with highest privileges)
    $Principal = New-ScheduledTaskPrincipal -UserId $Cred.UserName -LogonType Password -RunLevel Highest
    
    # Create the scheduled task
    $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description $TaskDescription
    
    # Register the task
    Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -InputObject $Task -User $AdminUsername -Password $Password -Force
    
    Write-Host "SUCCESS: Scheduled task '$TaskName' has been created successfully!" -ForegroundColor Green
    Write-Host "The task will run '$ScriptPath' as '$AdminUsername' with administrator privileges when user '$env:USERNAME' logs in." -ForegroundColor Green
    Write-Host "Note: The task is hidden and will not appear in the Task Scheduler GUI by default." -ForegroundColor Yellow
    Write-Host "Important: You will be prompted for '$AdminUsername' password when registering the task." -ForegroundColor Cyan
    
    # Display task information
    Write-Host "`nTask Details:" -ForegroundColor Cyan
    Write-Host "- Task Name: $TaskName" -ForegroundColor White
    Write-Host "- Script Path: $ScriptPath" -ForegroundColor White
    Write-Host "- Trigger: At user logon" -ForegroundColor White
    Write-Host "- Runs as: $AdminUsername" -ForegroundColor White
    Write-Host "- Run Level: Highest (Administrator)" -ForegroundColor White
    Write-Host "- Visibility: Hidden" -ForegroundColor White
    
    # Option to test the task
    Write-Host "`nTo test the task manually, run:" -ForegroundColor Yellow
    Write-Host "Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Yellow
    
    Write-Host "`nTo view hidden tasks in Task Scheduler GUI:" -ForegroundColor Cyan
    Write-Host "Run 'taskschd.msc', go to View menu, and check 'Show Hidden Tasks'" -ForegroundColor White
    
} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
}

# Optional: Display all scheduled tasks for verification
Write-Host "`nTo delete this task later, run:" -ForegroundColor Cyan
Write-Host "Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White
