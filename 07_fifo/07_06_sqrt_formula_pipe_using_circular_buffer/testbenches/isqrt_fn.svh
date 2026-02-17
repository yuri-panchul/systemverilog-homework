// This example is written by Yuri Panchul
// The algorithm is from Hacker's Delight by Henry Warren

`ifndef ISQRT_FN_SVH
`define ISQRT_FN_SVH

function [15:0] isqrt_fn (input [31:0] x);

    logic [31:0] m, tx, ty, b;

    m  = 32'h4000_0000;
    tx = x;
    ty = 0;

    repeat (16)
    begin
        b  = ty |  m;
        ty = ty >> 1;

        if (tx >= b)
        begin
            tx = tx - b;
            ty = ty | m;
        end

        m = m >> 2;
    end

    return ty [15:0];

endfunction

`endif
