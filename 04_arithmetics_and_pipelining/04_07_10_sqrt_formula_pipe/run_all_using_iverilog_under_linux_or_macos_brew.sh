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

iverilog -g2005-sv                   \
    -I testbenches testbenches/*.sv  \
    black_boxes/*.sv                 \
    *.sv                             \
             >> log.txt 2>&1         \
&& vvp a.out >> log.txt 2>&1

if [ -f dump.vcd ] ; then
    gtkwave dump.vcd --script gtkwave.tcl
fi

rm -f a.out
# rm -f dump.vcd

grep -e PASS -e FAIL -e error log.txt
