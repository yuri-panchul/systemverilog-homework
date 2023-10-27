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
       black_boxes/*.sv                 \
       *.sv                             \
       -I testbenches testbenches/*.sv  \
             >> log.txt 2>&1            \
&& vvp a.out >> log.txt 2>&1

# gtkwave dump_03_04.vcd

rm -f a.out
# rm -f dump_03_04.vcd

grep -e PASS -e FAIL -e error log.txt
