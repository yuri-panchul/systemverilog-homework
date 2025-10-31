`ifndef FORMULA_1_FN_SVH
`define FORMULA_1_FN_SVH

//----------------------------------------------------------------------------
// Header file defining the formula. DO NOT MODIFY
//----------------------------------------------------------------------------

`include "isqrt_fn.svh"

function [31:0] formula_1_fn
(
    input [31:0] a,
    input [31:0] b,
    input [31:0] c
);
    return 32' (isqrt_fn (a)) + 32' (isqrt_fn (b)) + 32' (isqrt_fn (c));

endfunction

`endif
