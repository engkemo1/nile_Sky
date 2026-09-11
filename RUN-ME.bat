@echo off
REM NileSky - double-click this file to deploy.
REM Uses -ExecutionPolicy Bypass because Windows blocks .ps1 scripts by default.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0go-live.ps1"
echo.
echo ===============================================
echo  Finished. Read the messages above.
echo  Copy any red text and send it to Claude.
echo ===============================================
pause
