module ff_fifo_with_reg_empty_full
# (
    parameter width = 8, depth = 10
)
(
    input                      clk,
    input                      rst,
    input                      push,
    input                      pop,
    input        [width - 1:0] write_data,
    output       [width - 1:0] read_data,
    output logic               empty,
    output logic               full
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth),
               counter_width = $clog2 (depth + 1);

    localparam [counter_width - 1:0] max_ptr = counter_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr_d, rd_ptr_d, wr_ptr_q, rd_ptr_q;
    logic empty_d, full_d;
    logic [width - 1:0] data [0: depth - 1];

    //------------------------------------------------------------------------

    always_comb
    begin

        // Example
        if (push)
            wr_ptr_d = wr_ptr_q == max_ptr ? '0 : wr_ptr_q + 1'b1;
        else
            wr_ptr_d = wr_ptr_q;

        // Task: Add logic for pop to make the FIFO work


        case ({ push, pop })

        // Example
        2'b10:
        begin
            empty_d = 1'b0;
            full_d  = wr_ptr_d == rd_ptr_q;
        end

        // Task: Add { push, pop } == 2'b01 case to make the FIFO work

        default:
        begin
            empty_d  = empty;
            full_d   = full;
        end
        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_ptr_q <= '0;
            rd_ptr_q <= '0;
            empty    <= 1'b1;
            full     <= 1'b0;
        end
        else
        begin
            wr_ptr_q <= wr_ptr_d;
            rd_ptr_q <= rd_ptr_d;
            empty    <= empty_d;
            full     <= full_d;
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr_q] <= write_data;

    assign read_data = data [rd_ptr_q];

endmodule
