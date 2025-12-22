
localparam N = 100 ;                        // number of repitition
localparam pos_token  = 50;                 // possybility generation token
localparam pos_valid  = 50;                 // token's validity, as percentage
localparam pos_ready  = 50;                 // possybility of reasiness
localparam N_hand     = 16;                 // lenght hand test
//`define      N_hand   16
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

    logic a, double_a;
    logic up_valid, up_ready;
    logic down_valid, down_ready;
    logic tmp;
    int   probability;
    int   i;

    /*
      первые 4 бита - одиночный токен и хэндшейк сверху и снизу.
      вторые 4 бита - двойной токен и хэндшейк сверху и снизу.
      третьи 4 бита - двойной токен в первом такте отсутствует хэндшейк сверху.
      четвертые 4 бита - два одиночных токена и отсутствует хэндшейк снизу.
      пятые 4 бита  - токенов нет, появляется хэндшейк снизу.
    */

    /*
      the first  nybble - a single token with handshake_up and handshake_down
      the second nybble - a double token with handshake_up and handshake_down
      the third  nybble - a double token without a handshake_up at the first step
      the 4th    nybble - the two single tokens without a handshake_down
      the 5th    nybble - no tokens but a handshake_down
    */
    logic [0:N_hand-1] a_down_ready     =  'b1111_1111_1111_0000_1111;
    logic [0:N_hand-1] a_up_token       =  'b1000_1100_1100_1010_0000;
    logic [0:N_hand-1] a_up_valid       =  'b1111_1111_0111_1111_1111;

    logic [0:N_hand-1] a_down_data      =  'b1100_1111_0110_1111_1111;
    logic [0:N_hand-1] a_down_valid     =  'b1111_1111_1111_1111_1111;
    logic [0:N_hand-1] a_up_ready       =  'b1111_1111_1111_1111_1111;



    wire up_handshake   = up_valid & up_ready;
    wire down_handshake = down_valid & down_ready;


    double_tokens_fc i_double_tokens_fc(
        .clk        ( clk             ),
        .rst        ( rst             ),
        .up_valid   ( up_valid        ),
        .up_ready   ( up_ready        ),
        .up_token   ( a               ),
        .down_valid ( down_valid      ),
        .down_data  ( double_a        ),
        .down_ready ( down_ready      )
    );

    //------------------------------------------------------------------------

    // Monitor

    bit was_reset = 1'b0;
    always @ (posedge clk) if (rst) was_reset <= 1'b1;

    int n_orig_tokens = 0,
        n_double_tokens = 0;

       wire in_token = up_valid & a ;

    always @ (posedge clk) begin
        if (~ rst & was_reset &  up_handshake)
        begin
            n_orig_tokens <= n_orig_tokens + 32' (a);
        end

        if (~ rst & was_reset & down_handshake)
        begin
            n_double_tokens <= n_double_tokens + 32'(double_a);
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

       // hand test
        @ (negedge rst);
        for ( i = 0 ; i < N_hand; i = i + 1)begin
          a          <= a_up_token[i];
          up_valid   <= a_up_valid[i];
          down_ready <= a_down_ready[i];
          @(posedge clk);
          if ((a_down_data[i] != double_a) | (a_down_valid[i] != down_valid)) begin
            $display("FAIL %s \n", `__FILE__);
            $display("Unexpected data. Step = %d\n", i);
            $display("expected double_a = %b,  down_valid = %b  \n", a_down_data[i], a_down_valid[i] );
            $display(" recived double_a = %b,  down_valid = %b  \n", double_a, down_valid );
          end
        end

        //
        repeat(N_hand)
        @(posedge clk);

        a          <= 1'b1;
        up_valid   <= 1'b1;
        down_ready <= 1'b0;
        i <= 0;

        while(up_ready) begin
          @(posedge clk)
          i <= i +1;
        end

        if (i != 100) begin
           $display("FAIL %s \n", `__FILE__);
           $display("Unexpected i = %d", i);
           $display("expected   i = %d", 100);
        end



        repeat (N)
        begin
            probability     = $urandom_range(100,0);
         //   a              <=  ($urandom_range(100,0) < pos_token);
         //   up_valid       <=  ($urandom_range(100,0) < pos_valid);

            // if the ystem is ready to process then generate token
            if (probability < pos_ready) begin
              down_ready     <= 1'b1;
              a              <=  ($urandom_range(100,0) < pos_token);
              up_valid       <=  ($urandom_range(100,0) < pos_valid);
            end
            else  begin
             // if system is not ready to process, then generate signal while
              down_ready   <= 1'b0;
              if ( ~(a & up_valid))
              a              <=  ($urandom_range(100,0) < pos_token);
              up_valid       <=  ($urandom_range(100,0) < pos_valid);

            end

            @ (posedge clk);
        end


        a          <= 1'b0;
        down_ready <= 1'b1;

        repeat ((2 * N) + 3)
            @ (posedge clk);


        //--------------------------------------------------------------------

        if ((n_double_tokens !== n_orig_tokens * 2) | (n_orig_tokens == 0))
        begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s}",
                             `PD(n_orig_tokens));

            $display("++ TEST     => {%s}",
                             `PD(n_double_tokens));
            $finish(1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
