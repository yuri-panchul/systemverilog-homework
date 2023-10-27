// This example is written by Yuri Panchul
// The algorithm is from Hacker's Delight by Henry Warren

// pipelined with configurable number of stages

module isqrt
# (
    parameter n_pipe_stages = 16
)
(
    input         clk,
    input         rst,

    input         x_vld,
    input  [31:0] x,

    output        y_vld,
    output [15:0] y
);

    localparam n_slices           = 16;
    localparam n_slices_per_stage = n_slices / n_pipe_stages;

    localparam [31:0] m = 32'h4000_0000;

    wire [31:0] ix [0:15], iy [0:15];
    wire [31:0] ox [0:15], oy [0:15];

    wire [15:0] ivld, ovld;

    generate
        genvar i;

        for (i = 0; i < 16; i = i + 1)
        begin : u
            if (i % n_slices_per_stage != n_slices_per_stage - 1)
            begin
                isqrt_slice_comb #(.m (m >> (i * 2))) inst
                (
                    .ix  ( ix [i] ),
                    .iy  ( iy [i] ),
                    .ox  ( ox [i] ),
                    .oy  ( oy [i] )
                );

                assign ovld [i] = ivld [i];
            end
            else
            begin
                isqrt_slice_reg #(.m (m >> (i * 2))) inst
                (
                    .clk  ( clk      ),
                    .rst  ( rst      ),

                    .ivld ( ivld [i] ),
                    .ix   ( ix   [i] ),
                    .iy   ( iy   [i] ),

                    .ovld ( ovld [i] ),
                    .ox   ( ox   [i] ),
                    .oy   ( oy   [i] )
                );
            end
        end

        for (i = 1; i < 16; i = i + 1)
        begin : v
            assign ivld [i] = ovld [i - 1];
            assign ix   [i] = ox   [i - 1];
            assign iy   [i] = oy   [i - 1];
        end

    endgenerate

    assign ivld [0] = x_vld;
    assign ix   [0] = x;
    assign iy   [0] = 0;

    assign y_vld = ovld [15];
    assign y     = oy   [15];

endmodule
