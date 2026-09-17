@echo off
REM ============================================================
REM  NileSky - push the verified fixes to GitHub
REM  Just double-click this file. Nothing else to do.
REM ============================================================
cd /d "%~dp0"

echo.
echo  Pushing NileSky fixes to github.com/engkemo1/nile_Sky
echo  -----------------------------------------------------
echo.

git add -A
if errorlevel 1 goto fail

git commit -m "Fix production blockers in API, customer app and admin panel" -m "Backend: repoint package-lock.json off registry.npmmirror.com (unreachable from Render, so the build failed); strip passwordHash/refreshTokenHash from every response; Update DTOs use PartialType so PATCH accepts partial payloads; coerce the ?guests= query param. Customer app: add INTERNET permission to the release manifest; parse decimal strings instead of calling .toDouble() on them; booking failures no longer strand the confirm button; coupon totals now match what the server charges; stop inventing an unassigned driver; 60s timeouts for free-tier cold starts; remove demo credentials. Admin panel: parse decimal strings in analytics/bookings/dashboard; add the operator picker that create required; omit blank optional fields; fix generateFlights return type; add 60s timeouts; remove the admin credentials printed on the login screen."
if errorlevel 1 (
  echo.
  echo  Nothing new to commit - maybe already pushed? Trying push anyway.
)

git push origin main
if errorlevel 1 goto fail

echo.
echo  ============================================
echo   DONE. Fixes are on GitHub.
echo   Now go back to Claude and say "pushed".
echo  ============================================
echo.
pause
exit /b 0

:fail
echo.
echo  ============================================
echo   Something went wrong. Copy the red text
echo   above and paste it to Claude.
echo  ============================================
echo.
pause
exit /b 1
