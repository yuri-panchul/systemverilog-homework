module testbench;

  localparam n = 4;

  logic          [    n - 1:0] a, b;
  logic                        signed_mul;
  logic          [2 * n - 1:0] res;

  logic   signed [    n - 1:0] sa, sb;
  logic   signed [2 * n - 1:0] sres;

  logic unsigned [2 * n - 1:0] t_res;
  logic   signed [2 * n - 1:0] t_sres;

  signed_mul_4 i_signed_mul_4
    (.a (a), .b (b), .res (t_sres));

  unsigned_mul #(n) i_unsigned_mul
    (.a (a), .b (b), .res (t_res));

  signed_or_unsigned_mul #(.n (n)) i_signed_or_unsigned_mul
    (.a (a), .b (b), .signed_mul (signed_mul), .res (res));

  task test
    (
      input [n - 1:0] t_a, t_b,
      input t_signed_mul
    );

    { a, b, signed_mul } = { t_a, t_b, t_signed_mul };

    # 1;

    { sa, sb, sres } = { a, b, res };

    if (signed_mul)
    begin
      $display ("TEST   signed %d * %d = %d", sa, sb, sres);

      if (sres !== t_sres)
      begin
        $display ("FAIL %s: %d EXPECTED", `__FILE__, t_sres);
        $finish;
      end
    end
    else
    begin
      $display ("TEST unsigned %d * %d = %d", a, b, res);

      if (res !== t_res)
      begin
        $display ("FAIL %s: %d EXPECTED", `__FILE__, t_res);
        $finish;
      end
    end

  endtask

  localparam signed [n - 1:0] smin = n' (1) << (n - 1);
  localparam signed [n - 1:0] smax = ~ smin;
  localparam        [n - 1:0] umax = ~ { n { 1'b0 } };

  initial
    begin
      for (int i = 0; i <= umax; i ++)
      for (int j = 0; j <= umax; j ++)
        test (n' (i), n' (j), 1'b0);

      for (int i = 32' (smin); i <= 32' (smax); i ++)
      for (int j = 32' (smin); j <= 32' (smax); j ++)
        test (n' (i), n' (j), 1'b1);

      $display ("PASS %s", `__FILE__);
      $finish;
    end

endmodule
