# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.cluster.imDataVld
lappend all_signals tb.cluster.romAddr
lappend all_signals tb.cluster.imData
lappend all_signals tb.cluster.g_cpu\[0\].cpu.pc
lappend all_signals tb.cluster.g_cpu\[0\].cpu.imDataVld
lappend all_signals tb.cluster.g_cpu\[0\].cpu.regData
lappend all_signals tb.cluster.g_cpu\[1\].cpu.pc
lappend all_signals tb.cluster.g_cpu\[2\].cpu.pc
lappend all_signals tb.cluster.g_cpu\[2\].cpu.imDataVld
lappend all_signals tb.cluster.g_cpu\[2\].cpu.regData

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
