//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // States
  enum logic[1:0]
  {
     st_equal       = 2'b00,
     st_a_less_b    = 2'b01,
     st_a_greater_b = 2'b10
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    case (state)
      st_equal       : if (~ a &   b) new_state = st_a_less_b;
                  else if (  a & ~ b) new_state = st_a_greater_b;
      st_a_less_b    : if (  a & ~ b) new_state = st_a_greater_b;
      st_a_greater_b : if (~ a &   b) new_state = st_a_less_b;
    endcase
  end

  // Output logic
  assign a_eq_b      = (a == b) & (state == st_equal);
  assign a_less_b    = (~ a &   b) | (a == b & state == st_a_less_b);
  assign a_greater_b = (  a & ~ b) | (a == b & state == st_a_greater_b);

  always_ff @ (posedge clk)
    if (rst)
      state <= st_equal;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first_using_fsm
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
  // Implement a serial comparator module similar to the previus exercise
  // but use the Finite State Machine to evaluate the result.
  // Most significant bits arrive first.


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
  serial_comparator_least_significant_first_using_fsm scl(
    .a_less_b(scl_less),
    .a_eq_b(scl_eq),
    .a_greater_b(scl_greater),
    .*);
  serial_comparator_most_significant_first_using_fsm scm(
    .a_less_b(scm_less),
    .a_eq_b(scm_eq),
    .a_greater_b(scm_greater),
    .*);

  localparam n = 16;

  // Sequence of input values
  localparam [0 : n - 1] seq_a = 16'b0110_0100_1000_0010;
  localparam [0 : n - 1] seq_b = 16'b0110_0010_0110_0010;

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

      $display ("a %b, b %b, lst %b %b %b (expected %b %b %b), mst %b %b %b (expected %b %b %b)",
        a, b,
        scl_less, scl_eq, scl_greater,
        seq_scl_less[i], seq_scl_eq[i], seq_scl_greater[i],
        scm_less, scm_eq, scm_greater,
        seq_scm_less[i], seq_scm_eq[i], seq_scm_greater[i]);

      if ({scl_less, scl_eq, scl_greater} !== {seq_scl_less[i], seq_scl_eq[i], seq_scl_greater[i]}
          || {scm_less, scm_eq, scm_greater} !== {seq_scm_less[i], seq_scm_eq[i], seq_scm_greater[i]})
      begin
        $display ("%s FAIL - see log above", `__FILE__);
        $finish;
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
