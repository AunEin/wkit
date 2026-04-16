@echo off
REM ============================================================
REM   AI Mod Helper -- the friendly launcher
REM ============================================================
REM   Opens VS Code at the mod folder you pick, with the local
REM   AI chat (Cline + Ollama) ready to use.
REM ============================================================

setlocal
pushd "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\scripts\ai-mod-helper.ps1" %*
set "EXITCODE=%ERRORLEVEL%"

popd
endlocal
exit /b %EXITCODE%
