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

if [ "$1" = "--lint" ]
then

    if command -v verilator > /dev/null 2>&1
    then
        run_lint=true
    else
    echo "ERROR [--lint]: Verilator is not in the path"                      \
         "or cannot be run."                                                 \
         "See README.md file in the package directory for the instructions"  \
         "how to install Verilator."                                         \
          2>&1

        echo "Press enter"
        read enter
        exit 1
    fi

else
    run_lint=false
fi

rm -rf log.txt
rm -f lint.txt

iverilog -g2005-sv                   \
    -I testbenches testbenches/*.sv  \
    black_boxes/*.sv                 \
    *.sv                             \
             >> log.txt 2>&1         \
&& vvp a.out >> log.txt 2>&1

for f in *.sv
do
    if [ $run_lint = true ]
    then
        printf "==============================================\n\n" >> lint.txt
        printf "File: $f\n\n" >> lint.txt
        printf "==============================================\n\n" >> lint.txt

        verilator --lint-only -Wall --timing -Wno-MULTITOP \
        -Wno-DECLFILENAME -Wno-INITIALDLY -Iblack_boxes $f >> lint.txt 2>&1

        sed -i '/- Verilator:/d' lint.txt
        sed -i '/- V e r i l a t i o n/d' lint.txt
    fi
done

if [ -f dump.vcd ] ; then
    gtkwave dump.vcd --script gtkwave.tcl
fi

rm -f a.out
# rm -f dump.vcd

grep -e PASS -e FAIL -e ERROR -e Error -e error -e Timeout log.txt
