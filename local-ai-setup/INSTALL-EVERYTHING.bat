@echo off
REM ============================================================
REM   CP2077 Local AI -- Easy Mode One-Click Installer (v4.0)
REM ============================================================
REM   Just double-click this file. It installs:
REM     * Ollama          (the AI engine)
REM     * VS Code         (the friendly editor)
REM     * Cline extension (the chat panel inside VS Code)
REM     * Qwen3-Coder 7B  (the AI brain, ~5 GB download)
REM     * Optional: Qwen3-Coder 30B-A3B (~18 GB, asks first)
REM     * Desktop shortcut "AI Mod Helper"
REM
REM   You can re-run this any time -- already-installed parts
REM   are skipped automatically.
REM ============================================================

setlocal
pushd "%~dp0"

REM Try to elevate to Administrator (needed by some installers).
REM If we're already elevated, skip the dance.
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo   This installer needs Administrator rights to run a few of the
    echo   installers (Ollama / VS Code). Windows will pop up a UAC prompt
    echo   in a moment -- click YES.
    echo.
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    popd
    endlocal
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\install-everything.ps1"
set "EXITCODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo   Installer finished. Press any key to close this window.
echo ============================================================
pause >nul

popd
endlocal
exit /b %EXITCODE%
