// This solution is a Yuri Panchul's edition
// of the code derived from:
//
// Digital Design: A Systems Approach
// by William James Dally and R. Curtis Harting
// 2012

module double_buffer_from_dally_harting
# (
    parameter width = 0
)
(
    input                      clk,
    input                      rst,

    input                      up_valid,
    output logic               up_ready,
    input        [width - 1:0] up_data,

    output logic               down_valid,
    input                      down_ready,
    output logic [width - 1:0] down_data
);

    logic               enable;
    logic               buf_valid;
    logic [width - 1:0] buf_data;

    assign enable = down_ready | ~down_valid;

    always_ff @ (posedge clk)
    begin
        if (up_ready & ~enable)
            buf_data <= up_data;

        if (enable)
            down_data <= up_ready ? up_data : buf_data;
    end

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            buf_valid  <= 1'b0;
            down_valid <= 1'b0;
            up_ready   <= 1'b1;
        end
        else
        begin
            if (up_ready & ~enable)
                buf_valid  <= up_valid;

            if (enable)
                down_valid <= up_ready ? up_valid : buf_valid;

            up_ready <= enable;
        end

endmodule
