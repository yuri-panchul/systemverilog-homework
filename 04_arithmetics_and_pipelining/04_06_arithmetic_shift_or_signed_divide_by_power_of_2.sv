//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module arithmetic_right_shift_of_N_by_S_using_arithmetic_right_shift_operation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  wire signed [N - 1:0] as = a;
  assign res = as >>> S;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module arithmetic_right_shift_of_N_by_S_using_concatenation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a module with the logic for the arithmetic right shift,
  // but without using ">>>" operation. You are allowed to use only
  // concatenations ({a, b}), bit repetitions ({ a { b }}), bit slices
  // and constant expressions.


endmodule

module arithmetic_right_shift_of_N_by_S_using_for_inside_always
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output logic [N - 1:0] res);

  // Task:
  //
  // Implement a module with the logic for the arithmetic right shift,
  // but without using ">>>" operation, concatenations or bit slices.
  // You are allowed to use only "always_comb" with a "for" loop
  // that iterates through the individual bits of the input.


endmodule

module arithmetic_right_shift_of_N_by_S_using_for_inside_generate
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  // Implement a module that arithmetically shifts input exactly
  // by `S` bits to the right using "generate" and "for"


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  localparam N = 8, S = 3;

  logic signed [N - 1:0] a, res [0:3];

  arithmetic_right_shift_of_N_by_S_using_arithmetic_right_shift_operation
  # (.N (8), .S (3)) i4 (a, res [0]);

  arithmetic_right_shift_of_N_by_S_using_concatenation
  # (.N (8), .S (3)) i5 (a, res [1]);

  arithmetic_right_shift_of_N_by_S_using_for_inside_always
  # (.N (8), .S (3)) i6 (a, res [2]);

  arithmetic_right_shift_of_N_by_S_using_for_inside_generate
  # (.N (8), .S (3)) i7 (a, res [3]);

  initial
  begin
    repeat (20)
    begin
      a = $urandom ();
      # 1

      $write ("TEST %d %b", a, a);

      for (int i = 0; i < 4; i ++)
        $write (" %d %b", res [i], res [i]);

      $display;

      for (int i = 1; i < 4; i ++)
        if (res [i] !== res [0])
        begin
          $display ("%s FAIL. EXPECTED %d %b",
            `__FILE__, res [0], res [0]);

          $finish;
        end

        /*
        if (res [i] !== a / 2 ** S)
        begin
          $display ("%s FAIL. EXPECTED %d %b",
            `__FILE__, a / (8'sd2 ** S), a / (8'sd2 ** S));

          $finish;
        end
        */
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
