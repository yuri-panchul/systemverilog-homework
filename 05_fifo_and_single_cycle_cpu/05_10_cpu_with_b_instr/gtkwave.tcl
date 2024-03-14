# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.cpu.pc
lappend all_signals tb.imAddr
lappend all_signals tb.imData
lappend all_signals tb.regAddr
lappend all_signals tb.regData

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
