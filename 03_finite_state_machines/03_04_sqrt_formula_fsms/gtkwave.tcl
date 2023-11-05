# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.clk
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.rst
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.arg_vld
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.a
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.b
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.c
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.isqrt_x_vld
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.isqrt_x
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.isqrt_y_vld
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.isqrt_y
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.res_vld
lappend all_signals tb.formula_1_impl_1_tb.if_1_1.i_formula_1_impl_1_top.res

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
