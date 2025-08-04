:: Requires admin to mess with registry values.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    set "params=%*"
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0 %params%' -Verb RunAs"
    exit /b
)


:: Load default registry values.
echo Loading registry values from default profile...
REG LOAD HKU\TempDefault "C:\Users\Default\NTUSER.DAT"

:: Disable swipe gestures.
echo Disabling swipe gestures...
REG ADD "HKU\TempDefault\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v ThreeFingerTapEnabled /t REG_DWORD /d 0 /f
REG ADD "HKU\TempDefault\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v ThreeFingerSlideEnabled /t REG_DWORD /d 0 /f
REG ADD "HKU\TempDefault\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v FourFingerTapEnabled /t REG_DWORD /d 0 /f
REG ADD "HKU\TempDefault\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v FourFingerSlideEnabled /t REG_DWORD /d 0 /f

:: Disable sticky keys
echo Disabling sticky keys...
REG ADD "HKU\TempDefault\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 506 /f
REG ADD "HKU\TempDefault\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d 122 /f

:: Apply the default registry values.
echo Applying changed values to default profile...
REG UNLOAD HKU\TempDefault