module flip_flop_fifo
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

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            rd_ptr <= '0;
            rd_ptr_odd_circle <= 1'b0;
        end
        else if (pop)
        begin
            if (rd_ptr == max_ptr)
            begin
                rd_ptr <= '0;
                rd_ptr_odd_circle <= ~ rd_ptr_odd_circle;
            end
            else
            begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    wire equal_ptrs = (wr_ptr == rd_ptr);

    assign empty = equal_ptrs & wr_ptr_odd_circle == rd_ptr_odd_circle;
    assign full  = equal_ptrs & wr_ptr_odd_circle != rd_ptr_odd_circle;

endmodule
