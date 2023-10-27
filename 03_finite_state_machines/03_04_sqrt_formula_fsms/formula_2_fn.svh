`ifndef FORMULA_2_FN_SVH
`define FORMULA_2_FN_SVH

//----------------------------------------------------------------------------
// Header file defining the formula. DO NOT MODIFY
//----------------------------------------------------------------------------

`include "isqrt_fn.svh"

function [31:0] formula_2_fn
(
    input [31:0] a,
    input [31:0] b,
    input [31:0] c
);
    return isqrt_fn (a + isqrt_fn (b + isqrt_fn (c)));

endfunction

`endif
