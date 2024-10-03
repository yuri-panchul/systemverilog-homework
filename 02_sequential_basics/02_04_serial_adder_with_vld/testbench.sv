`include "../util.sv"

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

  logic vld, a, b, last, actual;
  serial_adder_with_vld sav (.sum (actual), .*);

  localparam n = 16;

  // Ascending bit range in a packed vector is intentional here
  // verilator lint_off ASCRANGE

  // Sequence of input values
  localparam [0 : n - 1] seq_vld     = 16'b0110_1111_1100_0111;
  localparam [0 : n - 1] seq_a       = 16'b0100_1001_1001_0110;
  localparam [0 : n - 1] seq_b       = 16'b0010_1010_1001_0110;
  localparam [0 : n - 1] seq_last    = 16'b0010_0001_0101_0010;

  // Expected sequence of correct output values
  localparam [0 : n - 1] expected = 16'b0110_0111_0100_0010;

  // verilator lint_on ASCRANGE

  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      vld  <= seq_vld  [i];
      a    <= seq_a    [i];
      b    <= seq_b    [i];
      last <= seq_last [i];

      @ (posedge clk);

      if (vld) begin
        if (actual !== expected[i])
        begin
          $display("FAIL %s", `__FILE__);
          $display("++ INPUT    => {%s, %s, %s, %s, %s}",
                   `PD(i), `PB(vld), `PB(last), `PB(a), `PB(b));
          $display("++ TEST     => {%s, %s}",
                   `PB(expected[i]), `PB(actual));
          $finish(1);
        end
      end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
