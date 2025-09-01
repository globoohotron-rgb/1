@echo off
setlocal
set "P=%~dp0"
set "PSH=pwsh"
where %PSH% >nul 2>nul || set "PSH=powershell"

REM === step 1: targets from alpha (softmax long-only; fallback 1/N) ===
IF /I "%~1"=="run" (
    python -u "%P%tools\targets_from_alpha.py" %*
    REM continue regardless of python exit code
)

REM === step 2: delegate to PowerShell runner (orders/fills unchanged) ===
"%PSH%" -NoProfile -ExecutionPolicy Bypass -File "%P%tools\ats.ps1" %*
exit /b %ERRORLEVEL%
