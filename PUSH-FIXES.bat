@echo off
REM ============================================================
REM  NileSky - push the Vercel build fix to GitHub
REM  Just double-click this file.
REM ============================================================
cd /d "%~dp0"

echo.
echo  Pushing to github.com/engkemo1/nile_Sky
echo  --------------------------------------
echo.

git add -A
git commit -m "Install devDependencies on Vercel so the Nest CLI is available" -m "NODE_ENV=production makes npm skip devDependencies, and @nestjs/cli lives there, so the build failed with 'nest: command not found'. installCommand now passes --include=dev."
git push origin main
if errorlevel 1 goto fail

echo.
echo  ============================================
echo   DONE. Go back to Claude and say "pushed".
echo  ============================================
echo.
pause
exit /b 0

:fail
echo.
echo  Something went wrong - copy the text above to Claude.
echo.
pause
exit /b 1
