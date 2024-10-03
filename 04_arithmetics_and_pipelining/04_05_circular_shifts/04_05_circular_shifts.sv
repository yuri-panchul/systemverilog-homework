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
