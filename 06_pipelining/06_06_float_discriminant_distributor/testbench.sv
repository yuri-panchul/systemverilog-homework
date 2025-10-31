//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

`include "util.svh"

module testbench;

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic               clk;
    logic               rst;

    logic               arg_vld;
    logic  [FLEN - 1:0] a;
    logic  [FLEN - 1:0] b;
    logic  [FLEN - 1:0] c;

    wire                res_vld;
    wire   [FLEN - 1:0] res;
    wire                res_negative;
    wire                err;

    wire                busy;

    //--------------------------------------------------------------------------

    // If we change FLEN to 32, we have to change these constants

    localparam [FLEN - 1:0] inf     = 64'h7FF0_0000_0000_0000,
                            neg_inf = 64'hFFF0_0000_0000_0000,
                            zero    = 64'h0000_0000_0000_0000,
                            nan     = 64'h7FF1_2345_6789_ABCD;

    //--------------------------------------------------------------------------
    // Instantiating DUT

    localparam PIPE        = 0,
               FSM         = 0,
               DISTRIBUTOR = 1,
               MOCKUP      = 0,
               DEFECTIVE   = 0;

    generate

        if (! PIPE && FSM == 1)
            float_discriminant_fsm1_top FSM1_DUT (.*);
        else if (! PIPE && FSM == 2)
            float_discriminant_fsm2_top FSM2_DUT (.*);
        else if (! PIPE && FSM == 3)
            float_discriminant_fsm3 FSM3_DUT (.*);
        else if (PIPE)
           // pipelined register = 0, shift registers = 1, ring buffer = 2
           float_discriminant_pipelined # (.reg_type (2)) PIPE_DUT (.*);
        else if (DISTRIBUTOR)
           float_discriminant_distributor DISTRIBUTOR_DUT (.*);
        else if (MOCKUP == 1)
           float_discriminant_behavioral_mockup MOCKUP_DUT (.*);
        else if (DEFECTIVE == 1)
           float_discriminant_passes_but_defective DEFECT_DUT (.*);
        else
           float_discriminant DUT (.*);

    endgenerate

    //--------------------------------------------------------------------------
    // Driving clk

    initial
    begin
        clk = '1;

        forever
        begin
            # 5 clk = ~ clk;
        end
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
    // Test ID for error messages

    string test_id;

    initial $sformat (test_id, "%s", `__FILE__);

    //--------------------------------------------------------------------------
    // Utilities to drive stimulus

    localparam max_latency       = 16,
               gap_between_tests = 100;

    function int randomize_gap ();

        int gap_class;

        gap_class = $urandom_range (1, 100);

        if (gap_class <= 60)       // With a 60% probability: without gaps
            return 0;
        else if (gap_class <= 95)  // With a 35% probability: gap 1..3
            return $urandom_range (1, 3);
        else                       // With a  5% probability: gap 4..max_latency + 2
            return $urandom_range (4, max_latency + 2);

    endfunction

    //--------------------------------------------------------------------------

    task drive_arg_vld_and_wait_res_vld_if_necessary
    (
        bit random_gap = 0,
        int gap        = 0
    );

        arg_vld <= 1'b1;
        @ (posedge clk);
        arg_vld <= 1'b0;

        if (! (PIPE || DISTRIBUTOR))
        begin
            while (~ res_vld)
                @ (posedge clk);
        end

        if (random_gap)
            gap = randomize_gap ();

        repeat (gap) @ (posedge clk);

    endtask

    //--------------------------------------------------------------------------

    task make_gap_between_tests ();

        repeat (max_latency + gap_between_tests)
            @ (posedge clk);

    endtask

    //--------------------------------------------------------------------------
    // Driving stimulus

    localparam TIMEOUT = 5000;

    //--------------------------------------------------------------------------

    task run ();

        `ifdef USE_FORK_JOIN_NONE

        // Setting timeout against hangs

        fork
        begin
            repeat (TIMEOUT) @ (posedge clk);
            $display ("FAIL %s: timeout!", test_id);
            $finish;
        end
        join_none

        `endif

        $display ("--------------------------------------------------");
        $display ("Running %m");

        // Init and reset

        arg_vld <= '0;
        reset ();

        // Direct testing - a single test

        a <= $realtobits ( 1 );
        b <= $realtobits ( 4 );
        c <= $realtobits ( 3 );

        drive_arg_vld_and_wait_res_vld_if_necessary ();
        make_gap_between_tests ();

        // Verify for nan and inf - a single test

        // nan => reports error; inf => doesn't report error
        a <= $realtobits ( 1 );
        b <= nan; // inf;
        c <= $realtobits ( 4 );

        drive_arg_vld_and_wait_res_vld_if_necessary ();
        make_gap_between_tests ();

        // Direct testing - a group of tests

        for (int i = 0; i < 100; i = i * 3 + 1)
        begin
            a <= $realtobits ( i );
            b <= $realtobits ( i+10 );
            c <= $realtobits ( i );

            drive_arg_vld_and_wait_res_vld_if_necessary
            (
                0,      // random_gap
                i / 10  // gap
            );
        end

        make_gap_between_tests ();

        // Random testing

        repeat (10)
        begin
            a <= $realtobits ( $urandom () / 1000.0 ) ;
            b <= $realtobits ( $urandom () / 1000.0 ) ;
            c <= $realtobits ( $urandom () / 1000.0 ) ;

            drive_arg_vld_and_wait_res_vld_if_necessary (1); // random_gap
        end

        make_gap_between_tests ();

        `ifdef USE_FORK_JOIN_NONE

            // Disabling timeout check
            disable fork;

        `endif

    endtask

    //--------------------------------------------------------------------------
    // Running testbench

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        run ();

        $finish;
    end

    //--------------------------------------------------------------------------
    // Utility tasks and functions

    function is_err ( [FLEN - 1:0] a_bits );
        return a_bits [FLEN - 2 -: NE] === '1;
    endfunction

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("%s time %7d cycle %5d", test_id, $time, cycle);
        cycle <= cycle + 1'b1;

        if (rst)
            $write (" rst");
        else
            $write ("    ");

        if (arg_vld)
            // Optionnaly change to `PF_BITS optionally
            $write (" arg %s %s %s", `PG_BITS (a), `PG_BITS (b), `PG_BITS (c) );
        else
            $write ("                                     ");

        if (res_vld)
            $write (" res %s", `PG_BITS(res) );

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    logic [FLEN - 1:0] queue [$];
    logic [FLEN - 1:0] res_expected;
    logic              err_expected;

    logic was_reset = 0;

    // Blocking assignments are okay in this synchronous always block, because
    // data is passed using queue and all the checks are inside that always
    // block, so no race condition is possible

    // verilator lint_off BLKSEQ

    always @ (posedge clk)
    begin
        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            if (arg_vld)
            begin
                res_expected = $realtobits( $bitstoreal (b) * $bitstoreal (b) - 4 * $bitstoreal (a) * $bitstoreal (c) );

                queue.push_back (res_expected);
            end

            if (res_vld)
            begin
                if (queue.size () == 0)
                begin
                    $display ("FAIL %s: unexpected result %s",
                        test_id, `PG_BITS (res) );

                    $finish;
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        res_expected = queue [0];
                        queue.delete (0);
                    `else
                        res_expected = queue.pop_front ();
                    `endif

                    err_expected = is_err ( res_expected );

                    // TODO

                    if (0) // We need to temporary disable checking for errors
                    // if (err !== err_expected )
                    begin
                        $display ("FAIL %s: error mismatch. Expected %s, actual %s",
                            test_id, `PB (err_expected), `PB (err) );

                        $finish;
                    end
                    else if ( ( err_expected === 1'b0 ) && ( res !== res_expected ) )
                    begin
                        $display ("FAIL %s: res mismatch. Expected %s, actual %s",
                            test_id, `PG_BITS (res_expected), `PG_BITS (res) );

                        $finish;
                    end
                end
            end
        end
    end

    // verilator lint_on BLKSEQ

    //----------------------------------------------------------------------

    final
    begin
        if (queue.size () == 0)
        begin
            $display ("PASS %s", test_id);
        end
        else
        begin
            $write ("FAIL %s: data is left sitting in the model queue:",
                test_id);

            for (int i = 0; i < queue.size (); i ++)
                $write (" %h", queue [queue.size () - i - 1]);

            $display;
        end
    end

    //----------------------------------------------------------------------
    // Performance counters

    logic [32:0] n_cycles, arg_cnt, res_cnt;

    always @ (posedge clk)
        if (rst)
        begin
            n_cycles <= '0;
            arg_cnt  <= '0;
            res_cnt  <= '0;
        end
        else
        begin
            n_cycles <= n_cycles + 1'd1;

            if (arg_vld)
                arg_cnt <= arg_cnt + 1'd1;

            if (res_vld)
                res_cnt <= res_cnt + 1'd1;
        end

    //----------------------------------------------------------------------

    final
        $display ("\n\nnumber of transfers : arg %0d res %0d per %0d cycles",
            arg_cnt, res_cnt, n_cycles);

    //----------------------------------------------------------------------
    // Setting timeout against hangs

    initial
    begin
        repeat (TIMEOUT) @ (posedge clk);
        $display ("FAIL %s: timeout!", test_id);
        $finish;
    end

endmodule
