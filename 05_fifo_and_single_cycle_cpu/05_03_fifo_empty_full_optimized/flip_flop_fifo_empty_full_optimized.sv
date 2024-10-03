module flip_flop_fifo_empty_full_optimized
# (
    parameter width = 8, depth = 10
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

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth);
    localparam max_ptr       = pointer_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, rd_ptr;
    logic wr_ptr_odd_circle, rd_ptr_odd_circle;

    logic [width - 1:0] data [0: depth - 1];

    //------------------------------------------------------------------------
    // Example
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_ptr <= '0;
            wr_ptr_odd_circle <= 1'b0;
        end
        else if (push)
        begin
            if (wr_ptr == max_ptr)
            begin
                wr_ptr <= '0;
                wr_ptr_odd_circle <= ~ wr_ptr_odd_circle;
            end
            else
            begin
                wr_ptr <= wr_ptr + 1'b1;
            end
        end

    //------------------------------------------------------------------------
    // Task: Add logic for read pointer
    //------------------------------------------------------------------------

    // TODO: Add logic for rd_ptr

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    wire equal_ptrs  = (wr_ptr == rd_ptr);
    wire same_circle = (wr_ptr_odd_circle == rd_ptr_odd_circle);

    // Example
    assign empty = equal_ptrs & same_circle;

    // Task: Add logic for full output

endmodule
