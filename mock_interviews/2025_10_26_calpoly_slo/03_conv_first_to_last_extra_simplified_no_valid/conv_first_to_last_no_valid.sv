module conv_first_to_last_no_valid
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_first,
    input  [width - 1:0] up_data,

    output               down_last,
    output [width - 1:0] down_data
);


endmodule
