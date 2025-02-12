module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input [ n_inputs - 1 : 0 ]  up_vlds,
    input [ n_inputs - 1 : 0 ]
          [ width    - 1 : 0 ]  up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

/*
Legend:
Module "put_in_order" has up_vlds and up_data inputs coming from a block of
non-pipeline calculators with variable latency.
This calculators receive data sequentially, one after another (in round-robin manner).
The variable latency of these calculators leads to the fact that
the order of the outputs is not matching to the order of the input data.

Task:
Restore order of the output data.

For some timing and schematic example see "Scheme for task.pdf" file.
*/


endmodule
