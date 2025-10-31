module tb;

    localparam int width            = 8;

    localparam bit check_first      = 0,
                   check_last       = 1,
                   use_backpressure = 1;

    bit err;

    //------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic                clock;
    logic                reset;

    logic                up_enable;
    logic                up_valid;
    wire                 up_ready;
    logic                up_first;
    logic                up_last;
    logic  [width - 1:0] up_data;

    wire                 down_valid;
    logic                down_ready;
    wire                 down_first;
    wire                 down_last;
    wire   [width - 1:0] down_data;

    //------------------------------------------------------------------------
    // DUT instantiation

    conv_first_to_last
    # (.width (width))
    dut (.*);

    upstream_traffic_generator
    # (.width (width))
    upstream (.*);

    //------------------------------------------------------------------------
    // Driving clock

    initial
    begin
        clock = 1'b0;
        forever # 5 clock = ~ clock;
    end

    //------------------------------------------------------------------------
    // Driving down_ready

    always @ (posedge clock)
        down_ready <= $urandom | ~ use_backpressure;

    //------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clock)
    begin
        $write ("time %7d cycle %5d", $time, cycle);
        cycle <= cycle + 1'b1;

        if ( reset                                ) $write ( " reset"      ); else $write ( "      "      );

        if ( up_valid                             ) $write ( " up_valid"   ); else $write ( "         "   );
        if ( up_ready                             ) $write ( " up_ready"   ); else $write ( "         "   );

        if ( ~ check_first )
        begin
        if ( up_valid   & up_ready   & up_first   ) $write ( " up_first"   ); else $write ( "         "   );
        end

        if ( ~ check_last )
        begin
        if ( up_valid   & up_ready   & up_last    ) $write ( " up_last"    ); else $write ( "        "    );
        end

        if (up_valid & up_ready)
            $write (" %s", up_data);
        else
            $write ("  ");

        if ( down_valid                           ) $write ( " down_valid" ); else $write ( "           " );

        if (use_backpressure)
        begin
        if ( down_ready                           ) $write ( " down_ready" ); else $write ( "           " );
        end

        if ( check_first )
        begin
        if ( down_valid & down_ready & down_first ) $write ( " down_first" ); else $write ( "           " );
        end

        if ( check_last )
        begin
        if ( down_valid & down_ready & down_last  ) $write ( " down_last"  ); else $write ( "          "  );
        end

        if (down_valid & down_ready)
            $write (" %s", down_data);
        else
            $write ("  ");

        $display;
    end

    //------------------------------------------------------------------------
    // Modeling and checking

    logic [width + 2 - 1:0] queue [$];

    logic               expected_valid;
    logic               expected_first;
    logic               expected_last;
    logic [width - 1:0] expected_data;

    logic was_reset = 0;

    // Blocking assignments are okay in this synchronous always block, because
    // data is passed using queue and all the checks are inside that always
    // block, so no race condition is possible

    // verilator lint_off BLKSEQ

    always @ (posedge clock)
    begin
        if (reset)
        begin
            queue = {};
            was_reset = 1'b1;
        end
        else if (was_reset)
        begin
            if (up_valid & up_ready === 1'b1)
                queue.push_back ({ up_first, up_last, up_data });

            if (down_valid === 1'b1 & down_ready)
            begin
                if (queue.size () == 0)
                begin
                    $display ("\nERROR: unexpected down_data %h", down_data);
                    err = 1;
                end
                else
                begin
                    { expected_first,
                      expected_last,
                      expected_data  } = queue.pop_front ();

                    if (expected_data !== down_data)
                    begin
                        $display ("\nERROR: downstream data mismatch. Expected %s (%h), actual %s (%h)",
                            expected_data, expected_data, down_data, down_data);

                        err = 1;
                    end

                    if (check_first & expected_first !== down_first)
                    begin
                        $display ("\nERROR: downstream first flag mismatch. Expected %b, actual %b. Data: %s (%h)",
                            expected_first, down_first, down_data, down_data);

                        err = 1;
                    end

                    if (check_last & expected_last !== down_last)
                    begin
                        $display ("\nERROR: downstream last flag mismatch. Expected %b, actual %b. Data: %s (%h)",
                            expected_last, down_last, down_data, down_data);

                        err = 1;
                    end
                end
            end
        end
    end

    // verilator lint_on BLKSEQ

    //------------------------------------------------------------------------
    // Performance counters

    logic [32:0] n_cycles, up_count, down_count;

    always @ (posedge clock)
    begin
        if (reset)
        begin
            n_cycles   <= '0;
            up_count   <= '0;
            down_count <= '0;
        end
        else
        begin
            n_cycles <= n_cycles + 1'd1;

            if ( up_valid   & up_ready   ) up_count   <= up_count   + 1'd1;
            if ( down_valid & down_ready ) down_count <= down_count + 1'd1;
        end
    end

    //------------------------------------------------------------------------
    // Check at the end of simulation

    final
    begin
        $display ("\n\nnumber of transfers : %0d per %0d cycles",
            down_count, n_cycles);

        // Width this particular DUT
        // we may have 1 extra up_count at the end of simulation.

        if (  up_count != down_count
            & up_count != down_count + 1)
        begin
            $display ("\nERROR: number of transfers do not match: up: %0d down: %0d",
                up_count, down_count);

            err = 1;
        end

        if (err)
            $display ("%s FAIL", `__FILE__);
    end

    //------------------------------------------------------------------------
    // Driving reset and control signals

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following `define
            // to generate a VCD file and analyze it using GTKwave

            $dumpvars;
        `endif

        //--------------------------------------------------------------------
        // Initialization

        up_enable = 1'b1;

        //--------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clock);
        reset <= '1;
        repeat (3) @ (posedge clock);
        reset <= '0;

        //--------------------------------------------------------------------
        // Driving stimuli

        repeat (100) @ (posedge clock);

        up_enable = 1'b0;

        repeat (100) @ (posedge clock);

        //--------------------------------------------------------------------
        // Checking the queue

        // Width this particular DUT
        // we may have 1 item sitting in the queue at the end of simulation.

        if (queue.size () > 1)
        begin
            $write ("\nERROR: data is left sitting in the model queue:");

            for (int i = 0; i < queue.size (); i ++)
            begin
                { expected_first,
                  expected_last,
                  expected_data  } = queue [queue.size () - i - 1];

                if ( expected_first ) $write ( " first" ); else $write ( "      " );
                if ( expected_last  ) $write ( " last"  ); else $write ( "     "  );

                $display (" %s (%h)", expected_data, expected_data);
            end

            $display;

            err = 1;
        end

        //--------------------------------------------------------------------
        // Finish

        if (~ err)
            $display ("%s PASS", `__FILE__);

        $finish;
    end

endmodule
