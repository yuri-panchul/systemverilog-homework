module testbench;

  localparam N = 8, S = 3;

  logic signed [N - 1:0] a, res [0:3];

  arithmetic_right_shift_of_N_by_S_using_arithmetic_right_shift_operation
  # (.N (N), .S (S)) i4 (a, res [0]);

  arithmetic_right_shift_of_N_by_S_using_concatenation
  # (.N (N), .S (S)) i5 (a, res [1]);

  arithmetic_right_shift_of_N_by_S_using_for_inside_always
  # (.N (N), .S (S)) i6 (a, res [2]);

  arithmetic_right_shift_of_N_by_S_using_for_inside_generate
  # (.N (N), .S (S)) i7 (a, res [3]);

  initial
  begin
    `ifdef __ICARUS__
          // Uncomment the following line
          // to generate a VCD file and analyze it using GTKwave

          // $dumpvars;
    `endif

    repeat (20)
    begin
      a = N' ($urandom());
      # 1

      $write ("TEST %d %b", a, a);

      for (int i = 0; i < 4; i ++)
        $write (" %d %b", res [i], res [i]);

      $display;

      for (int i = 1; i < 4; i ++)
        if (res [i] !== res [0])
        begin
          $display ("FAIL %s. EXPECTED %d %b",
            `__FILE__, res [0], res [0]);

          $finish;
        end

        /*
        if (res [i] !== a / 2 ** S)
        begin
          $display ("%s FAIL. EXPECTED %d %b",
            `__FILE__, a / (8'sd2 ** S), a / (8'sd2 ** S));

          $finish;
        end
        */
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
