@echo off
REM ============================================================
REM   CP2077 Local AI Setup v3.0 -- Download & Configure
REM ============================================================
REM   Runs the PowerShell checker in install mode:
REM     -DownloadMissing  pulls any missing AI models via Ollama
REM     -WriteConfig      installs opencode.json into %APPDATA%
REM   It ASKS before each big download (Y/N).
REM ============================================================

setlocal
pushd "%~dp0"

echo.
echo ============================================================
echo   CP2077 Local AI Setup v3.0 -- Auto-download mode
echo ============================================================
echo.
echo   This script will:
echo     - check your system
echo     - ask before downloading any missing AI models
echo     - install opencode.json into %%APPDATA%%\opencode\
echo.
echo   Make sure Ollama is installed first (https://ollama.com).
echo.
pause

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\check-local-ai-setup.ps1" -DownloadMissing -WriteConfig
set "EXITCODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo   Done. Press any key to close this window.
echo ============================================================
pause >nul

popd
endlocal
exit /b %EXITCODE%
