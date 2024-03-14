@echo off

set rars_jar=rars1_6.jar

where java > nul 2>&1

if errorlevel 1 (
    echo ERROR: java.exe is not in the path. It is needed to run RARS, a RISC-V instruction set simulator."
    pause
    exit /b 1
)

java -jar ../../bin/%rars_jar%
