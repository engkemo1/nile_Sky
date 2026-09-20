@echo off
setlocal
title NileSky - Build Android APK + Windows Admin Panel
cd /d "%~dp0"

set LOG=%~dp0build-log.txt
set API=https://nile-sky.vercel.app

echo ============================================ > "%LOG%"
echo  NileSky build log >> "%LOG%"
echo  API: %API% >> "%LOG%"
echo  Started: %DATE% %TIME% >> "%LOG%"
echo ============================================ >> "%LOG%"

echo.
echo  ==========================================
echo   NileSky - building everything
echo   This takes 10-20 minutes. Please wait.
echo   Progress is saved to build-log.txt
echo  ==========================================
echo.

echo [0/3] Checking Flutter...
echo. >> "%LOG%"
echo ===== flutter doctor ===== >> "%LOG%"
call flutter doctor >> "%LOG%" 2>&1
if errorlevel 1 (
  echo   Flutter not found. Is it installed and on your PATH?
  echo   FLUTTER NOT FOUND >> "%LOG%"
  goto done
)

echo [1/3] Building the Android app ^(APK^)...
echo. >> "%LOG%"
echo ===== customer_app : flutter pub get ===== >> "%LOG%"
pushd customer_app
call flutter pub get >> "%LOG%" 2>&1
echo. >> "%LOG%"
echo ===== customer_app : flutter build apk ===== >> "%LOG%"
call flutter build apk --release --dart-define=API_URL=%API% >> "%LOG%" 2>&1
set APKRESULT=%errorlevel%
popd

echo [2/3] Building the Windows admin panel...
echo. >> "%LOG%"
echo ===== admin_panel : enable windows desktop ===== >> "%LOG%"
call flutter config --enable-windows-desktop >> "%LOG%" 2>&1
pushd admin_panel
echo. >> "%LOG%"
echo ===== admin_panel : flutter pub get ===== >> "%LOG%"
call flutter pub get >> "%LOG%" 2>&1
echo. >> "%LOG%"
echo ===== admin_panel : flutter build windows ===== >> "%LOG%"
call flutter build windows --release --dart-define=API_URL=%API% >> "%LOG%" 2>&1
set WINRESULT=%errorlevel%
popd

echo [3/3] Packaging...
if "%WINRESULT%"=="0" (
  if exist "admin_panel\build\windows\x64\runner\Release" (
    powershell -NoProfile -Command "Compress-Archive -Path 'admin_panel\build\windows\x64\runner\Release\*' -DestinationPath 'NileSky_Admin_Windows.zip' -Force" >> "%LOG%" 2>&1
  )
)

echo.
echo  ==========================================
echo   RESULTS
echo  ==========================================
if "%APKRESULT%"=="0" (
  echo   [OK]     Android app:
  echo            customer_app\build\app\outputs\flutter-apk\app-release.apk
) else (
  echo   [FAILED] Android app - see build-log.txt
)
if "%WINRESULT%"=="0" (
  echo   [OK]     Windows admin panel:
  echo            NileSky_Admin_Windows.zip
  echo            ^(run admin_panel.exe inside it^)
) else (
  echo   [FAILED] Windows admin panel - see build-log.txt
  echo            Usually means Visual Studio C++ tools are missing.
)
echo  ==========================================
echo.
echo   Now go to Claude and type:  built
echo   Claude will read build-log.txt and check the results.
echo.

:done
echo. >> "%LOG%"
echo Finished: %DATE% %TIME% >> "%LOG%"
pause
endlocal
