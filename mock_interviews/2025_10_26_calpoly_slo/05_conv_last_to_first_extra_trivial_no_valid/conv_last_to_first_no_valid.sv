module conv_last_to_first_no_valid
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_last,
    input  [width - 1:0] up_data,

    output               down_first,
    output [width - 1:0] down_data
);


endmodule
