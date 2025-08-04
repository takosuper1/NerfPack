# Test Registry
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" -Name "Deny_Execute"

# Practical test. Needs to have an executable file for $usbPath
$usbPath = "E:\test.exe"  # Replace E: with your actual USB drive letter
if (Test-Path $usbPath) {
    try {
        Start-Process -FilePath $usbPath -ErrorAction Stop
        Write-Host "Execution allowed: USB execution is enabled." -ForegroundColor Green
    } catch {
        Write-Host "Execution blocked: USB execution is likely disabled." -ForegroundColor Red
    }
} else {
    Write-Host "Test file not found on USB drive."
}
