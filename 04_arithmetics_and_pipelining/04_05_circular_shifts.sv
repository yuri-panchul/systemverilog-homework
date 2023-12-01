//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module circular_left_shift_of_N_by_S_using_bit_slices_and_concatenation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  assign res = { a [N - S - 1:0], a [N - 1 : N - S] };

endmodule

module circular_left_shift_of_N_by_S_by_ORing_the_results_of_shift_operations
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  assign res = (a << S) | (a >> (N - S));

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module circular_right_shift_of_N_by_S_using_bit_slices_and_concatenation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a module that shifts its input S bits to the right
  // in a circular fashion, using only concatenation of bit slices.
  //
  // "Circular" means ABCDEFGH -> FGHABCDE when N = 8 and S = 3.


endmodule

module circular_right_shift_of_N_by_S_by_ORing_the_results_of_shift_operations
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a module that shifts its input S bits to the right
  // in a circular fashion, using only the following operations:
  // logical right shift (>>), logical left shift (<<),
  // "or" (|) and constant expressions.
  //
  // "Circular" means ABCDEFGH -> FGHABCDE when N = 8 and S = 3.


endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  logic [7:0] a, resl0, resl1, resr0, resr1;

  circular_left_shift_of_N_by_S_using_bit_slices_and_concatenation
  # (.N (8), .S (3)) il0 (a, resl0);

  circular_left_shift_of_N_by_S_by_ORing_the_results_of_shift_operations
  # (.N (8), .S (3)) il1 (a, resl1);

  circular_right_shift_of_N_by_S_using_bit_slices_and_concatenation
  # (.N (8), .S (3)) ir0 (a, resr0);

  circular_right_shift_of_N_by_S_by_ORing_the_results_of_shift_operations
  # (.N (8), .S (3)) ir1 (a, resr1);

  task test (input [7:0] t_a, t_resl, t_resr);

    a = t_a;

    # 1;

    $display ("TEST %b << %b %b (EXP %b) >> %b %b (EXP %b)",
      a, resl0, resl1, t_resl, resr0, resr1, t_resr);

    if (! (   resl0 === t_resl && resl1 === t_resl
           && resr0 === t_resr && resr1 === t_resr))
    begin
      $display ("%s FAIL - see above", `__FILE__);
      $finish;
    end

  endtask

  initial
    begin
      test (8'b00000000, 8'b00000000, 8'b00000000);
      test (8'b10000000, 8'b00000100, 8'b00010000);
      test (8'b01000000, 8'b00000010, 8'b00001000);
      test (8'b00100000, 8'b00000001, 8'b00000100);
      test (8'b00010000, 8'b10000000, 8'b00000010);
      test (8'b00001000, 8'b01000000, 8'b00000001);
      test (8'b00000100, 8'b00100000, 8'b10000000);
      test (8'b00000010, 8'b00010000, 8'b01000000);
      test (8'b00000001, 8'b00001000, 8'b00100000);
      test (8'b11111111, 8'b11111111, 8'b11111111);
      test (8'b10110101, 8'b10101101, 8'b10110110);
      test (8'b01110000, 8'b10000011, 8'b00001110);
      test (8'b00100110, 8'b00110001, 8'b11000100);
      test (8'b11100000, 8'b00000111, 8'b00011100);
      test (8'b01101100, 8'b01100011, 8'b10001101);
      test (8'b11010001, 8'b10001110, 8'b00111010);
      test (8'b11000011, 8'b00011110, 8'b01111000);
      test (8'b00110100, 8'b10100001, 8'b10000110);
      test (8'b11110000, 8'b10000111, 8'b00011110);
      test (8'b01100110, 8'b00110011, 8'b11001100);

      $display ("%s PASS", `__FILE__);
      $finish;
    end

endmodule
