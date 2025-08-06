@echo off
setlocal enabledelayedexpansion

:: Windows Installer Script
:: This script copies files to Program Files and runs installation tasks

echo ================================
echo    NerfPack Installer
echo ================================
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: Administrator privileges required!
    echo Please right-click this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: Set variables
set "APP_NAME=NerfPack"
set "INSTALL_DIR=%ProgramFiles%\%APP_NAME%"
set "SOURCE_DIR=%~dp0"

echo Installing %APP_NAME%...
echo Source directory: %SOURCE_DIR%
echo Installation directory: %INSTALL_DIR%
echo.

:: Create installation directory
if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
    if !errorLevel! neq 0 (
        echo Error: Failed to create installation directory
        pause
        exit /b 1
    )
) else (
    echo Installation directory already exists
)

:: Copy files and folders
echo Copying application files...
xcopy "%SOURCE_DIR%*" "%INSTALL_DIR%\" /E /I /Y /Q
if %errorLevel% neq 0 (
    echo Error: Failed to copy files
    pause
    exit /b 1
)

:: Exclude the installer script from the copied files
if exist "%INSTALL_DIR%\install.bat" (
    del "%INSTALL_DIR%\install.bat"
)

echo Files copied successfully!
echo.

:: Run additional installation tasks
echo Running installation tasks...

:: Add to PATH
echo Adding %INSTALL_DIR% to system PATH...
setx PATH "%PATH%;%INSTALL_DIR%" /M >nul 2>&1

:: Create desktop shortcut (if main executable exists)
if exist "%INSTALL_DIR%\%APP_NAME%.exe" (
    echo Creating desktop shortcut...
    powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\%APP_NAME%.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\%APP_NAME%.exe'; $Shortcut.Save()}"
)

:: Run PowerShell installation scripts if they exist
if exist "%INSTALL_DIR%\unblockScriptsForNerfPack.ps1" (
    echo Running unblock scripts...
    powershell -ExecutionPolicy Bypass -File "%INSTALL_DIR%\unblockScriptsForNerfPack.ps1"
)

if exist "%INSTALL_DIR%\createNerfTask.ps1" (
    echo Running task creation script...
    powershell -ExecutionPolicy Bypass -File "%INSTALL_DIR%\createNerfTask.ps1"
)

:: Create uninstall script
echo Creating uninstaller...
(
echo @echo off
echo setlocal enabledelayedexpansion
echo echo Uninstalling %APP_NAME%...
echo.
echo :: Remove scheduled task
echo schtasks /delete /tn "runNerfCheck" /f ^>nul 2^>^&1
echo.
echo :: Stop service if running
echo sc stop "%APP_NAME%Service" ^>nul 2^>^&1
echo sc delete "%APP_NAME%Service" ^>nul 2^>^&1
echo.
echo :: Remove from PATH
echo for /f "tokens=2*" %%%%a in ^('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH'^) do set "currentPath=%%%%b"
echo set "newPath=!currentPath:%INSTALL_DIR%;=!"
echo setx PATH "!newPath!" /M ^>nul 2^>^&1
echo.
echo :: Remove shortcuts
echo del "%USERPROFILE%\Desktop\%APP_NAME%.lnk" ^>nul 2^>^&1
echo.
echo :: Remove installation directory
echo rmdir /s /q "%INSTALL_DIR%"
echo.
echo %APP_NAME% has been uninstalled.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"

echo.
echo ================================
echo    Installation Complete!
echo ================================
echo.
echo %APP_NAME% has been installed to:
echo %INSTALL_DIR%
echo.
echo Additional features:
echo - Added to system PATH
echo - Desktop shortcut created
echo - Uninstaller created
echo.
echo You can uninstall by running:
echo "%INSTALL_DIR%\uninstall.bat"
echo.
pause