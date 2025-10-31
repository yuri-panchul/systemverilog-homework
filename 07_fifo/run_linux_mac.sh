#!/bin/sh

for d in */ ;
do
    echo $d
    cd $d

    ./run_linux_mac.sh

    cd ..
done
