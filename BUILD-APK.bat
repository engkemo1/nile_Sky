@echo off
title NileSky - Build the customer Android app
cd /d "%~dp0\customer_app"
echo.
echo   Building the NileSky customer app...
echo   This takes a few minutes. Please wait.
echo.
call flutter pub get
call flutter build apk --release --dart-define=API_URL=https://nile-sky.vercel.app
echo.
if errorlevel 1 (
  echo   ============================================
  echo    BUILD FAILED - copy the text above to Claude
  echo   ============================================
) else (
  echo   ============================================
  echo    DONE! Your app is here:
  echo    customer_app\build\app\outputs\flutter-apk\app-release.apk
  echo   ============================================
)
echo.
pause
