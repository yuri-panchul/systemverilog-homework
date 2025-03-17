#!/bin/sh

iverilog -g2012 -D LOCAL_TB \
-I .. \
-I ../../import/preprocessed/cvw \
../../import/preprocessed/cvw/config.vh \
../../import/preprocessed/cvw/*.sv \
*.sv \
-s fpu_tb \
2>&1 | grep -v sorry

./a.out > z
rm -rf a.out
