module tb
# (
    parameter width = 4, depth = 4
);

    //------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic clk;
    logic rst;

    // Upstream

    logic               a_valid, b_valid;
    wire                a_ready, b_ready;
    logic [width - 1:0] a_data,  b_data;

    // Downstream

    wire                sum_valid;
    logic               sum_ready;
    wire  [width - 1:0] sum_data;

    //------------------------------------------------------------------------
    // DUT instantiation


    a_plus_b_using_fifos_and_double_buffer
    # (.width (width), .depth (depth))
    dut (.*);

    //------------------------------------------------------------------------
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

    //------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("time %7d cycle %5d", $time, cycle ++);

        if ( rst       ) $write ( " rst"       ); else $write ( "    "       );

        if ( a_valid   ) $write ( " a_valid"   ); else $write ( "        "   );
        if ( a_ready   ) $write ( " a_ready"   ); else $write ( "        "   );

        if (a_valid & a_ready)
            $write (" %h", a_data);
        else
            $write ("  ");

        if ( b_valid   ) $write ( " b_valid"   ); else $write ( "        "   );
        if ( b_ready   ) $write ( " b_ready"   ); else $write ( "        "   );

        if (b_valid & b_ready)
            $write (" %h", b_data);
        else
            $write ("  ");

        if ( sum_valid ) $write ( " sum_valid" ); else $write ( "          " );
        if ( sum_ready ) $write ( " sum_ready" ); else $write ( "          " );

        if (sum_valid & sum_ready)
            $write (" %h", sum_data);
        else
            $write ("  ");

        $display;
    end

    //------------------------------------------------------------------------
    // Modeling and checking

    logic [width - 1:0] a_queue [$], b_queue [$];
    logic [width - 1:0] sum_data_expected;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            a_queue = {};
            b_queue = {};

            was_reset = 1;
        end
        else if (was_reset)
        begin
            if (a_valid & a_ready)
                a_queue.push_back (a_data);

            if (b_valid & b_ready)
                b_queue.push_back (b_data);

            if (sum_valid & sum_ready)
            begin
                if (a_queue.size () == 0 || b_queue.size () == 0)
                begin
                    $display ("\nERROR: unexpected sum %h", sum_data);
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        sum_data_expected = a_queue [0] + b_queue [0];

                        a_queue.delete (0);
                        b_queue.delete (0);
                    `else
                        sum_data_expected = a_queue.pop_front () + b_queue.pop_front ();
                    `endif

                    if (sum_data_expected !== sum_data)
                        $display ("\nERROR: downstream data mismatch. Expected %h, actual %h",
                            sum_data_expected, sum_data);
                end
            end
        end
    end

    //------------------------------------------------------------------------
    // Check at the end of simulation

    final
    begin
        if (a_queue.size () != 0)
        begin
            $write ("\nERROR: data is left sitting in the model a_queue:");

            for (int i = 0; i < a_queue.size (); i ++)
                $write (" %h", a_queue [a_queue.size () - i - 1]);

            $display;
        end

        if (b_queue.size () != 0)
        begin
            $write ("\nERROR: data is left sitting in the model b_queue:");

            for (int i = 0; i < b_queue.size (); i ++)
                $write (" %h", b_queue [b_queue.size () - i - 1]);

            $display;
        end
    end

    //----------------------------------------------------------------------
    // Performance counters

    logic [32:0] n_cycles, a_count, b_count, sum_count;

    always @ (posedge clk)
        if (rst)
        begin
            n_cycles  <= '0;
            a_count   <= '0;
            b_count   <= '0;
            sum_count <= '0;
        end
        else
        begin
            n_cycles <= n_cycles + 1'd1;

            if ( a_valid   & a_ready   ) a_count   <= a_count   + 1'd1;
            if ( b_valid   & b_ready   ) b_count   <= b_count   + 1'd1;
            if ( sum_valid & sum_ready ) sum_count <= sum_count + 1'd1;
        end

    //----------------------------------------------------------------------

    final
    begin
        $display ("\n\nnumber of sum transfers : %0d per %0d cycles",
            sum_count, n_cycles);

        if (a_count != b_count | a_count != sum_count)
            $display ("\nERROR: number of transfers do not match: a: %0d b: %0s sum %0d",
                a_count, b_count, sum_count);
    end

    //------------------------------------------------------------------------
    // Driving reset and control signals

    localparam max_transfers = 100;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following `define
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        //--------------------------------------------------------------------
        // Initialization

        a_valid   <= 1'b0;
        b_valid   <= 1'b0;
        sum_ready <= 1'b0;

        //--------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //--------------------------------------------------------------------

        $display ("*** Run back-to-back");

        a_valid   <= 1'b1;
        b_valid   <= 1'b1;
        sum_ready <= 1'b1;

        repeat (20) @ (posedge clk);

        $display ("*** Supplying only \"a\"");

        // b_valid is still 1

        while (~ b_ready)  // Make sure b_valid went through
            @ (posedge clk);

        b_valid <= 1'b0;

        repeat (20) @ (posedge clk);

        $display ("*** Supplying only \"b\"");

        b_valid <= 1'b1;

        // a_valid is still 1

        while (~ a_ready)  // Make sure a_valid went through
            @ (posedge clk);

        a_valid  <= 1'b0;

        repeat (20) @ (posedge clk);

        $display ("*** Applying backpressure");

        a_valid   <= 1'b1;
        b_valid   <= 1'b1;
        sum_ready <= 1'b0;

        repeat (20) @ (posedge clk);

        $display ("*** Random");

        while (sum_count != max_transfers)
        begin
            // If this assertion fails, it is an internal error in the testbench
            assert (a_count <= max_transfers);

            if (   a_count == max_transfers
                    | (a_count == max_transfers - 1 & a_valid & a_ready))
            begin
                a_valid <= '0;
            end
            else if (~ a_valid | a_ready)
            begin
                a_valid <= $urandom ();
            end

            // If this assertion fails, it is an internal error in the testbench
            assert (b_count <= max_transfers);

            if (   b_count == max_transfers
                    | (b_count == max_transfers - 1 & b_valid & b_ready))
            begin
                b_valid <= '0;
            end
            else if (~ b_valid | b_ready)
            begin
                b_valid <= $urandom ();
            end

            sum_ready <= $urandom ();

            @ (posedge clk);
        end

        $display ("*** Draining the results");

        sum_ready <= 1'b1;
        repeat (depth * 2 + 3) @ (posedge clk);

        $display ("%s PASS", `__FILE__);
        $finish;
    end

    //------------------------------------------------------------------------
    // Driving data

    always @ (posedge clk)
        if (rst)
            a_data <= '0;
        else if (a_valid & a_ready)
            a_data <= $urandom;

    always @ (posedge clk)
        if (rst)
            b_data <= '0;
        else if (b_valid & b_ready)
            b_data <= $urandom;

endmodule
