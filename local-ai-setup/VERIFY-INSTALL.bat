@echo off
title CP2077 Local AI -- Smoke Test
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM ============================================================
REM   CP2077 Local AI -- End-to-End Smoke Test
REM ============================================================

set "PSEXE="
where pwsh.exe >nul 2>&1 && set "PSEXE=pwsh.exe"
if not defined PSEXE (
    where powershell.exe >nul 2>&1 && set "PSEXE=powershell.exe"
)
if not defined PSEXE (
    echo.
    echo   [ERROR] PowerShell is not available on this system.
    echo.
    pause
    exit /b 1
)

if not exist ".\scripts\verify-install.ps1" (
    echo.
    echo   [ERROR] Missing file: scripts\verify-install.ps1
    echo           Re-extract the release zip and try again.
    echo.
    pause
    exit /b 1
)

%PSEXE% -NoProfile -ExecutionPolicy Bypass -File ".\scripts\verify-install.ps1" %*
set "EXITCODE=!ERRORLEVEL!"

echo.
echo ============================================================
echo   Press any key to close this window.
echo ============================================================
pause >nul

endlocal
exit /b %EXITCODE%
