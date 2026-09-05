//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  wire x1, x2;
  
  mux mand1 (
    .d0(a), .d1(~b),
    .sel(a),
    .y(x1)
  );

  mux mand2 (
    .d0(b), .d1(~a),
    .sel(b),
    .y(x2)
  );
  
  mux mor (
    .d0(x1), .d1(1'b1),
    .sel(x2),
    .y(o)
  );

endmodule
