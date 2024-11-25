`include "util.svh"

module testbench;

  logic a, b, o;
  int i, j;

  or_gate_using_mux inst (a, b, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      for (j = 0; j <= 1; j++)
      begin
        a = 1' (i);
        b = 1' (j);

        # 1;

        if (o !== (a | b))
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s, %s, %s, %s}", `PH(a), `PH(b), `PH(i), `PH(j));
            $display("++ EXPECTED => {%s}", `PH(a|b));
            $display("++ ACTUAL   => {%s}", `PH(o));
            $finish(1);
          end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
