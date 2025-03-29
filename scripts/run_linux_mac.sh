#!/bin/sh

#-----------------------------------------------------------------------------

waveform_viewer="gtkwave"
# waveform_viewer="surfer"

#-----------------------------------------------------------------------------
# Utility functions
#-----------------------------------------------------------------------------

find_path()
{
    search_path=$1
    i=0

    while [ "$i" -lt 3 ]
    do
        [ -d "$search_path" ] && break
        search_path=../$search_path
        i=$((i + 1))
    done

    if [ -d "$search_path" ]
    then
        echo "$search_path"
    else
        echo "none"
    fi
}

#-----------------------------------------------------------------------------

import_files()
{
    import=$(echo "$1" | sed -e 's/common/import/g')

    if ! [ -d "$import/original/cvw" ]
    then
        mkdir -p "$import"
        git clone --depth 1 https://github.com/openhwgroup/cvw.git "$import/original/cvw"
    fi

    rm    -rf "$import/preprocessed"
    mkdir -p  "$import/preprocessed/cvw"

    # "$import/original/cvw/src/cache"/*.*                        \
    # "$import/original/cvw/src/generic/mem/ram1p1rwbe.sv"        \
    # "$import/original/cvw/src/generic/mem/ram1p1rwe.sv"         \

    cp -r  \
       "$import/original/cvw/config/rv32gc/config.vh"              \
       "$import/original/cvw/config/shared/BranchPredictorType.vh" \
       "$import/original/cvw/config/shared/config-shared.vh"       \
       "$import/original/cvw/src/fpu"/*/*                          \
       "$import/original/cvw/src/fpu"/*.*                          \
       "$import/original/cvw/src/generic"/*.*                      \
       "$import/original/cvw/src/generic/flop"/*.*                 \
       "$import/preprocessed/cvw"

    sed -i -e 's/#(P) //g' "$import/preprocessed/cvw/"*
    sed -i -e 's/P\./  /g' "$import/preprocessed/cvw/"*
    sed -i -e 's/import cvw::\*;  #(parameter cvw_t P) //g' "$import/preprocessed/cvw"/*
    sed -i -e '/import cvw::\*; #(parameter cvw_t P,[[:space:]]*$/{N;s/import cvw::\*; #(parameter cvw_t P,[[:space:]]*\n[[:space:]]*/#(/}' "$import/preprocessed/cvw"/*
    sed -i -e 's/\(cacheway #(\)P, /\1/' "$import/preprocessed/cvw"/*
    sed -i -e 's/import cvw::\*[[:space:]]*; //' "$import/preprocessed/cvw"/*

    sed -i -e 's/, parameter type TYPE=logic \[WIDTH-1:0\]//g' \
        "$import/preprocessed/cvw/flopenl.sv"

    sed -i -e 's/ TYPE / logic [WIDTH-1:0] /g' \
        "$import/preprocessed/cvw/flopenl.sv"

    sed -i -e 's/module fmalza #(WIDTH, NF) /module fmalza #(parameter WIDTH = 0, NF = 0) /g' \
        "$import/preprocessed/cvw/fmalza.sv"

    sed -i -e 's/(parameter FLEN)/(parameter FLEN=64)/g' \
        "$import/preprocessed/cvw/fregfile.sv"

    sed -i -e 's/ var / /g' \
        "$import/preprocessed/cvw/or_rows.sv"
}

#-----------------------------------------------------------------------------

run_icarus()
{
    extra_args=$1

    # $extra_args has to be unquoted here, otherwise it would pass as a single argument
    # shellcheck disable=SC2086
    iverilog -g2012                  \
             -o sim.out              \
             $extra_args             \
             >> log.txt 2>&1         \
             && vvp sim.out          \
             >> log.txt 2>&1

}

#-----------------------------------------------------------------------------

run_verilator()
{
    extra_args=$1

    # $extra_args has to be unquoted here, otherwise it would pass as a single argument
    # shellcheck disable=SC2086
    verilator --lint-only      \
              -Wall            \
              --timing         \
              $lint_rules_path \
              $extra_args      \
              >> lint.txt 2>&1

}

#-----------------------------------------------------------------------------

prompt_to_clone_if_repo_not_found()
{
    common_path=$1
    import_path=$(find_path "../import/preprocessed/cvw")

    if [ "$import_path" = "none" ]
    then
        printf "You need to import external files in order to verify some exercises.\n"
        printf "Needed files are located at https://github.com/openhwgroup/cvw\n"
        printf "Clone third-party repository from GitHub? [y/N] "

        read -r input

        if [ "$input" = "y" ] || [ "$input" = "Y" ]
        then
            import_files "$common_path"
            find_path "../import/preprocessed/cvw"
        else
            return 1
        fi
    fi
    return 0
}

#-----------------------------------------------------------------------------

check_iverilog_executable()
{
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
}

#-----------------------------------------------------------------------------

check_verilator_setup()
{
    if ! command -v verilator > /dev/null 2>&1
    then
        printf "%s\n"                                                             \
               "ERROR [-l | --lint]: Verilator is not in the path"                \
               "or cannot be run."                                                \
               "See README.md file in the package directory for the instructions" \
               "how to install Verilator."                                        \
               "Press enter"

        read -r enter
        exit 1
    fi

    lint_rules_path="../.lint_rules.vlt"
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
    fi
}

#-----------------------------------------------------------------------------

prepare_wally_env()
{
    choice=$1
    if [ "$choice" -eq 0 ]
    then
        prompt_to_clone_if_repo_not_found "$common_path"
        choice=$?

        if [ $choice -eq 0 ]
        then
            extra_args="$extra_args
                        -I $import_path
                        -I $common_path
                        $import_path/config.vh
                        $import_path/*.sv
                        $common_path/wally_fpu/*.sv
                        $d*.sv"
        fi
    fi

    return "$choice"
}

#-----------------------------------------------------------------------------
# Main functions
#-----------------------------------------------------------------------------

simulate_rtl()
{
    check_iverilog_executable

    rm -f sim.out
    rm -f dump.vcd
    rm -f log.txt

    common_path=$(find_path "../common")
    extra_args=""
    choice=0

    if [ -f tb.sv ]
    then
        # Testbench is in the same directory with the script (HW 05)
        extra_args="$extra_args ./*.sv"
        run_icarus "$extra_args"
    elif [ -d "testbenches" ]
    then
        # It is isqrt exercise
        extra_args="$extra_args
                    -I $common_path
                    -I testbenches
                    testbenches/*.sv
                    $common_path/isqrt/*.sv
                    *.sv"

        run_icarus "$extra_args"
    else
        # Enter each directory in homework
        for d in */
        do
            extra_args=""

            if [ -d "$d"testbenches ]
            then
            # It is isqrt exercise
            extra_args="$extra_args
                        -I $common_path
                        -I $d
                        -I ${d}testbenches
                        ${d}testbenches/*.sv
                        $common_path/isqrt/*.sv
                        $d*.sv"
            # elif [ -f "$d"testbench.sv ] && grep -q "realtobits\|cache" "$d"testbench.sv;
            elif [ -f "$d"testbench.sv ] && grep -q "realtobits" "$d"testbench.sv;
            then
                # It is an exercise with Wally CPU blocks
                prepare_wally_env "$choice"

                # Don't add solution_submodules if we haven't imported Wally CPU
                if [ -d "$d"solution_submodules ] && [ "$choice" -eq 0 ]
                then
                    extra_args="$extra_args
                                -I  ${d}solution_submodules
                                ${d}solution_submodules/*.sv"
                fi

            else
                # It is a regular exercise with a testbench in each dir
                extra_args="$extra_args
                            -I $common_path
                            $d*.sv"
            fi
            # Run icarus with specific arguments
            run_icarus "$extra_args"
        done
    fi

    # Don't print iverilog warning about not supporting constant selects
    sed -i -e '/sorry: constant selects/d' log.txt
    # Don't print $finish calls to make log cleaner
    sed -i -e '/finish called/d' log.txt
}

#-----------------------------------------------------------------------------

lint_code()
{
    common_path=$(find_path "../common")
    check_verilator_setup

    rm -f lint.txt

    extra_args="-I$common_path"

    if [ -f tb.sv ]
    then
        extra_args="$extra_args
                    *.sv
                    -top tb"

        run_verilator "$extra_args"
    elif [ -d testbenches ]
    then
        extra_args="$extra_args
                    -I$common_path/isqrt
                    -Itestbenches
                    testbenches/*.sv
                    *.sv
                    -top tb"

        run_verilator "$extra_args"
    else
        for d in */
        do
            extra_args="-I$common_path"

            {
                printf "==============================================================\n"
                printf "Task: %s\n" "$d"
                printf "==============================================================\n\n"
            } >> lint.txt

            if [ -d "$d"testbenches ]
            then
                extra_args="$extra_args
                            -I$common_path/isqrt
                            -I${d}testbenches
                            -I${d}
                            ${d}testbenches/*.sv
                            ${d}*.sv
                            -top tb"
            else
                # if [ -f "$d"testbench.sv ] && grep -q "realtobits\|cache" "$d"testbench.sv;
                if [ -f "$d"testbench.sv ] && grep -q "realtobits" "$d"testbench.sv;
                then
                    import_path=$(find_path "../import/preprocessed/cvw")

                    if [ "$import_path" = "none" ]
                    then
                        continue
                    fi

                    if [ -d "$d"solution_submodules ]
                    then
                        extra_args="$extra_args
                                    -I  ${d}solution_submodules
                                    ${d}solution_submodules/*.sv"
                    fi

                    extra_args="$extra_args
                                -I$import_path
                                $import_path/config.vh
                                -y $common_path/wally_fpu/*.sv
                                -y $import_path/wally_fpu"
                fi

                extra_args="$extra_args
                            ${d}*.sv
                            -top testbench"
            fi

            run_verilator "$extra_args"
        done
    fi

    sed -i -e '/- Verilator:/d' lint.txt
    sed -i -e '/- V e r i l a t i o n/d' lint.txt
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

    # $rars_args has to be unquoted in order to pass as multiple arguments
    # shellcheck disable=SC2086
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
# Main logic
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
            # shellcheck disable=SC2034
            read -r enter
            exit 1;;
    esac
done

grep -e PASS -e FAIL -e ERROR -e Error -e error -e Timeout -e ++ log.txt \
    | sed -e 's/PASS/\x1b[0;32m&\x1b[0m/g' -e 's/FAIL/\x1b[0;31m&\x1b[0m/g'
