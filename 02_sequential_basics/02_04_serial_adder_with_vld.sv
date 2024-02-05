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
  // The module have two input signals, a and b, and an output signal sum.
  // Additionally, the module have two control signals, vld and last.
  // The vld signal indicates when the input values are valid.
  // The last signal indicates when the last digits of the input numbers has been received.
  //
  // When vld is high, the module should add the values of a and b and produce the sum.
  // When last is high, the module should output the sum and reset its internal state.
  //
  // When rst is high, the module should reset its internal state.
  
  logic carry = 0;
  logic sum;
  logic last_ff;
  
	always_ff @ (posedge clk) begin
		if(last)
			last_ff <= 1'b1;
		else
			last_ff <= 1'b0;
	end

    always_ff @ (posedge clk) begin
		if (rst) begin
			sum <= '0;
			carry <= '0;
		end else if (vld) begin
			{sum, carry} <= {(a ^ b ^ carry), ((a & b) | ( a & carry) | (b & carry))};			
			if (last) begin
				carry <= 0;
			end
			//$display ("%t sum %b a %b b %b carry %b",$time, sum,  a , b, carry);
		end else begin
			sum <= 0;
		end
	end


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
    `ifdef __ICARUS__
        $dumpvars;
    `endif
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      vld  <= seq_vld  [i];
      a    <= seq_a    [i];
      b    <= seq_b    [i];
      last <= seq_last [i];

      @ (negedge clk);

      if (vld) begin
        $display ("%t vld %b, last %b, %b+%b=%b (expected %b)",
          $time, vld, last, a, b,
          sav_sum, seq_sav_sum[i]);

        if (sav_sum !== seq_sav_sum[i])
        begin
          $display ("%s FAIL - see log above", `__FILE__);
          $finish;
        end
      end
      else
        // Testbench ignores output when vld is not set
        $display ("vld %b, last %b, %b+%b=%b", vld, last, a, b, sav_sum);
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
