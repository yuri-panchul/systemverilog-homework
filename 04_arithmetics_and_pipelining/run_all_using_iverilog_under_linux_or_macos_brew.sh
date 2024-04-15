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

for f in *.sv
do
       iverilog -g2005-sv $f >> log.txt 2>&1  \
    && vvp a.out             >> log.txt 2>&1

    if [ $run_lint = true ]
    then
        printf "==============================================\n\n" >> lint.txt
        printf "File: $f\n\n" >> lint.txt
        printf "==============================================\n\n" >> lint.txt

        verilator --lint-only -Wall --timing -Wno-MULTITOP \
        -Wno-DECLFILENAME -Wno-INITIALDLY $f >> lint.txt 2>&1

        sed -i '/- Verilator:/d' lint.txt
        sed -i '/- V e r i l a t i o n/d' lint.txt
    fi

    # gtkwave dump.vcd
done

rm -f a.out

grep -e PASS -e FAIL -e error log.txt

cd "04_07_10_sqrt_formula_pipe"
./run_all_using_iverilog_under_linux_or_macos_brew.sh
