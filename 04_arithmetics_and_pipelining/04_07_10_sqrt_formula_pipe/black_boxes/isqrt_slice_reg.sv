module isqrt_slice_reg
# (
    parameter [31:0] m = 32'h4000_0000
)
(
    input               clk,
    input               rst,

    input               ivld,
    input        [31:0] ix,
    input        [31:0] iy,

    output logic        ovld,
    output logic [31:0] ox,
    output logic [31:0] oy
);

    wire [31:0] cox, coy;

    isqrt_slice_comb # (.m (m)) inst
    (
        .ix ( ix  ),
        .iy ( iy  ),
        .ox ( cox ),
        .oy ( coy )
    );

    always_ff @ (posedge clk)
        if (rst)
            ovld <= 1'b0;
        else
            ovld <= ivld;

    always_ff @ (posedge clk)
        if (ivld)
        begin
            ox <= cox;
            oy <= coy;
        end

endmodule
