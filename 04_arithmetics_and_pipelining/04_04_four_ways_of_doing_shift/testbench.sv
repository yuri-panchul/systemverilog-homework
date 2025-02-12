module testbench;

  localparam N = 8, S = 3;

  logic [N - 1:0] a, res [0:7];

  left_shift_of_8_by_3_using_left_shift_operation  i0 (a, res [0]);
  left_shift_of_8_by_3_using_concatenation         i1 (a, res [1]);
  left_shift_of_8_by_3_using_for_inside_always     i2 (a, res [2]);
  left_shift_of_8_by_3_using_for_inside_generate   i3 (a, res [3]);

  right_shift_of_N_by_S_using_right_shift_operation
  # (.N (N), .S (S)) i4 (a, res [4]);

  right_shift_of_N_by_S_using_concatenation
  # (.N (N), .S (S)) i5 (a, res [5]);

  right_shift_of_N_by_S_using_for_inside_always
  # (.N (N), .S (S)) i6 (a, res [6]);

  right_shift_of_N_by_S_using_for_inside_generate
  # (.N (N), .S (S)) i7 (a, res [7]);

  initial
  begin
    repeat (20)
    begin
      a = N' ($urandom());
      # 1

      $write ("TEST %b", a);

      for (int i = 0; i < 8; i ++)
        $write (" %b", res [i]);

      $display;

      for (int i = 0; i < 8; i ++)
        if (res [i] !== res [i / 4 * 4])
        begin
          $display ("FAIL %s - see above", `__FILE__);
          $finish;
        end
    end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
