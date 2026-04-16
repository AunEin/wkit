@echo off
title CP2077 Local AI -- Installer (v4.2)
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM ============================================================
REM   CP2077 Local AI -- Easy Mode Installer (v4.2)
REM ============================================================
REM   v4.2 changes:
REM     - NO admin elevation. Runs as your user, like a portable
REM       app. Every installer that needs admin will pop its OWN
REM       UAC prompt when needed.
REM     - Window NEVER closes silently. Always pauses at the end,
REM       even on errors, so you can read what happened.
REM     - Logs everything to install.log beside this .bat so you
REM       can attach it to a bug report.
REM ============================================================

REM Time-stamped log file (overwrites previous run)
set "LOGFILE=%~dp0install.log"
echo CP2077 Local AI Installer v4.2 - %DATE% %TIME% > "%LOGFILE%"
echo Working dir: %CD% >> "%LOGFILE%"

cls
echo.
echo ============================================================
echo   CP2077 Local AI -- Easy Mode Installer (v4.2)
echo ============================================================
echo.
echo   Working from:  %CD%
echo   Log file:      %LOGFILE%
echo.

REM ---- Find a PowerShell ----------------------------------------
set "PSEXE="
where pwsh.exe >nul 2>&1 && set "PSEXE=pwsh.exe"
if not defined PSEXE (
    where powershell.exe >nul 2>&1 && set "PSEXE=powershell.exe"
)
if not defined PSEXE (
    echo   [ERROR] PowerShell is not available on this system.
    echo           This is unusual on Windows -- try installing
    echo           "PowerShell" from the Microsoft Store.
    echo.
    echo PowerShell missing >> "%LOGFILE%"
    pause
    exit /b 1
)

echo   Using PowerShell:   %PSEXE%

REM ---- Sanity-check that the brain script is present ------------
if not exist ".\scripts\install-everything.ps1" (
    echo.
    echo   [ERROR] Missing file: scripts\install-everything.ps1
    echo           This usually means the zip wasn't fully
    echo           extracted, or you're running this .bat from
    echo           a different folder than where the zip went.
    echo.
    echo           Re-extract the zip and try again.
    echo.
    echo Missing scripts\install-everything.ps1 >> "%LOGFILE%"
    pause
    exit /b 1
)
echo   Found brain script: scripts\install-everything.ps1
echo.

echo ============================================================
echo   What happens next:
echo     1. The PowerShell script will check what's missing.
echo     2. If Ollama or VS Code aren't installed, their OWN
echo        installer will open and you may need to click YES
echo        on a UAC prompt -- that's normal.
echo     3. Then it downloads the AI model (~5 GB) -- the
echo        progress is shown right in this window.
echo.
echo   This window stays open the whole time. If anything goes
echo   wrong, you'll see it here. Nothing closes silently.
echo ============================================================
echo.

choice /C YN /N /M "Ready to start? (Y/N) "
if errorlevel 2 (
    echo.
    echo   Cancelled. Press any key to close.
    pause >nul
    exit /b 0
)

echo.
echo ----- PowerShell installer starting -----------------------
echo.

REM Run installer; tee output to log via PowerShell's Tee-Object on a single command
%PSEXE% -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { try { & '.\scripts\install-everything.ps1' } catch { Write-Host ('FATAL: ' + $_.Exception.Message) -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray; exit 99 } }" 2>&1
set "EXITCODE=!ERRORLEVEL!"

echo.
echo ----- PowerShell installer finished (exit code !EXITCODE!) -----
echo Exit code: !EXITCODE! >> "%LOGFILE%"

echo.
if "!EXITCODE!"=="0" (
    echo   ALL DONE. You can close this window now.
    echo   Next: double-click "AI Mod Helper" on your Desktop.
) else (
    echo   ^>^>^> Something did not complete cleanly. Common causes:
    echo.
    echo       1. You clicked NO on Ollama's or VS Code's UAC
    echo          prompt   -- re-run this .bat and click YES.
    echo       2. Internet connection dropped mid-download
    echo          -- re-run this .bat ^(it skips already-done parts^).
    echo       3. Antivirus blocked PowerShell from running scripts
    echo          -- temporarily disable real-time protection and retry.
    echo.
    echo   Re-running this .bat is ALWAYS safe. Already-installed
    echo   pieces are skipped automatically.
)

echo.
echo ============================================================
echo   Press any key to close this window.
echo ============================================================
pause >nul

endlocal
exit /b %EXITCODE%
