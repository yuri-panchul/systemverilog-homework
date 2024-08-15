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


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

`define KV(key, value)="name=",$sformatf(":%b", value)

module testbench;

  logic clk;

  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

  logic rst;

  initial
  begin
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  end

  logic a, pd_detected, ocpd_detected;

  posedge_detector         pd   (.detected (pd_detected),   .*);
  one_cycle_pulse_detector ocpd (.detected (ocpd_detected), .*);

  localparam n = 16;

  // Sequence of input values
  localparam [0 : n - 1] seq_a                = 16'b1001011011110001;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_posedge          = 16'b1001010010000001;
  localparam [0 : n - 1] seq_one_cycle_pulse  = 16'b0100100000000000;

  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a [i];

      @ (posedge clk);

      $display ("%b %b (%b) %b (%b)",
        a,
        pd_detected,   seq_posedge         [i],
        ocpd_detected, seq_one_cycle_pulse [i]);

      if (   pd_detected   !== seq_posedge         [i]
          || ocpd_detected !== seq_one_cycle_pulse [i])
      begin
        $display("FAIL %s", `__FILE__);
        $display("++ INPUT    => {a:%b, i:%b, pd_detected:%b, seq_posedge[%i]:%b, ocpd_detected:%b, seq_one_cyle_plus[%i]:%b}",
                 a,
                 pd_detected, i, seq_posedge         [i],
                 ocpd_detected, i, seq_one_cycle_pulse [i]);
        if (pd_detected !== seq_posedge[i])
        // begin
        //   $display("++ FAILED => {pd_detected:%b, seq_posedge[%i]:%b}",
        //            pd_detected, i, seq_posedge[i],);
        // end
        // if (pd_detected !== seq_posedge[i])
        // begin
        //   $display("++ FAILED => {ocpd_detected:%b, seq_one_cyle_plus[%i]:%b}",
        //            ocpd_detected, i, seq_one_cycle_pulse[i]);
        // end
        $fatal(1, "Test Failed");
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
