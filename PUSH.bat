@echo off
title NileSky - Push to GitHub
cd /d "%~dp0"
echo.
echo   Sending your changes to GitHub...
echo.
git add -A
git commit -m "Fix Vercel deploy and point both apps at the Vercel API URL"
git push origin main
echo.
if errorlevel 1 (
  echo   ============================================
  echo    FAILED - copy the text above to Claude
  echo   ============================================
) else (
  echo   ============================================
  echo    DONE! Go to Claude and type:  pushed
  echo   ============================================
)
echo.
pause
