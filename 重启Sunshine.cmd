@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-Command','Restart-Service SunshineService -Force; Start-Sleep 2; Get-Service SunshineService'"
echo.
pause
