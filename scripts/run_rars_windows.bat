@echo off

set targetDir=bin
set targetFile=rars1_6.jar
set dir=%~dp0

where java > nul 2>&1

if errorlevel 1 (
    echo ERROR: java.exe is not in the path. It is needed to run RARS, a RISC-V instruction set simulator."
    pause
    exit /b 1
)

:loop
if %dir:~-1% == "\" (
    echo Directory %targetDir% not found in the path
    exit /b
)

if exist "%dir%\%targetDir%" (
    set PathToBin="%dir%\%targetDir%\%targetFile%"
    goto :end
)

for %%i in ("%dir:~0,-1%") do set "dir=%%~dpi"
goto :loop
:end

start "" java -jar "%PathToBin%"