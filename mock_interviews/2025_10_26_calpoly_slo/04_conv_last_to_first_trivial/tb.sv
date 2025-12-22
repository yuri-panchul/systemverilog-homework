module tb;

    localparam int width        = 8;

    localparam bit check_first  = 1,
                   check_last   = 0,
                   use_ready    = 0,
                   use_valid    = 1;

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

    conv_last_to_first
    # (.width (width))
    dut (.*);

    upstream_traffic_generator
    # (.width (width), .use_valid (use_valid))
    upstream (.*);

    //------------------------------------------------------------------------
    // Driving clock

    initial
    begin
        clock = 1'b0;
        forever # 5 clock = ~ clock;
    end

    //------------------------------------------------------------------------
    // Flow control

    always @ (posedge clock)
        down_ready <= $urandom;

    initial
    begin
        if (~ use_ready)
        begin
            force up_ready   = 1'b1;
            force down_ready = 1'b1;
        end

        if (~ use_valid)
            force down_valid = 1'b1;
    end

    //------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clock)
    begin
        $write ("time %7d cycle %5d", $time, cycle);
        cycle <= cycle + 1'b1;

                $write (  "%s", reset                                ? " reset"      : "      "      );

        if (~ reset)
        begin
            if ( use_valid )
                $write (  "%s", up_valid                             ? " up_valid"   : "         "   );

            if ( use_ready )
                $write (  "%s", up_ready                             ? " up_ready"   : "         "   );

            if ( ~ check_first )
                $write (  "%s", up_valid   & up_ready   & up_first   ? " up_first"   : "         "   );

            if ( ~ check_last )
                $write (  "%s", up_valid   & up_ready   & up_last    ? " up_last"    : "        "    );

                $write ( " %s", up_valid & up_ready                  ?   up_data     : " "           );

            if ( use_valid )
                $write (  "%s", down_valid                           ? " down_valid" : "           " );

            if ( use_ready )
                $write (  "%s", down_ready                           ? " down_ready" : "           " );

            if ( check_first )
                $write (  "%s", down_valid & down_ready & down_first ? " down_first" : "           " );

            if ( check_last )
                $write (  "%s", down_valid & down_ready & down_last  ? " down_last"  : "          "  );

                $write ( " %s", down_valid & down_ready              ?   down_data   : " "           );
        end

        $display;
    end

    //------------------------------------------------------------------------
    // Was reset

    logic sticky_reset_r = 1'b0;

    always @ (posedge clock)
        if (reset)
            sticky_reset_r <= 1'b1;

    wire was_reset = sticky_reset_r & ~ reset;

    logic reset_r;

    always @ (posedge clock)
        reset_r <= reset;

    //------------------------------------------------------------------------
    // Transfer occurs

    wire up_transfer
       = up_valid & up_ready === 1'b1;

    wire down_transfer
       = down_valid === 1'b1 & down_ready
         & ~ (~ use_valid & check_last & reset_r);  // Ad-hoc, reconsider

    //------------------------------------------------------------------------
    // Forming strings to output

    string up_flag_c, up_data_c, down_flag_c, down_data_c,
           up_flag_s, up_data_s, down_flag_s, down_data_s;

    always @ (posedge clock)
    begin
        if (was_reset)
        begin
            if (up_transfer)
            begin
                if (check_first)
                    up_flag_c = up_last  ? "L" : " ";
                else
                    up_flag_c = up_first ? "F" : " ";

                $sformat (up_data_c, "%s", up_data);

                up_flag_s = { up_flag_s, up_flag_c };
                up_data_s = { up_data_s,  up_data_c };
            end

            if (down_transfer)
            begin
                if (check_first)
                    down_flag_c = down_first ? "F" : " ";
                else
                    down_flag_c = down_last  ? "L" : " ";

                $sformat (down_data_c, "%s", down_data);

                down_flag_s = { down_flag_s, down_flag_c };
                down_data_s = { down_data_s, down_data_c };
            end
        end
    end

    //------------------------------------------------------------------------
    // Modeling and checking

    logic [width + 2 - 1:0] queue [$];

    logic               expected_valid;
    logic               expected_first;
    logic               expected_last;
    logic [width - 1:0] expected_data;

    // Blocking assignments are okay in this synchronous always block, because
    // data is passed using queue and all the checks are inside that always
    // block, so no race condition is possible

    // verilator lint_off BLKSEQ

    always @ (posedge clock)
    begin
        if (reset)
        begin
            queue = {};
        end
        else if (was_reset)
        begin
            if (up_transfer)
                queue.push_back ({ up_first, up_last, up_data });

            if (down_transfer)
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

        repeat (10)  @ (posedge clock);

        //--------------------------------------------------------------------
        // Checking the queue

        // Width some variants of DUT
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
        // Output strings

        $display ( "up_flag   : %s", up_flag_s   );
        $display ( "up_data   : %s", up_data_s   );
        $display ( "down_flag : %s", down_flag_s );
        $display ( "down_data : %s", down_data_s );

        //--------------------------------------------------------------------
        // Finish

        if (~ err)
            $display ("%s PASS", `__FILE__);

        $finish;
    end

endmodule
