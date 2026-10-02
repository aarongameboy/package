@echo off
setlocal
set "GAME_ROOT=%~dp0.."
cd /d "%GAME_ROOT%"
curl.exe --silent --show-error --location --fail --connect-timeout 10 --max-time 30 --retry 1 --output "%GAME_ROOT%\Repair_and_Start_20261002_1713.bat.new" "https://raw.githubusercontent.com/aarongameboy/package/4ce2ab8bf9c2a0be521fc4c5552354f0b8fc0cbe/Repair_and_Start_20261002_1713.bat"
if errorlevel 1 (
    if not exist "%GAME_ROOT%\Repair_and_Start_20261002_1713.bat" goto failed
    echo Using cached matching launcher. Existing downloads will be resumed.
) else (
    move /y "%GAME_ROOT%\Repair_and_Start_20261002_1713.bat.new" "%GAME_ROOT%\Repair_and_Start_20261002_1713.bat" >nul
)
call "%GAME_ROOT%\Repair_and_Start_20261002_1713.bat"
exit /b %errorlevel%
:failed
echo Cannot update launcher. Check your network and run again.
pause
exit /b 1
