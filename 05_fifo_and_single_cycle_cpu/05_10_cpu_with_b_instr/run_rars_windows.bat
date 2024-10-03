@echo off

set targetDir=scripts
set targetFile=run_rars_windows.bat
set dir=%~dp0

:loop
if %dir:~-1% == "\" (
    echo Directory %targetDir% not found in the path
    exit /b
)

if exist "%dir%\%targetDir%" (
    set "ScriptPath=%dir%\%targetDir%\%targetFile%"
    goto :end
)

for %%i in ("%dir:~0,-1%") do set "dir=%%~dpi"
goto :loop
:end

call "%ScriptPath%"
