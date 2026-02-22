@echo off
echo ========================================
echo NOTIFICATION ACCESS FORCE REGISTRATION
echo ========================================
echo.

echo 🔍 Checking if device is connected...
adb devices
if errorlevel 1 (
    echo ❌ No device connected! Please connect your Android device with USB debugging enabled.
    pause
    exit /b 1
)

echo.
echo 📱 Checking current notification access settings...
adb shell settings get secure enabled_notification_listeners

echo.
echo 🔍 Checking if our app is installed...
adb shell pm list packages | findstr "wa_notifications_app"
if errorlevel 1 (
    echo ❌ App not found! Please install the app first with: flutter run
    pause
    exit /b 1
)

echo.
echo 🔧 Forcing service component enable...
adb shell pm enable com.example.wa_notifications_app/com.example.wa_notifications_app.NotificationsHandlerService

echo.
echo 🔍 Checking service component status...
adb shell dumpsys package com.example.wa_notifications_app | findstr "NotificationsHandlerService"

echo.
echo 🔄 Restarting app service...
adb shell am force-stop com.example.wa_notifications_app

echo.
echo ⏳ Waiting 3 seconds for service restart...
timeout /t 3 /nobreak > nul

echo.
echo 📱 Starting app...
adb shell am start -n com.example.wa_notifications_app/.MainActivity

echo.
echo 🔍 Monitoring service registration (will run for 30 seconds)...
echo 📝 Looking for these success indicators:
echo    - [SERVICE] onCreate called
echo    - [FORCED REGISTRATION] Attempt 1/5
echo    - [FINAL CHECK] Service registration and initialization completed
echo.
echo Press Ctrl+C to stop monitoring early.
echo.

adb logcat -s "NotificationsListenerService" -t 30

echo.
echo ========================================
echo REGISTRATION CHECK COMPLETE
echo ========================================
echo.
echo 📋 Next steps:
echo 1. Check Settings ^> Apps ^> Special access ^> Notification access
echo 2. Look for 'whatsapp_group_scheduler' or 'com.example.wa_notifications_app'
echo 3. Enable it if found
echo.
echo 🔍 To check manually:
echo    adb shell settings get secure enabled_notification_listeners
echo.
pause
