//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module left_shift_of_8_by_3_using_left_shift_operation (input  [7:0] a, output [7:0] res);

  assign res = a << 3;

endmodule

// We are ignoring bits a[7:5] on purpose
// verilator lint_off UNUSEDSIGNAL

module left_shift_of_8_by_3_using_concatenation (input  [7:0] a, output [7:0] res);

  assign res = { a [4:0], 3'b0 };

endmodule

// verilator lint_on UNUSEDSIGNAL

module left_shift_of_8_by_3_using_for_inside_always (input  [7:0] a, output logic [7:0] res);

  always_comb
    for (int i = 0; i < 8; i ++)
      res [i] = i < 3 ? 1'b0 : a [i - 3];

endmodule

// We are ignoring bits a[7:5] on purpose
// verilator lint_off UNUSEDSIGNAL

module left_shift_of_8_by_3_using_for_inside_generate (input  [7:0] a, output [7:0] res);

  genvar i;

  generate
    for (i = 0; i < 8; i ++)
      if (i < 3) begin : zero_bit_gen
        assign res [i] = 1'b0;
      end
      else begin : shifted_bit_gen
        assign res [i] = a [i - 3];
      end
  endgenerate

endmodule

// verilator lint_on UNUSEDSIGNAL

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

// We are ignoring some bits on purpose
// verilator lint_off UNUSEDSIGNAL

module right_shift_of_N_by_S_using_concatenation
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  //
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using concatenation operation


endmodule

// verilator lint_on UNUSEDSIGNAL

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
