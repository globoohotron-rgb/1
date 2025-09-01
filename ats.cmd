@echo off
setlocal
set P=%~dp0
set PWSH=pwsh
where %PWSH% >nul 2>nul || set PWSH=powershell
"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%P%tools\ats.ps1" %*
exit /b %ERRORLEVEL%
