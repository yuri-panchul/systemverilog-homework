module gearbox_1_to_2
# (
  parameter width = 0
)
(
  input                    clk,
  input                    rst,

  input                    up_vld,    // upstream
  output                   up_rdy,
  input  [    width - 1:0] up_data,

  output                   down_vld,  // downstream
  input                    down_rdy,
  output [2 * width - 1:0] down_data
);


endmodule
