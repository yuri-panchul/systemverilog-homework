module ff_fifo_pow2_depth
# (
    parameter width = 0, depth = 0
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [width - 1:0] write_data,
    output [width - 1:0] read_data,
    output               empty,
    output               full
);

    localparam pointer_width          = $clog2 (depth),
               extended_pointer_width = pointer_width + 1;

    `ifndef SYNTHESIS
    // Check that the depth is truly a power of two
    initial assert ((1 << pointer_width) == depth);
    `endif

    logic [extended_pointer_width - 1:0] ext_wr_ptr, ext_rd_ptr;

    wire [pointer_width - 1:0] wr_ptr = ext_wr_ptr [pointer_width - 1:0];
    wire [pointer_width - 1:0] rd_ptr = ext_rd_ptr [pointer_width - 1:0];

    logic [width - 1:0] data [0: depth - 1];

    //--------------------------------------------------------------------------

    // Example
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ext_wr_ptr <= '0;
        else if (push)
            ext_wr_ptr <= ext_wr_ptr + 1'b1;

    // Task: Add logic for ext_rd_ptr

    //--------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //--------------------------------------------------------------------------

    // Example
    assign full =   rd_ptr == wr_ptr
                  & ext_rd_ptr [pointer_width] != ext_wr_ptr [pointer_width];

    // Task: Add logic for empty output using full as an example

endmodule
