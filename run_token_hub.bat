@echo off
echo Launching Token Hub (Web Mode)...
echo This is the fastest way to access your app on the desktop.
cd /d "%~dp0"
flutter run -d chrome
if %errorlevel% neq 0 (
    echo.
    echo Launching on Windows Native...
    flutter run -d windows
)
pause
