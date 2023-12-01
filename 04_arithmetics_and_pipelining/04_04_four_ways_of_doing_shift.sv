//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module left_shift_of_8_by_3_using_left_shift_operation (input  [7:0] a, output [7:0] res);

  assign res = a << 3;

endmodule

module left_shift_of_8_by_3_using_concatenation (input  [7:0] a, output [7:0] res);

  assign res = { a [4:0], 3'b0 };

endmodule

module left_shift_of_8_by_3_using_for_inside_always (input  [7:0] a, output logic [7:0] res);

  always_comb
    for (int i = 0; i < 8; i ++)
      res [i] = i < 3 ? 1'b0 : a [i - 3];

endmodule

module left_shift_of_8_by_3_using_for_inside_generate (input  [7:0] a, output [7:0] res);

  genvar i;

  generate
    for (i = 0; i < 8; i ++)
      if (i < 3)
        assign res [i] = 1'b0;
      else
        assign res [i] = a [i - 3];
  endgenerate

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module right_shift_of_N_by_S_using_right_shift_operation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using logical right shift operation


endmodule

module right_shift_of_N_by_S_using_concatenation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using concatenation operation


endmodule

module right_shift_of_N_by_S_using_for_inside_always
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output logic [N - 1:0] res);

  // Task:
  //
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using "for" inside "always_comb"


endmodule

module right_shift_of_N_by_S_using_for_inside_generate
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // sing "generate" and "for"


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  localparam N = 8, S = 3;

  logic [N - 1:0] a, res [0:7];

  left_shift_of_8_by_3_using_left_shift_operation  i0 (a, res [0]);
  left_shift_of_8_by_3_using_concatenation         i1 (a, res [1]);
  left_shift_of_8_by_3_using_for_inside_always     i2 (a, res [2]);
  left_shift_of_8_by_3_using_for_inside_generate   i3 (a, res [3]);

  right_shift_of_N_by_S_using_right_shift_operation
  # (.N (8), .S (3)) i4 (a, res [4]);

  right_shift_of_N_by_S_using_concatenation
  # (.N (8), .S (3)) i5 (a, res [5]);

  right_shift_of_N_by_S_using_for_inside_always
  # (.N (8), .S (3)) i6 (a, res [6]);

  right_shift_of_N_by_S_using_for_inside_generate
  # (.N (8), .S (3)) i7 (a, res [7]);

  initial
  begin
    repeat (20)
    begin
      a = $urandom ();
      # 1

      $write ("TEST %b", a);

      for (int i = 0; i < 8; i ++)
        $write (" %b", res [i]);

      $display;

      for (int i = 0; i < 8; i ++)
        if (res [i] !== res [i / 4 * 4])
        begin
          $display ("%s FAIL - see above", `__FILE__);
          $finish;
        end
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
