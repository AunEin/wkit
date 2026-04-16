@echo off
REM ============================================================
REM   CP2077 Local AI -- End-to-End Smoke Test
REM ============================================================
REM   Pings every layer (Ollama API, models, generation,
REM   VS Code, Cline, workspace template) and tells you what
REM   actually works and what doesn't.
REM
REM   First run takes 10-30s while the model loads onto the GPU.
REM ============================================================

setlocal
pushd "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\verify-install.ps1" %*
set "EXITCODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo   Press any key to close this window.
echo ============================================================
pause >nul

popd
endlocal
exit /b %EXITCODE%
