# 1. Set execution policy to allow scripts (for current user)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. Unblock all .ps1 scripts in the NerfPack folder
$scriptPath = "C:\Program Files\NerfPack"
Get-ChildItem -Path $scriptPath -Filter *.ps1 -Recurse | Unblock-File

# 3. Confirm the folder exists and list scripts
if (Test-Path $scriptPath) {
    Write-Output "Scripts in $scriptPath are now unblocked and ready to run."
    Get-ChildItem -Path $scriptPath -Filter *.ps1
} else {
    Write-Output "Folder $scriptPath does not exist."
}
