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

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // TODO

  // Using code for mux_2_1_width_1, mux_2_1_width_2,
  // mux_4_1_width_1 as examples,
  // write code for 4:1 mux using only &, | and ~ operations,
  // and possibly some wire continuous assignments.


endmodule

//----------------------------------------------------------------------------

module testbench;

  logic [3:0] d0, d1, d2, d3;
  logic [1:0] sel;
  logic [3:0] y;

  mux_4_1 inst
  (
    .d0  (d0), .d1 (d1), .d2 (d2), .d3 (d3),
    .sel (sel),
    .y   (y)
  );

  task test
    (
      input [3:0] td0, td1, td2, td3,
      input [1:0] tsel,
      input [3:0] ty
    );

    { d0, d1, d2, d3, sel } = { td0, td1, td2, td3, tsel };

    # 1;

    $display ("TEST d { %h %h %h %h } sel %d y %h",
        d0, d1, d2, d3, sel, y);

    if (y !== ty)
      begin
        $display ("%s FAIL: %h EXPECTED", `__FILE__, ty);
        $finish;
      end

  endtask

  initial
    begin
      test ('ha, 'hb, 'hc, 'hd, 0, 'ha);
      test ('ha, 'hb, 'hc, 'hd, 1, 'hb);
      test ('ha, 'hb, 'hc, 'hd, 2, 'hc);
      test ('ha, 'hb, 'hc, 'hd, 3, 'hd);

      test (7, 10, 3, 'x, 0, 7);
      test (7, 10, 3, 'x, 1, 10);
      test (7, 10, 3, 'x, 2, 3);
      test (7, 10, 3, 'x, 3, 'x);

      $display ("%s PASS", `__FILE__);
      $finish;
    end

endmodule
