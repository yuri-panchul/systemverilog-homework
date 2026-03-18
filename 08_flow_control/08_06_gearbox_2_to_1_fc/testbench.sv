//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

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

    localparam WIDTH      = 2;
    localparam MAX_TOKEN  = 2**(WIDTH)-1;

    logic [2*WIDTH-1:0] in_token, sample, expected_token, tmp_token;
    logic [WIDTH-1:0]   out_token, first_part;
    logic [2*WIDTH-1:0] queue_tokens[$];

    logic up_valid, up_ready;
    logic down_valid, down_ready;
    logic valid_tmp, ready_tmp;
    logic order;

    int   count_token = 0;
    int   stage = 0;


    wire up_handshake   = up_valid & up_ready;
    wire down_handshake = down_valid & down_ready;

    gearbox_2_to_1_fc #(.width(WIDTH))
      dut(
        .clk          ( clk             ),
        .rst          ( rst             ),
        .up_valid     ( up_valid        ),
        .up_ready     ( up_ready        ),
        .up_data      ( in_token        ),
        .down_valid   ( down_valid      ),
        .down_data    ( out_token       ),
        .down_ready   ( down_ready      )
      );

    //------------------------------------------------------------------------

    // Monitor
    bit was_reset = 1'b0;

    always @ (posedge clk) if (rst) was_reset <= 1'b1;

    always @ (posedge clk) begin

        if (rst) order <= 1'b1;
        else if (was_reset & down_handshake)
        begin
            if (order == 1'b1) begin
              first_part = out_token;
              order <= 1'b0;
            end
            else begin
              order <= 1'b1;
              count_token = count_token + 1;
              expected_token =  queue_tokens.pop_back();
              if (~({first_part, out_token} === expected_token)) begin
                $display("FAIL %s", `__FILE__);
                $display("unexpected token  %b expected %b", tmp_token, expected_token);
                $display("Number token  %d ", count_token);
                repeat(3) @(posedge clk);
                $finish(1);
              end
            end
        end
     end

    //------------------------------------------------------------------------

    localparam N = 100 ;                        // number of repitition
    localparam pro_token  = 50;                 // probality generation token
    localparam pro_valid  = 50;                 // token's validity, as percentage
    localparam pro_ready  = 50;                 // probality of readiness

    localparam TIMEOUT   = 50_000;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif
        sample = '0; //MAX_TOKEN;

      @ (negedge rst);

    //--- simple test ---
      stage <= 1;
      down_ready <= 1'b1;
      up_valid   <= 1'b1;

      repeat (10)
        begin
        // gererating a token
          sample           = $urandom_range(MAX_TOKEN, 0);
        // sending the token
          in_token         <= sample;
          @(posedge clk);

          while (~up_handshake) @(posedge clk);

        // save data to queue
            queue_tokens.push_front(sample);
         @(posedge clk);
      end
      up_valid = 1'b0;

   // --- test  up_handshake ---

      stage  <=2;
      down_ready <= 1'b1;
      up_valid   <= 1'b0;
 // gererating the first token
      sample      <= $urandom_range(MAX_TOKEN, 0);
      //sample      <= 4'b0001;
      valid_tmp   <= ($urandom_range(100,0) < pro_valid);
      @(posedge clk)

      repeat (5)
        begin
        //
          while (~valid_tmp)   begin
            up_valid  <= 1'b0;
            valid_tmp <= ($urandom_range(100,0) < pro_valid);
            in_token  <= 'x ;
            @(posedge clk);
          end

          if(~up_ready) while (~up_ready) @(posedge clk);

          up_valid  <= 1'b1;
          in_token  <= sample;

        // save data to queue
          queue_tokens.push_front(sample);
          sample      <= $urandom_range(MAX_TOKEN, 0);

          if(~up_handshake) while (~up_handshake) @(posedge clk);
          else @(posedge clk);
          if(~up_handshake) while (~up_handshake) @(posedge clk);
        end

//  --- test  down_handshake ---

      stage          <=3;
      up_valid       <= 1'b0;
      down_ready     <= 1'b0;

   // gererating the first token
      sample      <= $urandom_range(MAX_TOKEN, 0);
       @(posedge clk)

      repeat (10)
        begin
        // gererating a token
        up_valid    <= 1'b1;
        in_token    <= sample;
        down_ready  <= ($urandom_range(100,0) < pro_ready);
        @(posedge clk)

        sample      <= $urandom_range(MAX_TOKEN, 0);

        if(~up_handshake)
          while (~up_handshake) begin
            @(posedge clk);
            down_ready  <= ($urandom_range(100,0) < pro_ready);
        end
        else @(posedge clk);

      // save data to queue
        queue_tokens.push_front(in_token);
      end

   up_valid    <= 1'b0;


   // --- random test ---
     stage <= 4;
   // gererating the first token
      sample        <= $urandom_range(MAX_TOKEN, 0);
      valid_tmp     <= ($urandom_range(100,0) < pro_valid);
      down_ready    <= ($urandom_range(100,0) < pro_ready);

      @(posedge clk);

      repeat(N) begin
        // we are sending first part
        // whiting for valid_tmp
        while (~valid_tmp) begin   // white valid data
          valid_tmp   <= ($urandom_range(100,0) < pro_valid);
          down_ready  <= ($urandom_range(100,0) < pro_ready);
          in_token    <= 'x;
          up_valid    <= 1'b0;
          @(posedge clk);
        end

        //  We are to send data
        in_token    <= sample;
        up_valid    <= 1'b1;

        valid_tmp   <= ($urandom_range(100,0) < pro_valid);
        down_ready  <= ($urandom_range(100,0) < pro_ready);

        sample        <= $urandom_range(MAX_TOKEN, 0);
      // waiting for up_ready
        if (~up_ready)
          while (~up_ready) begin
            down_ready  <= ($urandom_range(100,0) < pro_ready);
            @(posedge clk);
          end
        else @(posedge clk);

        // Cheking the up_ready again
        if (~up_ready)
          while (~up_ready) begin
            down_ready  <= ($urandom_range(100,0) < pro_ready);
            @(posedge clk);
          end

            // save data to queue
        queue_tokens.push_front(in_token);
      end


    //sink
      up_valid   <= 1'b0;
      down_ready <= 1'b1;
      repeat (3) @ (posedge clk);

    //--------------------------------------------------------------------

        if (count_token == '0) begin
          $display("FAIL %s", `__FILE__);
          $display("NO input tokens");
          $finish(1);
        end

        if (queue_tokens.size() !=0 ) begin
          $display("FAIL %s", `__FILE__);
          $display("Queue is not empty. Queue size = %d",queue_tokens.size());
          $display("token is : %b", queue_tokens.pop_back() );
          $finish(1);
        end;

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    initial
    begin
        repeat (TIMEOUT) @ (posedge clk);
        $display ("FAIL %s: timeout!", `__FILE__);
        $finish;
    end

endmodule
