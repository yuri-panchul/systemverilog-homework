`include "util.svh"

module testbench;

  logic a, o;
  int i;

  not_gate_using_mux inst (a, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      begin
        a = 1' (i);

        # 1;

        if (o !== ~ a)
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s, %s}", `PH(a), `PH(i));
            $display("++ EXPECTED => {%s}", `PH(~a));
            $display("++ ACTUAL   => {%s}", `PH(o));
            $finish(1);
          end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
