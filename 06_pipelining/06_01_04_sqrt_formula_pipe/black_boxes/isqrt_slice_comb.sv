module isqrt_slice_comb
# (
    parameter [31:0] m = 32'h4000_0000
)
(
    input  [31:0] ix,
    input  [31:0] iy,
    output [31:0] ox,
    output [31:0] oy
);

    wire [31:0] b      = iy | m;
    wire        x_ge_b = ix >= b;

    assign ox = x_ge_b ? ix - b : ix;
    assign oy = (iy >> 1) | (x_ge_b ? m : 0);

endmodule
