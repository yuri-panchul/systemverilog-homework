//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input  [3:0] d0, d1,
  input        sel,
  output [3:0] y
);

  logic [3:0] d [0:1];

  assign d [0] = d0;
  assign d [1] = d1;

  assign y = d [sel];

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
  // Using code for mux_2_1 as an example,
  // write code for 4:1 mux using array index
 logic [3:0] d [0:1][0:1];
 assign d[0][0] = d0; 
 assign d[0][1] = d1; 
 assign d[1][0] = d2; 
 assign d[1][1] = d3; 

 assign y = d[sel[1]][sel[0]]; 
endmodule
