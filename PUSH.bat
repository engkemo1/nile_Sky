@echo off
title NileSky - Push to GitHub
cd /d "%~dp0"
echo.
echo   Sending your changes to GitHub...
echo.
git add -A
git commit -m "Carry the original path through Vercel's rewrite in a query parameter"
git push origin main
echo.
if errorlevel 1 (
  echo    FAILED - copy the text above to Claude
) else (
  echo    DONE! Go to Claude and type:  pushed
)
echo.
pause
