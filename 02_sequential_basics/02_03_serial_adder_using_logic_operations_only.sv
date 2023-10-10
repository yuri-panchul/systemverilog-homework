//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_adder
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output sum
);

  // Note:
  // carry_d represents the cominational data input to the carry register.

  logic carry;
  wire carry_d;

  assign { carry_d, sum } = a + b + carry;

  always_ff @ (posedge clk)
    if (rst)
      carry <= '0;
    else
      carry <= carry_d;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_adder_using_logic_operations_only
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output sum
);

  // Task:
  // Implement a serial adder using only ^ (XOR), | (OR), & (AND), ~ (NOT) bitwise operations.
  //
  // Notes:
  // See Harris & Harris book
  // or https://en.wikipedia.org/wiki/Adder_(electronics)#Full_adder webpage
  // for information about the 1-bit full adder implementation.
  //
  // See the testbench for the output format ($display task).


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

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

  logic a, b, sa_sum, salo_sum;
  serial_adder                             sa   (.sum (sa_sum),   .*);
  serial_adder_using_logic_operations_only salo (.sum (salo_sum), .*);

  localparam n = 16;

  // Sequence of input values
  localparam [0 : n - 1] seq_a        = 16'b0100_1001_1000_0001;
  localparam [0 : n - 1] seq_b        = 16'b0010_1010_1000_0100;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_sa_sum   = 16'b0110_0111_0100_0101;
  localparam [0 : n - 1] seq_salo_sum = 16'b0110_0111_0100_0101;

  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a [i];
      b <= seq_b [i];

      @ (posedge clk);

      $display ("%b %b %b (%b) %b (%b)",
        a, b,
        sa_sum,   seq_sa_sum   [i],
        salo_sum, seq_salo_sum [i]);

      if (   sa_sum   !== seq_sa_sum   [i]
          || salo_sum !== seq_salo_sum [i])
      begin
        $display ("%s FAIL - see log above", `__FILE__);
        $finish;
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
