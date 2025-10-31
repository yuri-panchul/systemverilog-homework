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

  // Ascending bit range in a packed vector is intentional here
  // verilator lint_off ASCRANGE

  // The sequence of input values
  localparam [0 : n - 1] seq_new_bit       = 24'b0011_0101_1001_1001_1010_1000;

  // The sequence of expected output values
  localparam [0 : n - 1] seq_det4bit = 24'b0000_0001_0000_0000_0000_1010;
  localparam [0 : n - 1] seq_det6bit = 24'b0000_0000_0000_0100_0100_0000;

  // verilator lint_on ASCRANGE

  initial
  begin
    `ifdef __ICARUS__
        // Uncomment the following lines
        // to generate a VCD file and analyze it using GTKwave

        // $dumpvars;
    `endif

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
        $display ("FAIL %s - see log above", `__FILE__);
        $finish;
      end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
