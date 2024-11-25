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

  initial begin
    `ifdef __ICARUS__
      // Uncomment the following line
      // to generate a VCD file and analyze it using GTKwave or Surfer

      // $dumpvars;
    `endif
  end

  //--------------------------------------------------------------------------

  logic [1:0] requests;
  wire  [1:0] grants;

  round_robin_arbiter_with_2_requests arbiter (.*);

  //--------------------------------------------------------------------------

  localparam n = 32;

  // `define GENERATE

  `ifdef GENERATE

    logic [n - 1:0] req_0;
    logic [n - 1:0] req_1;

    logic [n - 1:0] grant_0;
    logic [n - 1:0] grant_1;

    initial
    begin
      @ (negedge rst);

      for (int i = 0; i < n; i ++)
      begin
        { req_1 [i], req_0 [i] } = $urandom;

        requests <= { req_1 [i], req_0 [i] };

        @ (posedge clk);

        { grant_1 [i], grant_0 [i] } = grants;
      end

      $display ("%b %b %b %b", req_0, req_1, grant_0, grant_1);
      $finish;
    end

  //--------------------------------------------------------------------------

  `else

    localparam [n - 1:0] req_0            = 32'b01111010001011010101101101111110;
    localparam [n - 1:0] req_1            = 32'b11000000111110101000010010001000;

    localparam [n - 1:0] expected_grant_0 = 32'b00111010001001010101101101110110;
    localparam [n - 1:0] expected_grant_1 = 32'b11000000110110101000010010001000;

    logic [1:0] expected_grants;

    initial
    begin
      @ (negedge rst);

      for (int i = 0; i < n; i ++)
      begin
        requests        <= { req_1 [i], req_0 [i] };
        expected_grants <= { expected_grant_1 [i], expected_grant_0 [i] };

        // expected_grants are assigned before @ (posedge clk)
        // rather than after @ (posedge clk)
        // in order to appear on the waveform at the same cycles as grants.

        @ (posedge clk);

        if (grants !== expected_grants)
        begin // TODO: If you comment the line out it just says "I give up"
          $display("FAIL %s", `__FILE__);
          $display("++ INPUT    => {%s, %s}",
                   `PB(requests), `PB(expected_grants));
          $display("++ TEST     => {%s, %s, %s, %s}",
                   `PD(i), `PB(requests),
                   `PB(grants), `PB(expected_grants));
          $finish(1);
        end
      end

      $display ("PASS %s", `__FILE__);
      $finish;
    end

  `endif

endmodule
