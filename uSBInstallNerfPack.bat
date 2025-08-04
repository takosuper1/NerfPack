@echo off
REM This batch file copies NerfPack from USB (relative path) to Program Files and unblocks scripts
REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as Administrator!
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Set source path relative to this script's location
set "SOURCE_PATH=%~dp0NerfPack"
set "DEST_PATH=C:\Program Files\NerfPack"
set "PS_SCRIPT=%DEST_PATH%\createNerfTask.ps1"

echo Copying NerfPack from %SOURCE_PATH% to %DEST_PATH%...
robocopy "%SOURCE_PATH%" "%DEST_PATH%" /E /R:3 /W:5
if %errorlevel% geq 8 (
    echo ERROR: Copy operation failed with error level %errorlevel%
    pause
    exit /b 1
)
echo Copy completed successfully.

REM Unblock all scripts in the destination folder
echo Unblocking scripts in %DEST_PATH%...
powershell -Command "Get-ChildItem -Path '%DEST_PATH%' -Recurse -Include *.ps1,*.bat,*.cmd | Unblock-File"

REM Run PowerShell script if it exists
if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell script not found at %PS_SCRIPT%
    pause
    exit /b 1
)

echo Running PowerShell script: %PS_SCRIPT%
powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
if %errorlevel% neq 0 (
    echo ERROR: PowerShell script execution failed with error level %errorlevel%
    pause
    exit /b 1
)

echo.
echo All operations completed successfully!
pause
