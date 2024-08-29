`include "../util.sv"

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_adder_with_vld
(
  input  clk,
  input  rst,
  input  vld,
  input  a,
  input  b,
  input  last,
  output sum
);

  // Task:
  // Implement a module that performs serial addition of two numbers.
  // It should have input signals a and b.
  // It should have an output signal sum.
  //
  // Additionally, it should have two control signals, vld and last.
  // The vld signal indicates when the input values are valid.
  // The last signal indicates when the last digits of the input numbers has been received.
  // When vld is high, the module should add the values of a and b and produce the sum.
  // When last is high, the module should output the sum and reset its internal state.
  //
  // When rst is high, the module should reset its internal state.

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

  logic vld, a, b, last, sav_sum;
  serial_adder_with_vld sav (.sum (sav_sum), .*);

  localparam n = 16;

  // Sequence of input values
  localparam [0 : n - 1] seq_vld     = 16'b0110_1111_1100_0111;
  localparam [0 : n - 1] seq_a       = 16'b0100_1001_1001_0110;
  localparam [0 : n - 1] seq_b       = 16'b0010_1010_1001_0110;
  localparam [0 : n - 1] seq_last    = 16'b0010_0001_0101_0010;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_sav_sum = 16'b0110_0111_0100_0010;

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
        if (sav_sum !== seq_sav_sum[i])
        begin
          $display("FAIL %s", `__FILE__);
          $display("++ INPUT    => {%s, %s, %s, %s, %s}",
                   `PD(i), `PB(vld), `PB(last), `PB(a), `PB(b));
          $display("++ TEST     => {%s, %s}",
                   `PB(sav_sum), `PB(seq_sav_sum[i]));
          $fatal(1, "Test Failed");
        end
      end
      else
        // Testbench ignores output when vld is not set
        $display ("vld %b, last %b, %b+%b=%b", vld, last, a, b, sav_sum);
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
