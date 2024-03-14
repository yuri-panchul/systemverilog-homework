# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.push
lappend all_signals tb.pop
lappend all_signals tb.write_data
lappend all_signals tb.read_data
lappend all_signals tb.empty
lappend all_signals tb.full

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
