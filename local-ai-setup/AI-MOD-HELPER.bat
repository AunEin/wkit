@echo off
title AI Mod Helper
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM ============================================================
REM   AI Mod Helper -- the friendly launcher
REM ============================================================
REM   Opens VS Code at the mod folder you pick, with the local
REM   AI chat (Cline + Ollama) ready to use.
REM ============================================================

REM Find a PowerShell
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

REM Sanity-check the brain script exists
if not exist ".\scripts\ai-mod-helper.ps1" (
    echo.
    echo   [ERROR] Missing file: scripts\ai-mod-helper.ps1
    echo           Re-extract the release zip and try again.
    echo.
    pause
    exit /b 1
)

%PSEXE% -NoProfile -ExecutionPolicy Bypass -STA -Command ^
  "& { try { & '.\scripts\ai-mod-helper.ps1' @args } catch { Write-Host ('FATAL: ' + $_.Exception.Message) -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray; exit 99 } }" %*
set "EXITCODE=!ERRORLEVEL!"

REM Only pause on error -- success means VS Code is opening, no need to keep this window
if not "!EXITCODE!"=="0" (
    echo.
    echo ============================================================
    echo   The launcher exited with code !EXITCODE!. Press any key.
    echo ============================================================
    pause >nul
)

endlocal
exit /b %EXITCODE%
