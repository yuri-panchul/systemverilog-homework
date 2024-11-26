module testbench;

  logic clk;

  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

  logic rst;

  task reset;
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  endtask

  logic new_bit, div_by_3, div_by_5;
  serial_divisibility_by_3_using_fsm sd3(
    .new_bit(new_bit),
    .div_by_3(div_by_3),
    .*);
  serial_divisibility_by_5_using_fsm sd5(
    .new_bit(new_bit),
    .div_by_5(div_by_5),
    .*);

  localparam w = 16;

  // The input number
  logic [w - 1:0] input_bits;
  always @ (posedge rst) input_bits <= '0;

  // The expected output values
  logic expected_div_by_3;
  logic expected_div_by_5;

  initial
  begin
    `ifdef __ICARUS__
        // Uncomment the following lines
        // to generate a VCD file and analyze it using GTKwave

        // $dumpvars;
    `endif

    // Run testbench 3 times
    repeat (3)
    begin
      // Reset the module
      reset ();

      new_bit <= 0;

      for (int i = 0; i < w; i ++)
      begin
        new_bit <= 1' ($urandom());

        @ (posedge clk);
        # 1

        input_bits = (input_bits << 1) | w' (new_bit);

        expected_div_by_3 = (input_bits % 3) == 0;
        expected_div_by_5 = (input_bits % 5) == 0;

        // Remove the comment to see the input sequence
        // $write("number %d %b ", input_bits, input_bits);

        $display("new_bit %b, div3 %b (expected %b), div5 %b (expected %b)",
          new_bit,
          div_by_3, expected_div_by_3,
          div_by_5, expected_div_by_5);

        if (div_by_3 !== expected_div_by_3 || div_by_5 !== expected_div_by_5)
        begin
          $display ("FAIL %s - see log above", `__FILE__);
          $finish;
        end
      end
      $display("Number %b accepted", input_bits);
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
