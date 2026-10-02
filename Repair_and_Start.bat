@echo off
setlocal
cd /d "%~dp0"
curl.exe --silent --show-error --location --fail --connect-timeout 10 --max-time 30 --retry 1 --output "%~dp0Download_Game_20261002_1713.ps1.new" "https://raw.githubusercontent.com/aarongameboy/package/bb431171a92b54ad808798ea88c2bbdbe7fe2b01/Download_Game_20261002_1713.ps1"
if errorlevel 1 (
    if not exist "%~dp0Download_Game_20261002_1713.ps1" goto failed
    echo Using cached matching downloader. Existing downloads will be resumed.
) else (
    move /y "%~dp0Download_Game_20261002_1713.ps1.new" "%~dp0Download_Game_20261002_1713.ps1" >nul
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Download_Game_20261002_1713.ps1" -StartGame
if errorlevel 1 goto failed
exit /b 0
:failed
echo Download or verification failed. Check your network and run again.
pause
exit /b 1
