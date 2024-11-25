`include "util.svh"

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

  logic vld, a, b, last, actual;
  serial_adder_with_vld sav (.sum (actual), .*);

  localparam n = 128;

  // `define GENERATE

  `ifdef GENERATE

    logic [n - 1:0] seq_vld;
    logic [n - 1:0] seq_a;
    logic [n - 1:0] seq_b;
    logic [n - 1:0] seq_last;

    // Expected sequence of correct output values
    logic [n - 1:0] expected;

    initial
    begin
      @ (negedge rst);

      for (int i = 0; i < n; i ++)
      begin
        { vld, a, b, last } <= $urandom ();

        @ (posedge clk);

        { seq_vld [i], seq_a [i], seq_b [i], seq_last [i], expected [i] }
          = { vld, a, b, last, actual };
      end

      $display ("%b %b %b %b %b",
        seq_vld, seq_a, seq_b, seq_last, expected);

      $finish;
    end

  //--------------------------------------------------------------------------

  `else

    // Sequence of input values
    // localparam [n - 1:0] seq_vld     = 16'b1110_0001_1111_0110;
    // localparam [n - 1:0] seq_a       = 16'b0110_1001_1001_0010;
    // localparam [n - 1:0] seq_b       = 16'b0110_1001_0101_0100;
    // localparam [n - 1:0] seq_last    = 16'b0100_1010_1000_0100;
    //
    // // Expected sequence of correct output values
    // localparam [n - 1:0] expected = 16'b0110_0010_1110_0110;

    localparam [n - 1:0] seq_vld  = 128'b01100111101001010001110111111001111010101000011111011110100111100111100111101011101110010100110010011101101000100111101000110100;
    localparam [n - 1:0] seq_a    = 128'b10111010010111010010111001000101011011001101000011101110001100110001111000000010001110100101100000111110101011011011111001110001;
    localparam [n - 1:0] seq_b    = 128'b00100100111101111111011011010011001101010101000101101101000111100110111100001101111011011011010011000000111110101000010010001000;
    localparam [n - 1:0] seq_last = 128'b01111011001101111100000001110111110011000011011101101100111001111100000110010000011100111110100001111010001011010101101101111110;

    // Expected sequence of correct output values
    localparam [n - 1:0] expected = 128'b10011110101010110010000010010110000110011000000110000011110011010000000100001111110001111110110011111111010101110011101011111001;

    initial
    begin
      `ifdef __ICARUS__
        // Uncomment the following line
        // to generate a VCD file and analyze it using GTKwave or Surfer

        // $dumpvars;
      `endif

      @ (negedge rst);

      for (int i = 0; i < n; i ++)
      begin
        vld  <= seq_vld  [i];
        a    <= seq_a    [i];
        b    <= seq_b    [i];
        last <= seq_last [i];

        @ (posedge clk);

        if (vld) begin
          if (actual !== expected[i])
          begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s, %s, %s, %s, %s}",
                     `PD(i), `PB(vld), `PB(last), `PB(a), `PB(b));
            $display("++ TEST     => {%s, %s}",
                     `PB(expected[i]), `PB(actual));
            $finish(1);
          end
        end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

  `endif

endmodule
