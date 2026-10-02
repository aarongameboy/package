@echo off
setlocal
cd /d "%~dp0"
curl.exe --silent --show-error --location --fail --connect-timeout 10 --max-time 30 --retry 1 --output "%~dp0Download_Game.ps1.new" "https://raw.githubusercontent.com/aarongameboy/package/main/Download_Game.ps1?update=%RANDOM%%RANDOM%"
if errorlevel 1 (
    if not exist "%~dp0Download_Game.ps1" goto failed
    echo Using cached downloader. Existing downloads will be resumed.
) else (
    move /y "%~dp0Download_Game.ps1.new" "%~dp0Download_Game.ps1" >nul
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Download_Game.ps1" -StartGame
if errorlevel 1 goto failed
exit /b 0
:failed
echo Download or verification failed. Check your network and run again.
pause
exit /b 1
