`include "../util.sv"

//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module fibonacci
(
  input               clk,
  input               rst,
  output logic [15:0] num
);

  logic [15:0] num2;

  always_ff @ (posedge clk)
    if (rst)
      { num, num2 } <= { 16'd1, 16'd1 };
    else
      { num, num2 } <= { num2, num + num2 };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module fibonacci_2
(
  input               clk,
  input               rst,
  output logic [15:0] num,
  output logic [15:0] num2
);

  // Task:
  // Implement a module that generates two fibonacci numbers per cycle


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  logic clk;

  initial
  begin
    clk = 0;

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

  logic [15:0] f1_num, f2_num, f2_num2;

  fibonacci   f1 (.num (f1_num), .*);
  fibonacci_2 f2 (.num (f2_num), .num2 (f2_num2), .*);

  localparam n = 10;

  logic [15:0] fifo1 [$], fifo2 [$];

  integer     round = 1;

  initial
  begin
    @ (negedge rst);
    // TODO: Why check both? Isn't fifo2 always twice the size of
    // fifo1? Let's use smaller so that n matches the number of
    // test you end up running.
    while (fifo1.size () < n)
    begin
      @ (posedge clk);

      fifo1.push_back (f1_num);
      fifo2.push_back (f2_num);
      fifo2.push_back (f2_num2);
    end

    while (fifo1.size () > 0 && fifo2.size () > 0)
    begin
      logic [15:0] expected, actual;

      expected = fifo1.pop_front ();
      actual = fifo2.pop_front ();

      if (expected !== actual)
      begin
        // TODO: We should try to get this to display as a table
        // of [ROUND | EXPECTED | ACTUAL ] for all n rounds. This
        // currently only displays the failing round.
        $display("FAIL %s", `__FILE__);
        $display("++ TEST     => {%s, %s, %s}",
                 `PD(round), `PD(expected), `PD(actual));
        $fatal(1, "Test Failed");
      end
      round += 1;
    end
    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
