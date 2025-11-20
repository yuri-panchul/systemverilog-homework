module testbench;

  logic signed [3:0] a, b, sum;
  logic overflow;

  signed_add_with_overflow inst
    (.a (a), .b (b), .sum (sum), .overflow);

  task test
    (
      input [3:0] t_a, t_b,
      input       t_overflow
    );

    logic [3:0] t_sum;

    t_sum = t_a + t_b;

    { a, b } = { t_a, t_b };

    # 1;

    $write ("TEST %d + %d = ", a, b);

    if (overflow === 1'b1)
      $display ("overflow");
    else if (overflow === 1'b0)
      $display ("%d", sum);
    else
      begin
        $display ("\nFAIL %s: overflow is %X",
          `__FILE__, overflow);

        $finish;
      end

    if (overflow !== t_overflow)
      begin
        $display ("FAIL %s: EXPECTED %soverflow",
          `__FILE__, t_overflow ? "" : "no ");

        $finish;
      end
    else if (sum !== t_sum)
      begin
        $display ("FAIL %s: EXPECTED sum %d",
          `__FILE__, t_sum);
        $finish;
      end

  endtask

  initial
  begin
    `ifdef __ICARUS__
          // Uncomment the following line
          // to generate a VCD file and analyze it using GTKwave

          // $dumpvars;
    `endif

    test (  0,  0, 0);

    test (  1,  2, 0);
    test (  1, -2, 0);
    test ( -1,  2, 0);
    test ( -1, -2, 0);

    test (  4,  7, 1);
    test (  4, -7, 0);
    test ( -4,  7, 0);
    test ( -4, -7, 1);

    test (  3,  5, 1);
    test (  3, -5, 0);
    test ( -3,  5, 0);
    test ( -3, -5, 0);

    test (  3,  6, 1);
    test (  3, -6, 0);
    test ( -3,  6, 0);
    test ( -3, -6, 1);

    test (  2,  1, 0);
    test ( -2,  1, 0);
    test (  2, -1, 0);
    test ( -2, -1, 0);

    test (  7,  4, 1);
    test ( -7,  4, 0);
    test (  7, -4, 0);
    test ( -7, -4, 1);

    test (  5,  3, 1);
    test ( -5,  3, 0);
    test (  5, -3, 0);
    test ( -5, -3, 0);

    test (  6,  3, 1);
    test ( -6,  3, 0);
    test (  6, -3, 0);
    test ( -6, -3, 1);

    test (  1,  1, 0);
    test (  1, -1, 0);
    test ( -1,  1, 0);
    test ( -1, -1, 0);

    test (  4,  4, 1);
    test (  4, -4, 0);
    test ( -4,  4, 0);
    test ( -4, -4, 0);

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
