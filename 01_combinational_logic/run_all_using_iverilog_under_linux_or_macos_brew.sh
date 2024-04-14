#!/bin/sh

if ! command -v iverilog >/dev/null 2>&1
then
    echo "ERROR: Icarus Verilog (iverilog) is not in the path"               \
         "or cannot be run."                                                 \
         "See README.md file in the package directory for the instructions"  \
         "how to install Icarus."                                            \
          2>&1

    echo "Press enter"
    read enter
    exit 1
fi

rm -rf log.txt
rm -f lint.txt

for f in *.sv
do
       iverilog -g2005-sv $f >> log.txt 2>&1  \
    && vvp a.out             >> log.txt 2>&1

    # gtkwave dump.vcd
done

if command -v verilator > /dev/null 2>&1
then
    verilator --lint-only -Wall --timing --top testbench \
    -Wno-DECLFILENAME -Wno-INITIALDLY -Wno-MODDUP *.sv  >> lint.txt 2>&1

    sed -i '/- Verilator:/d' lint.txt
    sed -i '/- V e r i l a t i o n/d' lint.txt
    sed -i '/%Error:/d' lint.txt
fi

rm -f a.out

grep -e PASS -e FAIL -e error log.txt
