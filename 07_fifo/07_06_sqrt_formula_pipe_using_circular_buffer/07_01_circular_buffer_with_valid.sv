//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module one_bit_wide_circular_buffer
# (
    parameter depth = 8
)
(
    input  clk,
    input  rst,

    input  in_data,
    output out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [depth - 1:0] data;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            data <= '0;
        else
            data [ptr] <= in_data;

    assign out_data = data [ptr];

endmodule

//----------------------------------------------------------------------------

module circular_buffer
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk)
        data [ptr] <= in_data;

    assign out_data  = data [ptr];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module circular_buffer_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input                in_valid,
    input  [width - 1:0] in_data,

    output               out_valid,
    output [width - 1:0] out_data
);

    // Insert here your solution from previous task.


endmodule
