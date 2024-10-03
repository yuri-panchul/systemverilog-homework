#!/bin/sh

rars_jar=rars1_6.jar

if command -v rars >/dev/null 2>&1
then
    rars_cmd=rars
else
    if ! command -v java >/dev/null 2>&1
    then
        echo "ERROR: java is not in the path or cannot be run."  \
             "java is needed to run RARS,"                       \
             "a RISC-V instruction set simulator."               \
             "You can install it using"                          \
             "'sudo apt-get install default-jre'"                \
             2>&1

        echo "Press enter"
        read enter
        exit 1
    fi

    rars_cmd="java -jar ../../bin/$rars_jar"
fi

$rars_cmd &
