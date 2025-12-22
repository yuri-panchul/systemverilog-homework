module gearbox_2_to_1
# (
  parameter width = 0
)
(
  input                    clk,
  input                    rst,

  input                    up_vld,    // upstream
  output                   up_rdy,
  input  [2 * width - 1:0] up_data,

  output                   down_vld,  // downstream
  input                    down_rdy,
  output [    width - 1:0] down_data
);


endmodule
