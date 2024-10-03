`include "../util.sv"

module testbench;

  logic clk;

  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

  logic rst;

  initial
  begin
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  end

  logic a, b, sa_sum, actual;
  serial_adder                             sa   (.sum (sa_sum), .*);
  serial_adder_using_logic_operations_only salo (.sum (actual), .*);

  localparam n = 16;

  // Ascending bit range in a packed vector is intentional here
  // verilator lint_off ASCRANGE

  // Sequence of input values
  localparam [0 : n - 1] seq_a        = 16'b0100_1001_1000_0001;
  localparam [0 : n - 1] seq_b        = 16'b0010_1010_1000_0100;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_expected   = 16'b0110_0111_0100_0101;

  // verilator lint_on ASCRANGE

  // TODO: If I misstype a variable, I just get nothing as an error?
  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      a <= seq_a [i];
      b <= seq_b [i];

      @ (posedge clk);

      if (sa_sum !== seq_expected [i]) // Sanity Check against serial_adder
        $fatal(1, "Error: serial_adder example failed!");

      if (actual !== seq_expected [i])
        begin // TODO: If you comment the line out it just says "I give up"
        $display("FAIL %s", `__FILE__);
        $display("++ INPUT    => {%s, %s, %s}",
                 `PB(seq_a), `PB(seq_b), `PB(seq_expected));
        $display("++ TEST     => {%s, %s, %s, %s, %s}",
                 `PD(i), `PB(seq_a[i]), `PB(seq_b[i]),
                 `PB(actual), `PB(seq_expected[i]));
        $finish(1);
    end
  end

    $display ("PASS %s", `__FILE__);
    $finish;
  end

endmodule
