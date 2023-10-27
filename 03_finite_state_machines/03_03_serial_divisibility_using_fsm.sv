//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_divisibility_by_3_using_fsm
(
  input  clk,
  input  rst,
  input  new_bit,
  output div_by_3
);

  // States
  enum logic[1:0]
  {
     mod_0 = 2'b00,
     mod_1 = 2'b01,
     mod_2 = 2'b10
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    case (state)
      mod_0 : if(new_bit) new_state = mod_1;
              else        new_state = mod_0;
      mod_1 : if(new_bit) new_state = mod_0;
              else        new_state = mod_2;
      mod_2 : if(new_bit) new_state = mod_2;
              else        new_state = mod_1;
    endcase
  end

  // Output logic
  assign div_by_3 = state == mod_0;

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= mod_0;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_divisibility_by_5_using_fsm
(
  input  clk,
  input  rst,
  input  new_bit,
  output div_by_5
);

  // Implement a module that performs a serial test if input number is divisible by 5.
  //
  // On each clock cycle, module recieves the next 1 bit of the input number.
  // The module should set output to 1 if the currently known number is divisible by 5.
  //
  // Hint: new bit is coming to the right side of the long binary number `X`.
  // It is similar to the multiplication of the number by 2*X or by 2*X + 1.
  //
  // Hint 2: As we are interested only in the remainder, all operations are performed under the modulo 5 (% 5).
  // Check manually how the remainder changes under such modulo.


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
    // Remove the comments below to generate the dump.vcd file and analyze it with GTKwave
    // $dumpfile("dump_03_03.vcd");
    // $dumpvars(0, testbench);

    // Run testbench 3 times
    repeat (3)
    begin
      // Reset the module
      reset ();

      new_bit <= 0;

      for (int i = 0; i < w; i ++)
      begin
        new_bit <= $urandom();

        @ (posedge clk);
        # 1

        input_bits = (input_bits << 1) | new_bit;

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
          $display ("%s FAIL - see log above", `__FILE__);
          $finish;
        end
      end
      $display("Number %b accepeted", input_bits);
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
