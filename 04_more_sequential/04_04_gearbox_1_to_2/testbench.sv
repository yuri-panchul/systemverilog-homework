module testbench
# (
    parameter width = 8
);

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic clk;
    logic rst;

    // Upstream

    logic                   up_vld;
    logic [    width - 1:0] up_data;

    // Downstream

    wire                    down_vld;
    wire  [2 * width - 1:0] down_data;

    //--------------------------------------------------------------------------
    // DUT instantiation

    gearbox_1_to_2 # (.width (width)) dut (.*);

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
        $display ("FAIL %s: timeout!", `__FILE__);
        $finish;
    end

    //--------------------------------------------------------------------------
    // Driving reset and control signals

    initial
    begin
        `ifdef __ICARUS__
                // Uncomment the following line
                // to generate a VCD file and analyze it using GTKwave or Surfer

                // $dumpvars;
        `endif

        //------------------------------------------------------------------------
        // Initialization

        up_vld   <= 1'b0;

        //------------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //------------------------------------------------------------------------

        $display ("*** Run back-to-back");

        up_vld   <= 1'b1;

        repeat (10) @ (posedge clk);

        up_vld <= 1'b0;

        @ (posedge clk);

        $display ("*** Random up_vld");

        repeat (50)
        begin
            up_vld <= 1'b1;

            @ (posedge clk);

            up_vld <= 1'b0;

            repeat ( $urandom_range (1, 2) ) @ (posedge clk);
        end

        up_vld <= 1'b0;

        repeat (10) @ (posedge clk);

        //------------------------------------------------------------------------

        $finish;
    end

    //--------------------------------------------------------------------------
    // Driving data

    always @ (posedge clk)
        if (rst)
            up_data <= "A";
        else if (up_vld)
            up_data <= $urandom_range ("A", "Z");

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("time %7d cycle %5d", $time, cycle ++);

        if ( rst    ) $write ( " rst"      ); else $write ( "    "      );

        if ( up_vld ) $write ( " up_vld"   ); else $write ( "       "   );

        if ( up_vld )
            $write (" %s", up_data);
        else
            $write ("  ");

        if ( down_vld ) $write ( " down_vld" ); else $write ( "         " );

        if ( down_vld )
            $write (" %s", down_data);
        else
            $write ("   ");

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    logic [    width - 1:0] queue [$];
    logic [2 * width - 1:0] down_data_expected;

    // Additional signals to have the comparison on the waveform

    logic comparison_moment;
    logic [2 * width - 1:0] down_data_compared;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        comparison_moment = '0;

        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            if (up_vld)
                queue.push_back (up_data);

            if (down_vld)
            begin
                if (queue.size () < 2)
                begin
                    $display ("FAIL %s: unexpected downstream data %s", `__FILE__, down_data);
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        down_data_expected = { queue [0], queue [1] };
                        queue.delete (0);
                        queue.delete (0);
                    `else
                        down_data_expected = { queue.pop_front (), queue.pop_front () };
                    `endif

                    if (down_data !== down_data_expected)
                        $display ("FAIL %s: downstream data mismatch. Expected %s, actual %s",
                            `__FILE__, down_data_expected, down_data);

                    // Additional assignments to have the comparison on the waveform

                    comparison_moment  <= '1;
                    down_data_compared <= down_data;
                end
            end
        end
    end

    //----------------------------------------------------------------------

    final
    begin
        if (queue.size () != 0)
        begin
            $write ("FAIL %s: data is left sitting in the model queue:", `__FILE__);

            for (int i = 0; i < queue.size (); i ++)
                $write (" %s", queue [queue.size () - i - 1]);

            $display;
        end
        else
        begin
            $display;
            $display ("PASS %s", `__FILE__);
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

            if ( up_vld   )
                up_cnt <= up_cnt + 1'd1;

            if ( down_vld )
                down_cnt <= down_cnt + 1'd1;
        end

    //----------------------------------------------------------------------

    final
        $display ("\n\nINFO %s: Number of transfers : up %0d down %0d per %0d cycles",
            `__FILE__, up_cnt, down_cnt, n_cycles);

endmodule
