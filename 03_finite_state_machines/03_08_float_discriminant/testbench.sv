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
    // Instantiating DUT

    float_discriminant dut (.*);

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
    // Driving stimulus

    localparam TIMEOUT = 5000;

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

        a       <= $realtobits ( 1 );
        b       <= $realtobits ( 4 );
        c       <= $realtobits ( 3 );
        arg_vld <= '1;

        @ (posedge clk);
        arg_vld <= '0;

        while (~ res_vld)
            @ (posedge clk);

        // Direct testing - a group of tests

        for (int i = 0; i < 100; i = i * 3 + 1)
        begin
            a       <= $realtobits ( i );
            b       <= $realtobits ( i+10 );
            c       <= $realtobits ( i );
            arg_vld <= '1;

            @ (posedge clk);
            arg_vld <= '0;

            while (~ res_vld)
                @ (posedge clk);
        end

        // Random testing

        repeat (10)
        begin
            a       <= $realtobits ( $urandom () / 1000.0 ) ;
            b       <= $realtobits ( $urandom () / 1000.0 ) ;
            c       <= $realtobits ( $urandom () / 1000.0 ) ;
            arg_vld <= '1;

            @ (posedge clk);
            arg_vld <= '0;

            while (~ res_vld)
                @ (posedge clk);
        end

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
                    if (err !== err_expected )
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
