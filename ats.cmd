@echo off
setlocal
set "P=%~dp0"
set "PSH=pwsh"
where %PSH% >nul 2>nul || set "PSH=powershell"

REM === step 1: compute targets from alpha (softmax; fallback 1/N handled in script) ===
IF /I "%~1"=="run" (
    python -u "%P%tools\targets_from_alpha.py" %*
    REM === step 2: derive orders & fills from targets ===
    python -u "%P%tools\orders_fills.py" %*
)

REM === step 3: delegate to PowerShell runner (orders/fills бізнес-логіка нижче лишається як є) ===
"%PSH%" -NoProfile -ExecutionPolicy Bypass -File "%P%tools\ats.ps1" %*
exit /b %ERRORLEVEL%
