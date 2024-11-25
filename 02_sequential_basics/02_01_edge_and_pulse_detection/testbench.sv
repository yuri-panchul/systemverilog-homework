`include "util.svh"

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
  localparam [n - 1:0] seq_a                = 16'b1000111001000100;

  // Expected sequence of correct output values
  localparam [n - 1:0] seq_posedge          = 16'b1000001001000100;
  localparam [n - 1:0] seq_one_cycle_pulse  = 16'b0000000010001000;

  initial
  begin
    `ifdef __ICARUS__
      // Uncomment the following line
      // to generate a VCD file and analyze it using GTKwave or Surfer

      // $dumpvars;
    `endif

    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a [i];

      @ (posedge clk);

      // TODO: Why are we testing pd_detected at all? We should limit to
      // only testing the things the student is working upon.

      if (   pd_detected   !== seq_posedge         [i]
          || ocpd_detected !== seq_one_cycle_pulse [i])
      begin
        $display("FAIL %s", `__FILE__);
        $display("++ INPUT    => {%s, %s}",
                 `PB(seq_a), `PB(seq_one_cycle_pulse));
        // TODO: This isn't great. It basically only list the first
        // instance of i that failed. We should consider writing out
        // the results of all i's and then only printing out the "table"
        // of results in the event that there is a failure.
        $display("++ TEST     => {%s, %s, %s}",
                 `PD(i), `PB(ocpd_detected), `PB(seq_one_cycle_pulse[i]));
        $finish(1);
      end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
