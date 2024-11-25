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

  task reset();
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  endtask

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

  wire [n - 1:0] seq_a           [3];
  wire [n - 1:0] seq_b           [3];

  wire [n - 1:0] seq_scl_less    [3];
  wire [n - 1:0] seq_scl_eq      [3];
  wire [n - 1:0] seq_scl_greater [3];

  wire [n - 1:0] seq_scm_less    [3];
  wire [n - 1:0] seq_scm_eq      [3];
  wire [n - 1:0] seq_scm_greater [3];


  // Sequence of input values
  assign seq_a           [0] = 16'b0100_0001_0010_0110;
  assign seq_b           [0] = 16'b0100_0110_0100_0110;

  // Expected sequence of correct output values
  // LSB comes first
  assign seq_scl_less    [0] = 16'b1111_1110_1100_0000;
  assign seq_scl_eq      [0] = 16'b0000_0000_0001_1111;
  assign seq_scl_greater [0] = 16'b0000_0001_0010_0000;

  // MSB comes first
  assign seq_scm_less    [0] = 16'b0000_0000_0000_0000;
  assign seq_scm_eq      [0] = 16'b0000_0000_0001_1111;
  assign seq_scm_greater [0] = 16'b1111_1111_1110_0000;

  //---------------------------------------------------------------------------

  // Sequence of input values
  assign seq_a           [1] = 16'b0100_0001_0000_0110;
  assign seq_b           [1] = 16'b0101_0110_0100_0110;

  // Expected sequence of correct output values
  assign seq_scl_less    [1] = 16'b1111_1110_1100_0000;
  assign seq_scl_eq      [1] = 16'b0000_0000_0011_1111;
  assign seq_scl_greater [1] = 16'b0000_0001_0000_0000;

  assign seq_scm_less    [1] = 16'b1111_1111_1100_0000;
  assign seq_scm_eq      [1] = 16'b0000_0000_0011_1111;
  assign seq_scm_greater [1] = 16'b0000_0000_0000_0000;

  //---------------------------------------------------------------------------

  // Sequence of input values
  // equal numbers case
  assign seq_a           [2] = 16'b0100_0111_0010_0110;
  assign seq_b           [2] = 16'b0100_0111_0010_0110;

  // Expected sequence of correct output values
  assign seq_scl_less    [2] = 16'b0000_0000_0000_0000;
  assign seq_scl_eq      [2] = 16'b1111_1111_1111_1111;
  assign seq_scl_greater [2] = 16'b0000_0000_0000_0000;

  assign seq_scm_less    [2] = 16'b0000_0000_0000_0000;
  assign seq_scm_eq      [2] = 16'b1111_1111_1111_1111;
  assign seq_scm_greater [2] = 16'b0000_0000_0000_0000;

  //---------------------------------------------------------------------------

  initial
  begin
    `ifdef __ICARUS__
      // Uncomment the following line
      // to generate a VCD file and analyze it using GTKwave or Surfer

      // $dumpvars;
    `endif

    for (int i = 0; i < 3; i ++)
    begin
      reset();

      for (int j = 0; j < n; j ++)
      begin
        a <= seq_a[i][j];
        b <= seq_b[i][j];

        @ (posedge clk);

        if ({scl_less, scl_eq, scl_greater} !== {seq_scl_less[i][j], seq_scl_eq[i][j], seq_scl_greater[i][j]})
        begin
          $display("FAIL %s", `__FILE__);
          $display("++ INPUT    => {%s, %s, %s}",
                   `PD(j), `PB(a), `PB(b));
          $display("++ TEST     => {%s, %s, %s} != {%s, %s, %s}",
                   `PB(scl_less), `PB(scl_eq), `PB(scl_greater),
                   `PB(seq_scl_less[i][j]), `PB(seq_scl_eq[i][j]), `PB(seq_scl_greater[i][j]));
          $fatal(1, "(ERROR: This shouldn't fail!) Test Failed");
        end

        if ({scm_less, scm_eq, scm_greater} !== {seq_scm_less[i][j], seq_scm_eq[i][j], seq_scm_greater[i][j]})
        begin
          $display("FAIL %s", `__FILE__);
          $display("++ INPUT    => {%s, %s, %s}",
                   `PD(j), `PB(a), `PB(b));
          $display("++ TEST     => {%s, %s, %s} != {%s, %s, %s}",
                   `PB(scm_less), `PB(scm_eq), `PB(scm_greater),
                   `PB(seq_scm_less[i][j]), `PB(seq_scm_eq[i][j]), `PB(seq_scm_greater[i][j]));
          $finish(1);
        end
      end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
