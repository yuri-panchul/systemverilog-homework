module testbench_1;

  localparam  width          = 16,
              n_inputs       = 4,
              data_ptr_width = $clog2( n_inputs );

  logic                                       clk;
  logic                                       rst;
  logic [ n_inputs - 1 : 0 ]                  up_vlds;
  logic [ n_inputs - 1 : 0 ][ width - 1 : 0 ] up_data;
  logic                                       down_vld;
  logic [ width - 1 : 0 ]                     down_data;

  put_in_order #( .width( width ), .n_inputs( n_inputs ) )
  DUT(
    .clk        ( clk       ),
    .rst        ( rst       ),
    .up_vlds    ( up_vlds   ),
    .up_data    ( up_data   ),
    .down_vld   ( down_vld  ),
    .down_data  ( down_data )
  );


  //--------------------------------------------------------------------------
  // Driving clk

  initial
  begin

    clk = '1;
    forever # 5 clk = ~ clk;

  end

  //------------------------------------------------------------------------
  // Reset

  task reset ();

    rst <= 'x;
    repeat ( 3 ) @ ( posedge clk );
    rst <= '1;
    repeat ( 3 ) @ ( posedge clk );
    rst <= '0;

  endtask

  //------------------------------------------------------------------------

  logic                            running;
  logic [ width - 1 : 0 ]          current_data;
  logic [ n_inputs - 1 : 0 ]       ring_one;
  logic [ data_ptr_width - 1 : 0 ] data_ptr;

  //Pointer to current valid data input
  initial begin

    data_ptr <= '0;

    wait ( running ) @( posedge clk );

    forever begin
      data_ptr <= data_ptr + 1'b1;
      if ( data_ptr >= data_ptr_width' ( n_inputs - 1 ) )
        data_ptr <= '0;

      @( posedge clk );
    end

  end

  //current valid bit
  always_comb begin
    ring_one           = '0;
    if ( running ) begin
      ring_one             = '0;
      ring_one[ data_ptr ] = 1'b1;
    end
  end

  //Input data generation
  always_ff @( posedge clk ) begin
    if ( rst ) begin
      current_data <= '0;
    end else begin
      if ( running )
        current_data <= current_data + 1'b1;
    end
  end

  //delay generation
  logic [ n_inputs : 0 ][ data_ptr_width : 0 ] delays;
  event all_combination_done;

  initial begin

    delays = '0;

    wait ( running ) @( posedge clk );

    forever begin

      //get new delays value on every n_inputs cycle
      repeat ( n_inputs ) @( posedge clk );

      delays[ 0 ] = delays[ 0 ] + 1'b1;

      for ( int i = 0; i < n_inputs; i = i + 1 ) begin
        if ( delays[ i ] >= n_inputs ) begin
          delays[ i ]     = '0;
          delays[ i + 1 ] = delays[ i + 1 ] + 1'b1;
        end
      end

      //When overflow in last delay variable ( delays[n_inputs - 1] ) occure
      //we get "1" in delays[n_inputs]. This meant end of generation
      if ( delays[ n_inputs ] > '0 )
        -> all_combination_done;

    end


  end

  //Generate blocks that simulate modules with given latency
  genvar i;
  generate
    for ( i = 0; i < n_inputs; i++ ) begin : input_generator
      delay_data_model #( .width( width ), .n_inputs( n_inputs ) )
      r_delay(
        .clk       ( clk          ),
        .rst       ( rst          ),
        .vld_in    ( ring_one[i]  ),
        .out_delay ( delays[i][(data_ptr_width - 1) : 0] ),
        .data_in   ( current_data ),
        .vld_out   ( up_vlds[i]   ),
        .data_out  ( up_data[i]   )
      );
    end
  endgenerate

  event finish;

  initial
  begin
    `ifdef __ICARUS__
        // Uncomment the following line
        // to generate a VCD file and analyze it using GTKwave

        $dumpvars;
    `endif

    running <= 1'b0;
    reset();
    running <= 1'b1;

    //wait until all combination will be generated
    @( all_combination_done );
    running <= 1'b0;

    //Giving time for finishing pending delays
    repeat ( n_inputs + 1 ) @( posedge clk );

    -> finish;

    //Give time finish work for final block
    @( posedge clk );

    $finish;

  end

  //Collect input data
  logic  [ width - 1 : 0 ] data_in_queue [$];

  initial begin

    forever begin

      @( posedge clk );
      if ( running )
        data_in_queue.push_back( current_data );

    end

  end

  //Collect output data
  logic  [ width - 1 : 0 ] data_out_queue [$];

  initial begin

    forever begin

      @( posedge clk )
      if ( down_vld )
        data_out_queue.push_back( down_data );

    end

  end

  //Check data - last block. in "final" block for cycle not executed for some reason
  logic [ width - 1 : 0 ] res_expected;
  logic [ width - 1 : 0 ] res;
  logic                   is_test_fail;
  initial begin

    @( finish );
    is_test_fail = '0;

    $info("Qeueue size: %d", data_in_queue.size() );

    for ( int l = 0; l < data_in_queue.size(); l = l + 1 ) begin
      res_expected = data_in_queue.pop_front ();
      res          = data_out_queue.pop_front ();

      if ( res_expected !== res ) begin
        $warning( "Test failed. Expected output %d, but get %d", res_expected, res );
        is_test_fail  = 1'b1;
      end
    end

    if ( is_test_fail )
      $display ( "FAIL %s - see above", `__FILE__ );
    else
      $display ( "PASS %s", `__FILE__ );

  end

endmodule
