module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------

module not_gate_using_mux
(
    input  i,
    output o
);

  // TODO

  // Implement not gate using instance(s) of mux,
  // constants 0 and 1, and wire connections


endmodule

//----------------------------------------------------------------------------

module testbench;

  logic a, o;
  int i;

  not_gate_using_mux inst (a, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      begin
        a = i;

        # 1;

        $display ("TEST ~ %b = %b", a, o);

        if (o !== ~ a)
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {a:%h, i:%h}", a, i);
            $display("++ EXPECTED => {o:%h}", ~a);
            $display("++ ACTUAL   => {o:%h}", o);
            $fatal(1, "Test Failed");
          end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
