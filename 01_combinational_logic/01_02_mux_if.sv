module mux_2_1
(
  input        [3:0] d0, d1,
  input              sel,
  output logic [3:0] y
);

  always_comb
    if (sel)
      y = d1;
    else
      y = d0;

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
  // write code for 4:1 mux using the "if" statement


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
