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

module mux_4_1
(
  input        [3:0] d0, d1, d2, d3,
  input        [1:0] sel,
  output logic [3:0] y
);

  // TODO

  // Using code for mux_2_1 as an example,
  // write code for 4:1 mux using the "case" statement


endmodule
