//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input        [3:0] d0, d1,
  input              sel,
  output logic [3:0] y
);

  always_comb
    case (sel)
      1'd0: y = d0;
      1'd1: y = d1;
    endcase

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input        [3:0] d0, d1, d2, d3,
  input        [1:0] sel,
  output logic [3:0] y
);

  // Task:
  // Using code for mux_2_1 as an example,
  // write code for 4:1 mux using the "case" statement
  always_comb
  case (sel)
    2'b00: y = d0;
    2'b01: y = d1;
    2'b10: y = d2;
    2'b11: y = d3;
    endcase

endmodule
