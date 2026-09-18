@echo off
title NileSky - Push to GitHub
cd /d "%~dp0"
echo.
echo   Sending your changes to GitHub...
echo.
git rm --cached backend/api/index.js 2>nul
del /q backend\api\index.js 2>nul
git add -A
git commit -m "Fix 404: preserve the request path through Vercel's rewrite"
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
