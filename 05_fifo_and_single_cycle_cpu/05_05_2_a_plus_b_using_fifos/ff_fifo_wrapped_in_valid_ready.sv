module ff_fifo_wrapped_in_valid_ready
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,

    input                up_valid,    // upstream
    output               up_ready,
    input  [width - 1:0] up_data,

    output               down_valid,  // downstream
    input                down_ready,
    output [width - 1:0] down_data
);

    wire fifo_push;
    wire fifo_pop;
    wire fifo_empty;
    wire fifo_full;

    assign up_ready   = ~ fifo_full;
    assign fifo_push  = up_valid & up_ready;

    assign down_valid = ~ fifo_empty;
    assign fifo_pop   = down_valid & down_ready;

    flip_flop_fifo
    # (.width (width), .depth (depth))
    fifo
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .push       ( fifo_push  ),
        .pop        ( fifo_pop   ),
        .write_data ( up_data    ),
        .read_data  ( down_data  ),
        .empty      ( fifo_empty ),
        .full       ( fifo_full  )
    );

endmodule
