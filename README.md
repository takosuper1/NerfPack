# NerfPack
Software meant to take new ai copilot laptops and restrict them to be more suitable for student use in the classroom.

## What is it
It is a windows software that limits student Windows machines that have Copilot preinstalled. As long as the domain is setup correctly and students only have access to a standard account, this will keep the laptop limited for school use. The features offered by this software is removal of copilot on the local machine and via microsoft edge sidebar, removal of the windows store (which could easily reinstall copilot), removal of USB execution, removal of swipe gestures on trackpads. 

## How to setup

### USB installer
Copy the NerfPack and the uSBInstallNerfPack.bat to a USB drive at the root level. Insert into the desired machine and login as an admin. Run the installer as admin. Check Task Scheduler. Make sure that you can see hidden tasks. Verify the creation of "runNerfCheck" in Active Tasks in Task Scheduler. Double-click on it and then hit the "Run" button on the next screen to the right.

### Copying from a domain server
Copy only the NerfPack folder into Program Files on the C drive of the local Windows machine. 

After you do that, open the NerfPack folder. Copy the contents of unblockScriptsForNerfPack.ps1 and paste them into powershell running as admin. This will allow scripts in this folder to run. 

Next run this commmand:
`& .\createNerfTask.ps1`

Once that completes, verify the creation of "runNerfCheck" in Active Tasks in Task Scheduler. Double-click on it and then hit the "Run" button on the next screen to the right.


## Final Verification
Some of these features might need a restart, so it is best to make sure that you have restarted before verifying.

1. To test if Copilot is off the system, hit the copilot button on the keyboard. It should now function like a right-click.

2. To test if Copilot and the sidebar on Microsoft Edge is gone, open Microsoft Edge. If there are initial prompts, cycle through them first. Then open a new tab. The sidebar with the copilot button should be gone. If not, kill the session and restart the browser. If it is still there, run: 

`& C:\Program Files\NerfPack\runNerfCheck.ps1`

Then check the logs: NerfLogs.txt and AppLogs.txt. Look for removeEdgeSidebar to see what went wrong.

3. To test the removal of Microsoft Store, hit the Start button and type Microsoft Store. If nothing appears, all is good. If it is still there, check the logs: NerfLogs.txt and AppLogs.txt. Look for removeWindowsStore to see what went wrong.

4. To test the USB execution to see if Windows is blocking it, check the registry by running this command in powershell:

`Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" -Name "Deny_Execute"`

The other option is to have a simple executable file on a USB and edit and run the following command to match the path of the program on your USB:

`$usbPath = "E:\test.exe"  # Replace E: with your actual USB drive letter
if (Test-Path $usbPath) {
    try {
        Start-Process -FilePath $usbPath -ErrorAction Stop
        Write-Host "Execution allowed: USB execution is enabled." -ForegroundColor Green
    } catch {
        Write-Host "Execution blocked: USB execution is likely disabled." -ForegroundColor Red
    }
} else {
    Write-Host "Test file not found on USB drive."
}`

5. To verify swipe gestures, perform a swipe gesture and see if it works. 

## Troubleshooting
Some of these features might need a restart, so it is best to make sure that you have restarted before verifying.

Once the program runs, it creates logs. Here are the file locations:

NerfPack\AppLogs.txt
This log shows the logs of the individual scripts and any errors in that may occur.

NerfPack\NerfLogs.txt
This log shows the logs of the main program each time it cycles on logon. There are stars (****) to show when the program started and ended to help visually see the cycles.

==NOTE==
the scripts to re-enable features have not been rigorously tested yet, so will want to be sure of what features you want first. If there is a feature that you do not want, you can delete the line that calls the script inside the runNerfCheck.ps1 file.
