`include "../util.sv"

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------

module and_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // TODO

  // Implement and gate using instance(s) of mux,
  // constants 0 and 1, and wire connections


endmodule

//----------------------------------------------------------------------------

module testbench;

  logic a, b, o;
  int i, j;

  and_gate_using_mux inst (a, b, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      for (j = 0; j <= 1; j++)
      begin
        a = i;
        b = j;

        # 1;

        if (o !== (a & b))
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s, %s, %s, %s}", `PH(a), `PH(b), `PH(i), `PH(j));
            $display("++ EXPECTED => {%s}", `PH(a&b));
            $display("++ ACTUAL   => {%s}", `PH(o));
            $fatal(1, "Test Failed");
          end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
