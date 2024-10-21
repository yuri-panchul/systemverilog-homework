@echo off
setlocal
type nul > log.txt
set mainDir=%cd%

where iverilog > nul 2>&1
if errorlevel 1 (
    if exist "C:\iverilog\bin\iverilog.exe" (
        set iverilog="C:\iverilog\bin\iverilog"
        set vvp="C:\iverilog\bin\vvp"
        set gtkwave="C:\iverilog\gtkwave\bin\gtkwave"
    ) else (
    echo ERROR: iverilog.exe is not in the path, is not in the default location C:\iverilog\bin or cannot be run.
    echo See README.md file in the package directory for the instructions on how to install Icarus Verilog.
        exit /b 1
    )
) else (
    set iverilog=iverilog
    set vvp=vvp
    set gtkwave=gtkwave
)

set targetDir=bin
set targetFile=rars1_6.jar
set dir=%~dp0

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

if exist "program.s" (
    where java > nul 2>&1
    if errorlevel 1 (
        echo ERROR: java.exe is not in the path. It is needed to run RARS, a RISC-V instruction set simulator."
        pause
        exit /b 1
    )

    rem :: nc                             - Copyright notice will not be displayed
    rem :: a                              - assembly only, do not simulate
    rem :: ae<n>                          - terminate RARS with integer exit code if an assemble error occurs
    rem :: dump .text HexText program.hex - dump segment .text to program.hex file in HexText format

    java -jar "%PathToBin%" nc a ae1 dump .text HexText program.hex program.s >> log.txt
    %iverilog% -g2005-sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
    %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
    del a.out
) else if exist "testbenches" (
    %iverilog% -g2005-sv -I testbenches testbenches/*.sv black_boxes/*.sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
    %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
    del /q a.out
) else if exist "tb.sv" (
    %iverilog% -g2005-sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
    %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
    del a.out
) else (
    for /d %%d in (*) do (
        if exist "%%d/program.s" (
            pushd %%d
            where java > nul 2>&1
            if errorlevel 1 (
            echo ERROR: java.exe is not in the path. It is needed to run RARS, a RISC-V instruction set simulator."
            pause
            exit /b 1
            )

            rem :: nc                             - Copyright notice will not be displayed
            rem :: a                              - assembly only, do not simulate
            rem :: ae<n>                          - terminate RARS with integer exit code if an assemble error occurs
            rem :: dump .text HexText program.hex - dump segment .text to program.hex file in HexText format

            type nul > log.txt
            java -jar %PathToBin% nc a ae1 dump .text HexText program.hex program.s >> log.txt 2>&1
            %iverilog% -g2005-sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
            %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
            del a.out
            popd
        ) else if exist "%%d/testbenches" (
            pushd %%d
            type nul > log.txt
            %iverilog% -g2005-sv -I testbenches testbenches/*.sv black_boxes/*.sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
            %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
            del a.out
            popd
        ) else if exist "%%d/tb.sv" (
            pushd %%d
            type nul > log.txt
            %iverilog% -g2005-sv *.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
            %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
            del a.out
            popd
        ) else (
            %iverilog% -g2005-sv %%d/*.sv 2>&1 | findstr /v /c:"sorry: constant selects" >> log.txt
            %vvp% a.out 2>&1 | findstr /v /c:"$finish called" >> log.txt
            del a.out
        )
    )
)

if %1=="-wave" (
    if exist "dump.vcd" (
        if exist "gtkwave.tcl" (
            start "" %gtkwave% dump.vcd --script gtkwave.tcl
        ) else (
            start "" %gtkwave% dump.vcd
        )
    )
)

if exist "log.txt" (
    for /f "tokens=*" %%i in ('findstr /c:"PASS" /c:"FAIL" /c:"ERROR" /c:"Error" /c:"error" /c:"Timeout" "log.txt"') do (
        echo %%i
    )
)
for /d %%d in (*) do (
    if exist "%%d\log.txt" (
        for /f "tokens=*" %%i in ('findstr /c:"PASS" /c:"FAIL" /c:"ERROR" /c:"Error" /c:"error" /c:"Timeout" "%%d\log.txt"') do (
            echo %%d: %%i
        )
    )
)

for /d %%d in (*) do (
    if exist "%%d\log.txt" (
        echo %%d >> %mainDir%\log.txt
        type %%d\log.txt >> %mainDir%\log.txt
        echo.  >> %mainDir%\log.txt
    )
)