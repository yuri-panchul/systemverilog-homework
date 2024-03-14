#!/bin/sh

for d in *
do
    if [ -d $d ] ; then
        echo $d
        cd $d

        if [ -f run_using_iverilog_under_linux_or_macos_brew.sh ] ; then
            ./run_using_iverilog_under_linux_or_macos_brew.sh
        else
            ./run_all_using_iverilog_under_linux_or_macos_brew.sh
        fi

        cd ..
    fi
done
