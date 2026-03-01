@echo off
setlocal

REM Reliable release APK build script:
REM - Forces JDK 17 even if system Java is 21+
REM - Uses project-local caches to reduce environment drift
REM - Provides clear failure messages

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

if not exist "%PROJECT_DIR%\pubspec.yaml" (
  echo [ERROR] pubspec.yaml not found in "%PROJECT_DIR%".
  echo Run this script from the project root folder.
  exit /b 1
)

set "_JAVA17_HOME="
if defined WA_JAVA17_HOME if exist "%WA_JAVA17_HOME%\bin\java.exe" set "_JAVA17_HOME=%WA_JAVA17_HOME%"

if not defined _JAVA17_HOME (
  if exist "C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot\bin\java.exe" set "_JAVA17_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
)

if not defined _JAVA17_HOME (
  for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do (
    if exist "%%~fD\bin\java.exe" set "_JAVA17_HOME=%%~fD"
  )
)

if not defined _JAVA17_HOME (
  for /d %%D in ("C:\Program Files\Java\jdk-17*") do (
    if exist "%%~fD\bin\java.exe" set "_JAVA17_HOME=%%~fD"
  )
)

if not defined _JAVA17_HOME (
  for /d %%D in ("C:\Program Files\Microsoft\jdk-17*") do (
    if exist "%%~fD\bin\java.exe" set "_JAVA17_HOME=%%~fD"
  )
)

if not defined _JAVA17_HOME (
  echo [ERROR] JDK 17 not found.
  echo Install Temurin/OpenJDK 17 or set WA_JAVA17_HOME to your JDK 17 path.
  exit /b 1
)

set "JAVA_HOME=%_JAVA17_HOME%"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "GRADLE_USER_HOME=%PROJECT_DIR%\.gradle-cache"
set "PUB_CACHE=%PROJECT_DIR%\.pub-cache"

if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Flutter is not on PATH.
  echo Add flutter\bin to PATH, then run again.
  exit /b 1
)

echo Using JAVA_HOME=%JAVA_HOME%
echo Using GRADLE_USER_HOME=%GRADLE_USER_HOME%
echo Using PUB_CACHE=%PUB_CACHE%

java -version
echo.
echo Building release APK...
call flutter build apk --release %*
set EXIT_CODE=%ERRORLEVEL%

if "%EXIT_CODE%"=="0" (
  echo.
  echo [OK] Build command completed successfully.
  if exist "%PROJECT_DIR%\build\app\outputs\flutter-apk\app-release.apk" (
    echo APK path:
    echo %PROJECT_DIR%\build\app\outputs\flutter-apk\app-release.apk
  )
) else (
  echo.
  echo [ERROR] Build failed with exit code %EXIT_CODE%.
)

endlocal & exit /b %EXIT_CODE%
