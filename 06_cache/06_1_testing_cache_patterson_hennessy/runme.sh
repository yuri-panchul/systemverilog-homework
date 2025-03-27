#!/bin/sh

iverilog -I../../common -g2005-sv *.sv
./a.out | tee log.txt
