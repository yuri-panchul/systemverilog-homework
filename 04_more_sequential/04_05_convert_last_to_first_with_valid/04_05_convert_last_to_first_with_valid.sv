//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_last_to_first
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_last,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_first,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'last' input status signal
    // to the 'first' output status signal.
    //
    // See README for full description of the task with timing diagram.


endmodule
