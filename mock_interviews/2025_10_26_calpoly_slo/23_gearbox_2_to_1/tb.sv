module tb
# (
  parameter width = 8
);

  //--------------------------------------------------------------------------
  // Signals to drive Device Under Test - DUT

  logic clk;
  logic rst;

  // Upstream

  logic                   up_vld;
  wire                    up_rdy;
  logic [2 * width - 1:0] up_data;

  // Downstream

  wire                    down_vld;
  logic                   down_rdy;
  wire  [    width - 1:0] down_data;

  //--------------------------------------------------------------------------
  // DUT instantiation

  gearbox_2_to_1 # (.width (width)) dut (.*);

  //--------------------------------------------------------------------------
  // Driving clock

  initial
  begin
    clk = '1;
    forever #5 clk = ~ clk;
  end

  initial
  begin
    repeat (10000) @ (posedge clk);
    $display ("Timeout!");
    $finish;
  end

  //--------------------------------------------------------------------------
  // Driving reset and control signals

  initial
  begin
    `ifdef __ICARUS__
      $dumpvars;
    `endif

    //------------------------------------------------------------------------
    // Force overrides: you can use it for the initial debug

    // force down_rdy = 1'b1;

    //------------------------------------------------------------------------
    // Initialization

    up_vld   <= 1'b0;
    down_rdy <= 1'b0;

    //------------------------------------------------------------------------
    // Reset

    repeat (3) @ (posedge clk);
    rst <= '1;
    repeat (3) @ (posedge clk);
    rst <= '0;

    //------------------------------------------------------------------------

    $display ("*** Run back-to-back");

    up_vld   <= 1'b1;
    down_rdy <= 1'b1;

    repeat (10) @ (posedge clk);

    $display ("*** Random up_vld and down_rdy");

    repeat (50)
    begin
      if (~ up_vld | up_rdy)
        up_vld <= $urandom ();

      down_rdy <= $urandom ();

      @ (posedge clk);
    end

    $display ("*** Draining the pipeline: up_vld=0, down_rdy=1");

    down_rdy <= 1'b1;

    while (up_vld & ~ up_rdy)  // Need to keep up_vld until up_rdy
      @ (posedge clk);

    up_vld <= 1'b0;

    repeat (10) @ (posedge clk);

    //------------------------------------------------------------------------

    $finish;
  end

  //--------------------------------------------------------------------------
  // Driving data

  always @ (posedge clk)
    if (rst)
    begin
      up_data <= "AB";
    end
    else if (up_vld & up_rdy)
    begin
      up_data [15:8] <= $urandom_range ("A", "Z");
      up_data [ 7:0] <= $urandom_range ("A", "Z");
    end

  //--------------------------------------------------------------------------
  // Logging

  int unsigned cycle = 0;

  always @ (posedge clk)
  begin
    $write ("time %7d cycle %5d", $time, cycle ++);

    if ( rst      ) $write ( " rst"      ); else $write ( "    "      );

    if ( up_vld   ) $write ( " up_vld"   ); else $write ( "       "   );
    if ( up_rdy   ) $write ( " up_rdy"   ); else $write ( "       "   );

    if (up_vld & up_rdy)
      $write (" %s", up_data);
    else
      $write ("   ");

    if ( down_vld ) $write ( " down_vld" ); else $write ( "         " );
    if ( down_rdy ) $write ( " down_rdy" ); else $write ( "         " );

    if (down_vld & down_rdy)
      $write (" %s", down_data);
    else
      $write ("  ");

    $display;
  end

  //--------------------------------------------------------------------------
  // Modeling and checking

  logic [width - 1:0] queue_up [$], queue_down [$];
  logic [width - 1:0] down_data_expected;

  // Additional signals to have the comparison on the waveform

  logic comparison_moment;
  logic [width - 1:0] down_data_compared;

  logic was_reset = 0;

  always @ (posedge clk)
  begin
    comparison_moment = '0;

    if (rst)
    begin
      queue_up   = {};
      queue_down = {};

      was_reset  = 1;
    end
    else if (was_reset)
    begin
      if (up_vld & up_rdy)
      begin
        queue_up.push_back (up_data [15:8]);
        queue_up.push_back (up_data [ 7:0]);
      end

      if (down_vld & down_rdy)
        queue_down.push_back (down_data);

      if (   queue_up   .size () > 0
          && queue_down .size () > 0)
      begin
        if (queue_down [0] != queue_up [0])
          $display ("ERROR: downstream data mismatch. Expected %s, actual %s",
            queue_up [0], queue_down [0]);

        // Additional assignments to have the comparison on the waveform

        comparison_moment  <= '1;

        down_data_expected <= queue_up   [0];
        down_data_compared <= queue_down [0];

        queue_up   .delete (0);
        queue_down .delete (0);
      end
    end
  end

  //----------------------------------------------------------------------

  final
  begin
    if (queue_up.size () != 0)
    begin
      $write ("ERROR: data is left sitting in the model upstream queue:");

      for (int i = 0; i < queue_up.size (); i ++)
        $write (" %s", queue_up [queue_up.size () - i - 1]);

      $display;
    end

    if (queue_down.size () != 0)
    begin
      $write ("ERROR: data is left sitting in the model downstream queue:");

      for (int i = 0; i < queue_down.size (); i ++)
        $write (" %s", queue_down [queue_down.size () - i - 1]);

      $display;
    end
  end

  //----------------------------------------------------------------------
  // Performance counters

  logic [32:0] n_cycles, up_cnt, down_cnt;

  always @ (posedge clk)
    if (rst)
    begin
      n_cycles <= '0;
      up_cnt   <= '0;
      down_cnt <= '0;
    end
    else
    begin
      n_cycles <= n_cycles + 1'd1;

      if (up_vld & up_rdy)
        up_cnt <= up_cnt + 1'd1;

      if (down_vld & down_rdy)
        down_cnt <= down_cnt + 1'd1;
    end

  //----------------------------------------------------------------------

  final
    $display ("\n\nnumber of transfers : up %0d down %0d per %0d cycles",
      up_cnt, down_cnt, n_cycles);

endmodule
