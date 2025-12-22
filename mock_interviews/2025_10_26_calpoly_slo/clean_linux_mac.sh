#!/bin/sh

rm -f */{log.txt,sim.out,dump.vcd}

echo Other files not from the repository that can be potentially deleted:
git clean -xdn
