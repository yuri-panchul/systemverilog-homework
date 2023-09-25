echo ALL PROBLEMS > log.txt

for %%f in (*.sv) do (
    C:\iverilog\bin\iverilog -g2005-sv %%f >> log.txt 2>&1
    C:\iverilog\bin\vvp a.out >> log.txt 2>&1
    rem C:\iverilog\gtkwave\bin\gtkwave dump.vcd
)

del /q a.out

findstr PASS  log.txt
findstr FAIL  log.txt
findstr error log.txt
