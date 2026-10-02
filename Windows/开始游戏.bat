@echo off
setlocal
set "GAME_ROOT=%~dp0.."
cd /d "%GAME_ROOT%"
curl.exe --silent --show-error --location --fail --connect-timeout 10 --max-time 30 --retry 1 --output "%GAME_ROOT%\Repair_and_Start.bat.new" "https://raw.githubusercontent.com/aarongameboy/package/da1508501632237b475bb8e4f851f1efe43d5252/Repair_and_Start.bat"
if errorlevel 1 (
    if not exist "%GAME_ROOT%\Repair_and_Start.bat" goto failed
    echo Using cached launcher. Existing downloads will be resumed.
) else (
    move /y "%GAME_ROOT%\Repair_and_Start.bat.new" "%GAME_ROOT%\Repair_and_Start.bat" >nul
)
call "%GAME_ROOT%\Repair_and_Start.bat"
exit /b %errorlevel%
:failed
echo Cannot update launcher. Check your network and run again.
pause
exit /b 1
