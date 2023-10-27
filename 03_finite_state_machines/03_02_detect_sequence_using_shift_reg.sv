//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_shift_reg
(
  input  clk,
  input  rst,
  input  new_bit,
  output detected
);

  // Detection of the "1010" sequence using shift register

  logic [3:0] shift_reg;

  assign detected =   shift_reg[3] &
                    ~ shift_reg[2] &
                      shift_reg[1] &
                    ~ shift_reg[0];

  always_ff @ (posedge clk)
    if (rst)
      shift_reg <= '0;
    else
      shift_reg <= {shift_reg[2:0], new_bit };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_shift_reg
(
  input  clk,
  input  rst,
  input  new_bit,
  output detected
);

  // Task:
  // Implement a module that detects the "110011" sequence


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

  logic new_bit, det4bit, det6bit;
  detect_4_bit_sequence_using_shift_reg det4b (.detected (det4bit),  .*);
  detect_6_bit_sequence_using_shift_reg det6b (.detected (det6bit), .*);

  localparam n = 24;

  // The sequence of input values
  localparam [0 : n - 1] seq_new_bit       = 24'b0011_0101_1001_1001_1010_1000;

  // The sequence of expected output values
  localparam [0 : n - 1] seq_det4bit = 24'b0000_0001_0000_0000_0000_1010;
  localparam [0 : n - 1] seq_det6bit = 24'b0000_0000_0000_0100_0100_0000;

  initial
  begin
    // Remove the comments below to generate the dump.vcd file and analyze it with GTKwave
    // $dumpfile("dump_03_02.vcd");
    // $dumpvars(0, testbench);

    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      new_bit <= seq_new_bit [i];

      @ (posedge clk);

      $display ("%b %b (%b) %b (%b)",
        new_bit,
        det4bit, seq_det4bit[i],
        det6bit, seq_det6bit[i]);

      if (   det4bit !== seq_det4bit[i]
          || det6bit !== seq_det6bit[i])
      begin
        $display ("%s FAIL - see log above", `__FILE__);
        $finish;
      end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
