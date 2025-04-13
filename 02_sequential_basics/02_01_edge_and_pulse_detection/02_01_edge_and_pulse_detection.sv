//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module posedge_detector (input clk, rst, a, output detected);

  logic a_r;

  // Note:
  // The a_r flip-flop input value d propogates to the output q
  // only on the next clock cycle.

  always_ff @ (posedge clk)
    if (rst)
      a_r <= '0;
    else
      a_r <= a;

  assign detected = ~ a_r & a;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module one_cycle_pulse_detector (input clk, rst, a, output detected);

  // Task:
  // Create an one cycle pulse (010) detector.
  //
  // Note:
  // See the testbench for the output format ($display task).
  logic current_r;
  logic prev_r;

  always_ff @ (posedge clk)
    if (rst)
      begin
        current_r <= '0;
        prev_r    <= '0;
      end
    else
      begin
        prev_r <= current_r;
        current_r <= a;
      end

  assign detected = ~prev_r & current_r & ~a;
endmodule
