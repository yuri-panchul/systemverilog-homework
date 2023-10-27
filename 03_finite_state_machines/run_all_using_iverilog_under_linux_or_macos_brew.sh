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

for f in *.sv
do
       iverilog -g2005-sv $f >> log.txt 2>&1  \
    && vvp a.out             >> log.txt 2>&1

    # gtkwave dump.vcd
done

rm -f a.out

grep -e PASS -e FAIL -e error log.txt

cd 03_04_sqrt_formula_fsms
./run_all_using_iverilog_under_linux_or_macos_brew.sh
