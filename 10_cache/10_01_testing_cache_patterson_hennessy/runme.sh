#!/bin/sh

iverilog -I../../common -g2005-sv *.sv
vvp a.out | tee log.txt
