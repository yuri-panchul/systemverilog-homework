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
  logic not_b;
  mux not_gate(.d0('1),
              .d1('0),
              .sel(b),
              .y(not_b)
        );

  mux xor_gate(.d0(b),
              .d1(not_b),
              .sel(a),
              .y(o));

endmodule
