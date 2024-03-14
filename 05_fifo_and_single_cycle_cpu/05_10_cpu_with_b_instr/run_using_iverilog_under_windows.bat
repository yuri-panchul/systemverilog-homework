@echo off

set rars_jar=rars1_6.jar

del /q log.txt

if exist program.s (
    where java > nul 2>&1

    if errorlevel 1 (
        echo ERROR: java.exe is not in the path. It is needed to run RARS, a RISC-V instruction set simulator."
        pause
        exit /b 1
    )

    :: nc                             - Copyright notice will not be displayed
    :: a                              - assembly only, do not simulate
    :: ae<n>                          - terminate RARS with integer exit code if an assemble error occurs
    :: dump .text HexText program.hex - dump segment .text to program.hex file in HexText format

    java -jar ../../bin/%rars_jar% nc a ae1 dump .text HexText program.hex program.s >> log.txt 2>&1
)

where iverilog > nul 2>&1

if errorlevel 1 (
    if exist C:\iverilog\bin\iverilog.exe (
        set iverilog_path=C:\iverilog\bin\
    ) else (
        echo ERROR: iverilog.exe is not in the path, is not in the default location C:\iverilog\bin or cannot be run.
        echo See README.md file in the package directory for the instructions on how to install Icarus Verilog.
        pause
        exit /b 1
    )
) else (
    set iverilog_path=
)

%iverilog_path%iverilog -g2005-sv *.sv >> log.txt 2>&1
%iverilog_path%vvp a.out               >> log.txt 2>&1

if exist dump.vcd (
    %iverilog_path%gtkwave dump.vcd
)

del /q a.out
rem del /q dump.vcd

findstr PASS    log.txt
findstr FAIL    log.txt
findstr ERROR   log.txt
findstr Error   log.txt
findstr error   log.txt
findstr Timeout log.txt
