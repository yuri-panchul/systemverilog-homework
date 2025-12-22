

localparam N = 500 ;                        // number of repitition

// set events probability in percent
localparam pos_token  = 50;
localparam pos_valid  = 50;
localparam pos_ready  = 50;

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


    logic down_data, up_token;
    logic up_valid, up_ready;
    logic down_valid, down_ready;
    logic tmp;
    int   probability;

    wire up_handshake   = up_valid & up_ready;
    wire down_handshake = down_valid & down_ready;


    halve_tokens_fc i_halve_tokens_fc(
        .clk        ( clk             ),
        .rst        ( rst             ),
        .up_valid   ( up_valid        ),
        .up_ready   ( up_ready        ),
        .up_token   ( up_token        ),
        .down_valid ( down_valid      ),
        .down_data  ( down_data       ),
        .down_ready ( down_ready      )
    );

    //------------------------------------------------------------------------

    // Monitor
    // sample inputs
    logic[0:15] s_down_ready     =   16'b1111_1111_1111_0000;
    logic[0:15] s_up_token       =   16'b1101_0100_1111_1111;
    logic[0:15] s_up_valid       =   16'b1111_1111_0101_1111;
    //outputs
    logic[0:15] s_down_valid     =   16'b1111_1111_0101_1111;
    logic[0:15] s_down_data      =   16'b0100_0100_0001_0000;
    logic[0:15] s_up_ready       =   16'b1111_1111_0101_1000;

    int i;

    bit was_reset = 1'b0;


    always @ (posedge clk) if (rst) was_reset <= 1'b1;

    int n_orig_tokens = 0,
        n_half_tokens = 0;

       wire in_token = up_valid & up_token ;

    always @ (posedge clk) begin
        if (~ rst & was_reset &  up_handshake)
        begin
            n_orig_tokens <= n_orig_tokens + 32' (up_token);
        end

        if (~ rst & was_reset & down_valid)
        begin
            n_half_tokens <= n_half_tokens + 32' (down_data);
        end
     end

    //------------------------------------------------------------------------
  initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

             $dumpvars;
        `endif

        @ (negedge rst);

        for (i=0; i < 15; i = i+1 ) begin
          //@(posedge  clk);
          down_ready <= s_down_ready[i];
          up_token   <= s_up_token[i];
          up_valid   <= s_up_valid[i];

           @(posedge  clk);
        if (~((down_ready == s_down_ready[i]) & (down_data == s_down_data[i]) & (down_valid == s_down_valid[i])))
           begin
             $display("FAIL %s", `__FILE__);
             $display ("\nERROR: numder test set = %d", i);
             $display ("\nERROR: unexpected result down_data = %h, down_ready = %h, down_valid  = %h", down_data, down_ready, down_valid);
             $display ("\n         expected result down_data = %h, down_ready = %h, down_valid  = %h", s_down_data[i], s_down_ready[i], s_down_valid[i]);
             repeat(3) @ (posedge clk);
             $finish;
            end

         // @(posedge  clk);
        end

        repeat (N)
        begin
            probability     = $urandom_range(100,0);

            // if the ystem is ready to process then generate token
            if (probability < pos_ready) begin
              down_ready     <= 1'b1;
              up_token       <=  ($urandom_range(100,0) < pos_token);
              up_valid       <=  ($urandom_range(100,0) < pos_valid);
            end
            else  begin
             // if system is not ready to process, then generate signal while
              down_ready   <= 1'b0;
              if ( ~(up_token & up_valid))
              up_token       <=  ($urandom_range(100,0) < pos_token);
              up_valid       <=  ($urandom_range(100,0) < pos_valid);

            end

            @ (posedge clk);
        end

        up_token <= 1'b0;

        repeat (2 * N)
            @ (posedge clk);

        //--------------------------------------------------------------------

        if ((n_half_tokens !== n_orig_tokens / 2) | (n_orig_tokens == 0))
        begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s}",
                             `PD(n_orig_tokens));

            $display("++ TEST     => {%s}",
                             `PD(n_half_tokens));
            $finish(1);
        end
        $display ("%s PASS", `__FILE__);
        $finish;
    end

endmodule
