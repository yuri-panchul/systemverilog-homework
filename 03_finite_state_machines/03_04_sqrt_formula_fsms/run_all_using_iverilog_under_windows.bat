@echo off

echo ALL PROBLEMS > log.txt

where iverilog > nul 2>&1

if errorlevel 1 (
    if exist C:\iverilog\bin\iverilog.exe (
        C:\iverilog\bin\iverilog -g2005-sv black_boxes/*.sv *.sv -I testbenches testbenches/*.sv >> log.txt 2>&1
        C:\iverilog\bin\vvp a.out >> log.txt 2>&1
        rem C:\iverilog\gtkwave\bin\gtkwave dump.vcd
    ) else (
        echo ERROR: iverilog.exe is not in the path, is not in the default location C:\iverilog\bin or cannot be run.
        echo See README.md file in the package directory for the instructions on how to install Icarus Verilog.
        pause
        exit /b 1
    )
) else (
    iverilog -g2005-sv black_boxes/*.sv *.sv -I testbenches testbenches/*.sv >> log.txt 2>&1
    vvp a.out >> log.txt 2>&1
    rem gtkwave dump.vcd
)

del /q a.out dump.vcd

findstr PASS  log.txt
findstr FAIL  log.txt
findstr error log.txt
