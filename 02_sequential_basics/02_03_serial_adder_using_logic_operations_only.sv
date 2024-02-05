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
  output carry,
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
  
  reg carry;
  reg sum;
 
 
	/*
	When posedge is used at time 12500 units, inputs are 
	a = 1, b = 1, sum = 0, carry = 1. It is observerd on the waves, but not on the log.
	This might be due to a race condition between tb and dut as they are both working on posedge
	*/
    always_ff @ (negedge clk) begin
		if (rst) begin
			carry = '0;
			sum = '0;
		end else begin
			{sum, carry} = {(a ^ b ^ carry), ((a & b) | ( a & carry) | (b & carry))};			
			//$display ("%t sum %b a %b b %b carry %b",$time, sum,  a , b, carry);
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
    `ifdef __ICARUS__
        $dumpvars;
    `endif
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  end

  logic a, b, sa_sum, salo_sum, carry;
  serial_adder                             sa   (.sum (sa_sum),   .*);
  serial_adder_using_logic_operations_only salo (.sum (salo_sum), .carry(carry), .*);

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

      $display ("%t %b %b SUM OBS: %b EXP:(%b) carry  %b",
        $time, a, b,
        salo_sum, seq_salo_sum [i], carry);

      if (   sa_sum   !== seq_sa_sum   [i]
          || salo_sum !== seq_salo_sum [i])
      begin
        $display ("%s FAIL - see log above", `__FILE__);
        //$finish;
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
