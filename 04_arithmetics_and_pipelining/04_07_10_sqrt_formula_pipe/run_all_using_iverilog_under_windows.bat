@echo off

echo ALL PROBLEMS > log.txt

where iverilog > nul 2>&1

if errorlevel 1 (
    if exist C:\iverilog\bin\iverilog.exe (
        C:\iverilog\bin\iverilog -g2005-sv -I testbenches testbenches/*.sv black_boxes/*.sv *.sv >> log.txt 2>&1
        C:\iverilog\bin\vvp a.out >> log.txt 2>&1

        if exist dump.vcd (
            rem C:\iverilog\gtkwave\bin\gtkwave dump.vcd --script gtkwave.tcl
        )
    ) else (
        echo ERROR: iverilog.exe is not in the path, is not in the default location C:\iverilog\bin or cannot be run.
        echo See README.md file in the package directory for the instructions on how to install Icarus Verilog.
        pause
        exit /b 1
    )
) else (
    iverilog -g2005-sv -I testbenches testbenches/*.sv black_boxes/*.sv *.sv >> log.txt 2>&1
    vvp a.out >> log.txt 2>&1

    if exist dump.vcd (
        rem gtkwave dump.vcd --script gtkwave.tcl
    )
)

del /q a.out
rem del /q dump.vcd

findstr PASS  log.txt
findstr FAIL  log.txt
findstr error log.txt
