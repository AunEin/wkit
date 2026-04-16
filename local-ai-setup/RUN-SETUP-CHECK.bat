@echo off
REM ============================================================
REM   CP2077 Local AI Setup v3.0 -- System Checker
REM ============================================================
REM   Just runs the PowerShell checker in read-only mode.
REM   Tells you what's installed and what's missing.
REM   Does NOT download or change anything.
REM ============================================================

setlocal
pushd "%~dp0"

echo.
echo ============================================================
echo   CP2077 Local AI Setup v3.0 -- Checking your system...
echo ============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\check-local-ai-setup.ps1"
set "EXITCODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo   Check finished. Press any key to close this window.
echo ============================================================
pause >nul

popd
endlocal
exit /b %EXITCODE%
