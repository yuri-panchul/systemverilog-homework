#!/bin/sh

rm -rf log.txt

for f in *.sv
do
       iverilog -g2005-sv $f >> log.txt 2>&1  \
    && vvp a.out             >> log.txt 2>&1

    # gtkwave dump.vcd
done

rm -rf a.out

grep -e PASS -e FAIL -e error log.txt
