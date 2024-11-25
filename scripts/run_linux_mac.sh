#!/bin/sh

#-----------------------------------------------------------------------------

waveform_viewer="gtkwave"
# waveform_viewer="surfer"

#-----------------------------------------------------------------------------

find_common_path()
{
    common_path="../common"

    i=0

    while [ "$i" -lt 3 ]
    do
        [ -d $common_path ] && break
        common_path=../$common_path
        i=$((i + 1))
    done
}

#-----------------------------------------------------------------------------

find_import_path()
{
    import_path="../import/preprocessed/cvw"

    i=0

    while [ "$i" -lt 3 ]
    do
        [ -d $import_path ] && break
        import_path=../$import_path
        i=$((i + 1))
    done
}
#-----------------------------------------------------------------------------

import_files()
{
    import=$(echo $common_path | sed 's/common/import/g')

    if ! [ -d "$import/original/cvw" ]
    then
        mkdir -p "$import"
        git clone --depth 1 https://github.com/openhwgroup/cvw.git "$import/original/cvw"
    fi

    rm    -rf "$import/preprocessed"
    mkdir -p  "$import/preprocessed/cvw"

    cp -r  \
       "$import/original/cvw/config/rv32gc/config.vh"              \
       "$import/original/cvw/config/shared/BranchPredictorType.vh" \
       "$import/original/cvw/config/shared/config-shared.vh"       \
       "$import/original/cvw/src/fpu"/*/*                          \
       "$import/original/cvw/src/fpu"/*.*                          \
       "$import/original/cvw/src/generic"/*.*                      \
       "$import/original/cvw/src/generic/flop"/*.*                 \
       "$import/preprocessed/cvw"

    sed -i 's/#(P) //g' "$import/preprocessed/cvw/"*
    sed -i 's/P\./  /g' "$import/preprocessed/cvw/"*
    sed -i 's/import cvw::\*;  #(parameter cvw_t P) //g' "$import/preprocessed/cvw"/*

    sed -i 's/, parameter type TYPE=logic \[WIDTH-1:0\]//g' \
        "$import/preprocessed/cvw/flopenl.sv"

    sed -i 's/ TYPE / logic [WIDTH-1:0] /g' \
        "$import/preprocessed/cvw/flopenl.sv"

    sed -i 's/module fmalza #(WIDTH, NF) /module fmalza #(parameter WIDTH = 0, NF = 0) /g' \
        "$import/preprocessed/cvw/fmalza.sv"

    sed -i 's/(parameter FLEN)/(parameter FLEN=64)/g' \
        "$import/preprocessed/cvw/fregfile.sv"

    sed -i 's/ var / /g' \
        "$import/preprocessed/cvw/or_rows.sv"
}

#-----------------------------------------------------------------------------

simulate_rtl()
{
    find_common_path
    find_import_path

    if ! command -v iverilog > /dev/null 2>&1
    then
        printf "%s\n"                                                \
               "ERROR: Icarus Verilog (iverilog) is not in the path" \
               "or cannot be run."                                   \
               "See README.md file in the package directory"         \
               "for the instructions how to install Icarus."         \
               "Press enter"

        read -r enter
        exit 1
    fi

    rm -f dump.vcd
    rm -f log.txt

    if [ -d testbenches ]
    then
        iverilog -g2005-sv               \
                 -o sim.out              \
                 -I testbenches          \
                 -I $common_path         \
                 testbenches/*.sv        \
                 $common_path/isqrt/*.sv \
                 *.sv                    \
                 >> log.txt 2>&1         \
                 && vvp sim.out          \
                 >> log.txt 2>&1

        rm -f sim.out
    elif [ -f tb.sv ]
    then
        iverilog -g2005-sv       \
                 -o sim.out      \
                 *sv             \
                 >> log.txt 2>&1 \
                 && vvp sim.out  \
                 >> log.txt 2>&1

        rm -f sim.out
    else
        for d in */
        do
            if [ ! -d "$d"testbenches ]
            then

                if [ -f "$d"testbench.sv ] && grep -q "realtobits" "$d"testbench.sv;
                then

                    if [ ! -d $import_path ]
                    then
                        printf "You need to import external files in order to do %s.\n" "$d"
                        printf "Needed files are located at https://github.com/openhwgroup/cvw\n"
                        printf "Clone third-party repository from GitHub? [y/N] "

                        read -r input

                        if [ "$input" = "y" ] || [ "$input" = "Y" ]
                        then
                            import_files
                            find_import_path
                        else
                            continue
                        fi
                    fi

                    iverilog -g2005-sv                   \
                             -o "$d"sim.out              \
                             -I $import_path             \
                             -I $common_path             \
                             $import_path/config.vh      \
                             $import_path/*.sv           \
                             $common_path/wally_fpu/*.sv \
                             "$d"*.sv                    \
                             >> log.txt 2>&1             \
                             && vvp "$d"sim.out          \
                             >> log.txt 2>&1
                else
                    iverilog -g2005-sv                   \
                             -o "$d"sim.out              \
                             -I $common_path             \
                             "$d"*.sv                    \
                             >> log.txt 2>&1             \
                             && vvp "$d"sim.out          \
                             >> log.txt 2>&1
                fi

                rm -f "$d"sim.out
            fi
        done
    fi

    # Don't print iverilog warning about not supporting constant selects
    sed -i '/sorry: constant selects/d' log.txt
    # Don't print $finish calls to make log cleaner
    sed -i '/finish called/d' log.txt
}

#-----------------------------------------------------------------------------

lint_code()
{
    find_common_path
    find_import_path

    lint_rules_path="../.lint_rules.vlt"

    if command -v verilator > /dev/null 2>&1
    then
        i=0

        while [ "$i" -lt 3 ]
        do
            [ -f $lint_rules_path ] && break
            lint_rules_path=../$lint_rules_path
            i=$((i + 1))
        done

        if ! [ -f $lint_rules_path ]
        then
            printf "%s\n"                                             \
                   "ERROR: Config file for Verilator cannot be found" \
                   "Press enter"

            read -r enter
            exit 1
        else
            rm -f lint.txt

            if [ -d testbenches ]
            then
                verilator --lint-only      \
                          -Wall            \
                          --timing         \
                          $lint_rules_path \
                          -Itestbenches    \
                          -I$common_path   \
                          testbenches/*.sv \
                          *.sv             \
                          -top tb          \
                          >> lint.txt 2>&1

            elif [ -f tb.sv ]
            then
                verilator --lint-only      \
                          -Wall            \
                          --timing         \
                          $lint_rules_path \
                          -I$common_path   \
                          *.sv             \
                          -top tb          \
                          >> lint.txt 2>&1
            else
                for d in */
                do
                    if [ ! -d "$d"testbenches ]
                    then
                        {
                            printf "==============================================================\n"
                            printf "Task: %s\n" "$d"
                            printf "==============================================================\n\n"
                        } >> lint.txt

                        if [ -f "$d"testbench.sv ] && grep -q "realtobits" "$d"testbench.sv;
                        then
                            extra_args="-I$import_path -y $import_path/wally_fpu"
                        fi

                        verilator --lint-only                \
                                  -Wall                      \
                                  --timing                   \
                                  $lint_rules_path           \
                                  $extra_args                \
                                  -I$import_path             \
                                  -y $import_path/wally_fpu  \
                                  "$d"*.sv                   \
                                  -top testbench             \
                                  >> lint.txt 2>&1
                    fi
                done
            fi

            sed -i '/- Verilator:/d' lint.txt
            sed -i '/- V e r i l a t i o n/d' lint.txt
        fi
    else
        printf "%s\n"                                                             \
               "ERROR [-l | --lint]: Verilator is not in the path"                \
               "or cannot be run."                                                \
               "See README.md file in the package directory for the instructions" \
               "how to install Verilator."                                        \
               "Press enter"

        read -r enter
        exit 1
    fi
}

#-----------------------------------------------------------------------------

run_assembly()
{
    rars_jar=rars1_6.jar

    #  nc                              - Copyright notice will not be displayed
    #  a                               - assembly only, do not simulate
    #  ae<n>                           - terminate RARS with integer exit code if an assemble error occurs
    #  dump .text HexText program.hex  - dump segment .text to program.hex file in HexText format

    rars_args="nc a ae1 dump .text HexText program.hex"

    if command -v rars > /dev/null 2>&1
    then
        rars_cmd=rars
    else
        if ! command -v java > /dev/null 2>&1
        then
            printf "%s\n"                                             \
                   "ERROR: java is not in the path or cannot be run." \
                   "java is needed to run RARS,"                      \
                   "a RISC-V instruction set simulator."              \
                   "You can install it using"                         \
                   "'sudo apt-get install default-jre'"               \
                   "Press enter"

            read -r enter
            exit 1
        fi

        rars_cmd="java -jar ../../bin/$rars_jar"
    fi

    if ! $rars_cmd $rars_args program.s >> log.txt 2>&1
    then
        printf "ERROR: assembly failed. See log.txt.\n"
        grep Error log.txt
        printf "Press enter\n"
        read -r enter
        exit 1
    fi
}

#-----------------------------------------------------------------------------

open_waveform()
{
    if [ -f dump.vcd ]
    then

        if [ "$waveform_viewer" = "gtkwave" ]
        then
            if [ -f gtkwave.tcl ]
            then
                gtkwave dump.vcd --script gtkwave.tcl &
            else
                gtkwave dump.vcd &
            fi
        elif [ "$waveform_viewer" = "surfer" ]
        then
            if [ -f state.ron ]
            then
                surfer dump.vcd --state-file state.ron &
            else
                surfer dump.vcd &
            fi
        fi

    else
        printf "No dump.vcd file found\n"
        printf "Check that it's generated in testbench for this exercise\n\n"
    fi
}

#-----------------------------------------------------------------------------

if [ -f program.s ] ; then
    run_assembly
fi

simulate_rtl

while getopts ":lw-:" opt
do
    case $opt in
        -)
            case $OPTARG in
                lint)
                    lint_code;;
                wave)
                    open_waveform;;
                *)
                    printf "ERROR: Unknown option\n"
                    printf "Press enter\n"
                    read -r enter
                    exit 1
            esac;;
        l)
            lint_code;;
        w)
            open_waveform;;
        ?)
            printf "ERROR: Unknown option\n"
            printf "Press enter\n"
            read -r enter
            exit 1;;
    esac
done

#-----------------------------------------------------------------------------

grep -e PASS -e FAIL -e ERROR -e Error -e error -e Timeout -e ++ log.txt \
    | sed -e 's/PASS/\x1b[0;32m&\x1b[0m/g' -e 's/FAIL/\x1b[0;31m&\x1b[0m/g'
