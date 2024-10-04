//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1_width_1
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = (d0 & ~ sel) | (d1 & sel);

endmodule

//----------------------------------------------------------------------------

module mux_2_1_width_2
(
  input  [1:0] d0, d1,
  input        sel,
  output [1:0] y
);

  // { 2 { a } } is the same as { a, a }
  // { 4 { a } } is the same as { a, a, a, a }

  assign y =   (d0 & { 2 { ~ sel }})
             | (d1 & { 2 {   sel }});

endmodule

//----------------------------------------------------------------------------

module mux_4_1_width_1
(
  input        d0, d1, d2, d3,
  input  [1:0] sel,
  output       y
);

  wire sel0 = ~ sel [0] & ~ sel [1];
  wire sel1 =   sel [0] & ~ sel [1];
  wire sel2 = ~ sel [0] &   sel [1];
  wire sel3 =   sel [0] &   sel [1];

  assign y =   (d0 & sel0)
             | (d1 & sel1)
             | (d2 & sel2)
             | (d3 & sel3);

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // Task:
  // Using code for mux_2_1_width_1, mux_2_1_width_2,
  // mux_4_1_width_1 as examples,
  // write code for 4:1 mux using only &, | and ~ operations.


endmodule
