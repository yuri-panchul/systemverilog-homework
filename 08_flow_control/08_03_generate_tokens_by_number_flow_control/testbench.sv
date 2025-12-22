


localparam N = 100 ;                        // number of repitition
localparam pro_token  = 50;                 // probality generation token
localparam pro_valid  = 50;                 // token's validity, as percentage
localparam pro_ready  = 50;                 // probality of readiness
localparam WIDTH_A    = 4;                  //
localparam MAX_A      = $pow(2,WIDTH_A) - 1;//

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

    //------------------------------------------------------------------------

    logic [WIDTH_A-1:0] n_tokens ;
    logic up_valid, up_ready;
    logic down_valid, down_ready;
    int   probability;
    int   i;

    wire up_handshake   = up_valid & up_ready;
    wire down_handshake = down_valid & down_ready;

    generate_tokens_fc
      dut(
        .clk        ( clk             ),
        .rst        ( rst             ),
        .up_valid   ( up_valid        ),
        .up_ready   ( up_ready        ),
        .n_tokens   ( n_tokens        ),
        .down_valid ( down_valid      ),
        .down_token ( out_token       ),
        .down_ready ( down_ready      )
      );

    //------------------------------------------------------------------------

    // Monitor

    bit was_reset = 1'b0;
    always @ (posedge clk) if (rst) was_reset <= 1'b1;

    int n_tokens_up  = 0,
        n_tokens_out = 0;


    always @ (posedge clk) begin
        if (~rst & was_reset &  up_handshake)
        begin
            n_tokens_up <= n_tokens_up + 32'(n_tokens);
        end

        if (~rst & was_reset & down_handshake)
        begin
            n_tokens_out <= n_tokens_out + out_token ;
        end
     end

    //------------------------------------------------------------------------
    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif

        @ (negedge rst);
        n_tokens   <= 1'b0;
        up_valid   <= 1'b1;


        repeat (N)
        begin
        if (up_ready) begin
          n_tokens       <= $urandom_range(MAX_A,0);
          up_valid       <= ($urandom_range(100,0) < pro_valid);
        end
        else if (~up_valid)
          up_valid       <= ($urandom_range(100,0) < pro_valid);

          down_ready     <= ($urandom_range(100,0) < pro_ready);
        @ (posedge clk);
        end


        n_tokens   <= 1'b0;
        down_ready <= 1'b1;

       //sink
        repeat ((2 * N) + 3)
            @ (posedge clk);
        //--------------------------------------------------------------------


        if (n_tokens_up == '0) begin
          $display("FAIL %s", `__FILE__);
          $display("NO input tokens");
          $finish(1);
        end

        if (n_tokens_up !== n_tokens_out)
        begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s}",
                             `PD(n_tokens_up));

            $display("++ TEST     => {%s}",
                             `PD(n_tokens_out));
            $finish(1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
