//----------------------------------------------------------------------------
// Top file wiring everything together. DO NOT MODIFY
//----------------------------------------------------------------------------

module formula_1_impl_2_top
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    wire        isqrt_1_x_vld;
    wire [31:0] isqrt_1_x;

    wire        isqrt_1_y_vld;
    wire [15:0] isqrt_1_y;

    wire        isqrt_2_x_vld;
    wire [31:0] isqrt_2_x;

    wire        isqrt_2_y_vld;
    wire [15:0] isqrt_2_y;

    formula_1_impl_2_fsm i_formula_1_impl_2_fsm (.*);

    isqrt i_isqrt_1
    (
        .clk   ( clk           ),
        .rst   ( rst           ),
        .x_vld ( isqrt_1_x_vld ),
        .x     ( isqrt_1_x     ),
        .y_vld ( isqrt_1_y_vld ),
        .y     ( isqrt_1_y     )
    );

    isqrt i_isqrt_2
    (
        .clk   ( clk           ),
        .rst   ( rst           ),
        .x_vld ( isqrt_2_x_vld ),
        .x     ( isqrt_2_x     ),
        .y_vld ( isqrt_2_y_vld ),
        .y     ( isqrt_2_y     )
    );

endmodule
