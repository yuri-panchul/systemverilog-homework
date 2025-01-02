`timescale 1ns/1ps

module testbench;

  localparam  width          = 16,
              n_inputs       = 5,
              data_ptr_width = $clog2(n_inputs);

  logic                                  clk;
  logic                                  rst;
  logic [n_inputs - 1:0]                 up_vlds;
  logic [n_inputs - 1:0][width - 1 : 0]  up_data;
  logic                                  down_vld;
  logic [width - 1:0]                    down_data;
   
  put_in_order #(.width(width), .n_inputs(n_inputs))
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
    repeat (3) @ (posedge clk);
    rst <= '1;
    repeat (3) @ (posedge clk);
    rst <= '0;

  endtask

  //--------------------------------------------------------------------------
  logic                          running;
  logic [ width-1:0 ]            current_data;
  logic [ n_inputs - 1:0 ]       ring_one;
  logic [ data_ptr_width - 1:0 ] data_ptr;
  //Pointer to current valid data input
  always @(posedge clk) begin
    if ( rst ) begin
      data_ptr <= '0;
    end else begin
      if ( running ) begin
        if ( data_ptr >= (n_inputs - 1) ) begin
          data_ptr <= '0;
        end else begin
          data_ptr <= data_ptr + 1'b1;
        end
      end
    end

  end

  //current valid bit
  always_comb begin
    ring_one           = '0;
    if ( running ) begin
      ring_one[data_ptr] = 1'b1;
    end else begin
      ring_one         = '0;
    end   
  end

  //Input data
  always_ff @(posedge clk)
  begin
    if (rst) begin
      current_data <= '0;
    end else begin
      if ( running ) begin
        current_data <= current_data + 1'b1;
      end
    end
  end

  //Generate mock for input data simulation
  genvar i;
  generate
    for ( i = 0; i < n_inputs; i++ ) begin : input_generator
      random_delay #(.width(width), .n_inputs(n_inputs))
      r_delay(
        .clk       ( clk          ),
        .rst       ( rst          ), 
        .vld_in    ( ring_one[i]  ),
        .data_in   ( current_data ),
        .vld_out   ( up_vlds[i]   ),
        .data_out  ( up_data[i]   )
      );
    end
  endgenerate


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
  
    #1000

    running <= 1'b0;

    //Giving time for finishing delays
    #(20*n_inputs + 20)

    if ( current_data != next_expected ) begin
      $warning("Test failed. Expected %d inputs, but get %d", current_data, next_expected);
      $display ("%s FAIL - see above", `__FILE__);
      $finish;
    end

    $display ("%s PASS", `__FILE__);
    $finish;
    
  end
    
  //Check output data
  logic [width-1:0]      next_expected; 
  initial begin

    next_expected <= '0;
    @(!rst);

    forever begin

      @(posedge clk);
      if ( down_vld ) begin
        if ( down_data !== next_expected ) begin
          $warning("Test failed. Expected output %d, but get %d", next_expected, down_data);
          $display ("%s FAIL - see above", `__FILE__);
          #10
          $finish;
        end
        next_expected <= next_expected + 1'b1;
      end
        
    end

  end

endmodule


//This block emulate non-constant processing delay
//Delay variable from 1 to n_input clock cycles
module random_delay
#(
    parameter width    = 16,
              n_inputs = 4
)
(
  input 		              clk,
  input                   rst,
  input                   vld_in,
  input [width-1:0]	      data_in,
  output reg              vld_out,
  output reg [width-1:0]  data_out
);

  int                 delay; 
  logic [ width-1:0 ] data_lock;
  logic               busy; 

  //Input
  initial begin
    data_lock <= '0;
    delay     <= '0;
    
    @(!rst);

    forever begin
      @(posedge vld_in);
      data_lock <= data_in;
      delay     <= $urandom_range(n_inputs, 1);
    end

  end

  //Delay
  initial begin

    busy <= 1'b0;

    forever begin
    
      //wait valid in signal
      @(posedge vld_in);
      //Wait one clock
      //This needed for release busy signal on next clock cycle
      @(posedge clk);
      busy <= 1'b1;

      repeat (delay-1) begin
        @(posedge clk);
      end

      busy <= 1'b0;

    end

  end

//output
  initial begin
    vld_out   <= '0;
    data_out  <= '0;
    @(!rst)

    forever begin

      //Output locked data when finished wait
      @(negedge busy);
      vld_out  <= 1'b1;
      data_out <= data_lock;
      //Hold vld_out for one clk
      @(posedge clk);
      vld_out  <= 1'b0;
  
    end     
  end

  //Self check - repeated vld_in when module in busy state forbidden
  initial begin
    forever begin
      @(posedge clk);
      if (vld_in && busy) begin
        $warning("Repeated vld_in during busy. Current vld_in will be ignored. Time: ", $realtime);
      end
    end
  end

endmodule
