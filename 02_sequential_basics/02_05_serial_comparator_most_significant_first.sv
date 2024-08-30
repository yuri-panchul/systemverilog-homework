`include "../util.sv"
//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  logic prev_a_eq_b, prev_a_less_b;

  assign a_eq_b      = prev_a_eq_b & (a == b);
  assign a_less_b    = (~ a & b) | (a == b & prev_a_less_b);
  assign a_greater_b = (~ a_eq_b) & (~ a_less_b);

  always_ff @ (posedge clk)
    if (rst)
    begin
      prev_a_eq_b   <= '1;
      prev_a_less_b <= '0;
    end
    else
    begin
      prev_a_eq_b   <= a_eq_b;
      prev_a_less_b <= a_less_b;
    end

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // Task:
  // Implement a module that compares two numbers in a serial manner.
  // The module inputs a and b are 1-bit digits of the numbers
  // and most significant bits are first.
  // The module outputs a_less_b, a_eq_b, and a_greater_b
  // should indicate whether a is less than, equal to, or greater than b, respectively.
  // The module should also use the clk and rst inputs.
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

  logic a, b;
  logic scl_less, scl_eq, scl_greater;
  logic scm_less, scm_eq, scm_greater;
  serial_comparator_least_significant_first scl(
    .a_less_b(scl_less),
    .a_eq_b(scl_eq),
    .a_greater_b(scl_greater),
    .*);
  serial_comparator_most_significant_first scm(
    .a_less_b(scm_less),
    .a_eq_b(scm_eq),
    .a_greater_b(scm_greater),
    .*);

  localparam n = 16;

  // Sequence of input values
  localparam [0 : n - 1] seq_a           = 16'b0110_0100_1000_0010;
  localparam [0 : n - 1] seq_b           = 16'b0110_0010_0110_0010;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_scl_less    = 16'b0000_0011_0111_1111;
  localparam [0 : n - 1] seq_scl_eq      = 16'b1111_1000_0000_0000;
  localparam [0 : n - 1] seq_scl_greater = 16'b0000_0100_1000_0000;

  localparam [0 : n - 1] seq_scm_less    = 16'b0000_0000_0000_0000;
  localparam [0 : n - 1] seq_scm_eq      = 16'b1111_1000_0000_0000;
  localparam [0 : n - 1] seq_scm_greater = 16'b0000_0111_1111_1111;

  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a[i];
      b <= seq_b[i];

      @ (posedge clk);

      if ({scl_less, scl_eq, scl_greater} !== {seq_scl_less[i], seq_scl_eq[i], seq_scl_greater[i]})
      begin
        $display("++ INPUT    => {%s, %s, %s}",
                 `PD(i), `PB(a), `PB(b));
        $display("++ TEST     => {%s, %s, %s, %s, %s, %s}",
                 `PB(scl_less), `PB(scl_eq), `PB(scl_greater),
                 `PB(seq_scl_less), `PB(seq_scl_eq), `PB(seq_scl_greater));
        $fatal(1, "Test Failed");
      end

      if ({scm_less, scm_eq, scm_greater} !== {seq_scm_less[i], seq_scm_eq[i], seq_scm_greater[i]})
        begin
          $display("++ INPUT    => {%s, %s, %s}",
                   `PD(i), `PB(a), `PB(b));
          $display("++ TEST     => {%s, %s, %s, %s, %s, %s}",
                   `PB(scm_less), `PB(scm_eq), `PB(scm_greater),
                   `PB(seq_scm_less), `PB(seq_scm_eq), `PB(seq_scm_greater));
          $fatal(1, "Test Failed");
        end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
