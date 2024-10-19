`include "../include/util.svh"

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

  // Sequence of input values
  localparam [n - 1:0] seq_vld     = 16'b1110_0001_1111_0110;
  localparam [n - 1:0] seq_a       = 16'b0110_1001_1001_0010;
  localparam [n - 1:0] seq_b       = 16'b0110_1001_0101_0100;
  localparam [n - 1:0] seq_last    = 16'b0100_1010_1000_0100;

  // Expected sequence of correct output values
  localparam [n - 1:0] expected = 16'b0110_0010_1110_0110;

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
