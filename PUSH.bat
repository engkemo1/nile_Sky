@echo off
title NileSky - Push to GitHub
cd /d "%~dp0"
echo.
echo   Sending your changes to GitHub...
echo.
REM Remove the leftover Next.js-style catch-all (not honoured by Vercel)
if exist "backend\api\[[...slug]].js" del /q "backend\api\[[...slug]].js"
git rm --cached "backend/api/[[...slug]].js" >nul 2>&1
git add -A
git commit -m "Build the admin panel on Vercel; drop the stray catch-all file"
git push origin main
echo.
if errorlevel 1 (
  echo    FAILED - copy the text above to Claude
) else (
  echo    DONE! Go to Claude and type:  pushed
)
echo.
pause
