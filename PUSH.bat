@echo off
title NileSky - Push new admin features
cd /d "%~dp0"
echo.
echo   Sending the new admin panel features to GitHub...
echo.
git add -A
git commit -m "Add missing admin features: media storage, flight editor, packages/users/reviews screens"
git push origin main
echo.
if errorlevel 1 (
  echo    FAILED - copy the text above to Claude
) else (
  echo    DONE! Go to Claude and type:  pushed
)
echo.
pause
