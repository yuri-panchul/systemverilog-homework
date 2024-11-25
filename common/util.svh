`define PD(SYMBOL) $sformatf("SYMBOL:%0d", SYMBOL)
`define PB(SYMBOL) $sformatf("SYMBOL:%b", SYMBOL)
`define PH(SYMBOL) $sformatf("SYMBOL:%h", SYMBOL)
`define PF(SYMBOL) $sformatf("SYMBOL:%f", SYMBOL)

`define PF_BITS(SYMBOL) $sformatf("SYMBOL:%f", $bitstoreal(SYMBOL))
`define PG_BITS(SYMBOL) $sformatf("SYMBOL:%g", $bitstoreal(SYMBOL))

`ifdef __ICARUS__
    `define ISUNKNOWN(a) ((^ a) === 1'bx)
`else
    `define ISUNKNOWN(a) $isunknown(a)
`endif
