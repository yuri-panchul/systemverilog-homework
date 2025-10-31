//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

`include "util.svh"

module testbench;

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic                   clk;
    logic                   rst;

    logic                   arg_vld;
    logic      [FLEN - 1:0] a;
    logic      [FLEN - 1:0] b;
    logic      [FLEN - 1:0] c;

    wire                    res_vld;
    wire  [0:2][FLEN - 1:0] res;
    wire                    err;
    wire                    busy;

    wire       [FLEN - 1:0] f_a;
    wire       [FLEN - 1:0] f_b;
    wire                    f_res;
    wire                    f_err;

    //--------------------------------------------------------------------------
    // Instantiating DUT

    f_less_or_equal f_le (
        .a   ( f_a   ),
        .b   ( f_b   ),
        .res ( f_res ),
        .err ( f_err )
    );

    sort_floats_using_fsm sort_floats_using_fsm (
        .clk       ( clk     ),
        .rst       ( rst     ),

        .valid_in  ( arg_vld ),
        .unsorted  ( { a, b, c } ),

        .valid_out ( res_vld ),
        .sorted    ( res     ),
        .err       ( err     ),
        .busy      (         ),

        .f_le_a    ( f_a     ),
        .f_le_b    ( f_b     ),
        .f_le_res  ( f_res   ),
        .f_le_err  ( f_err   )
    );

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
    // Stimulus data

    localparam N = 7;

    // If we change FLEN to 32, we have to use $shortrealtobits

    localparam [FLEN - 1:0] inf     = 64'h7FF0_0000_0000_0000,
                            neg_inf = 64'hFFF0_0000_0000_0000,
                            zero    = 64'h0000_0000_0000_0000,
                            nan     = 64'h7FF1_2345_6789_ABCD;

    logic [0:N - 1][FLEN - 1:0] nums =
    {
        zero,
        $realtobits ( 1     ),
        $realtobits ( 2.34  ),
        $realtobits ( 5.6e5 ),
        $realtobits ( 8e-7  ),
        inf,
        nan
    };

    function [FLEN - 1:0] rand_from_num ();

        return   ($urandom_range (0, 1) << (FLEN - 1))
               | nums [$urandom_range (0, N - 1)];

    endfunction

    //--------------------------------------------------------------------------
    // Driving stimulus

    task test (input [FLEN - 1:0] ta, tb, tc);

        a       <= ta;
        b       <= tb;
        c       <= tc;
        arg_vld <= '1;

        @ (posedge clk);

        arg_vld <= '0;

        while (~ res_vld)
            @ (posedge clk);

    endtask

    //--------------------------------------------------------------------------

    // We expect combinations of 3 numbers with both + and -,
    // plus N * 100 random combinations,
    // and we expect every FSM iteration take no more than 10 clock cycles,
    // plus 1000 clock cycles just in case.

    localparam TIMEOUT = ((N * 2) ** 3 + N * 100 * 2) * 10 + 1000;

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

        test
        (
            $realtobits ( 1.0 ),
            $realtobits ( 4.0 ),
            $realtobits ( 9.0 )
        );

        `ifdef ALL_COMBINATIONS

        // Direct testing - a group of tests

        for (int i  = 0; i  <  N; i  ++)
        for (int j  = 0; j  <  N; j  ++)
        for (int k  = 0; k  <  N; k  ++)
        for (int si = 0; si <= 1; si ++)
        for (int sj = 0; sj <= 1; sj ++)
        for (int sk = 0; sk <= 1; sk ++)
            test
            (
               (si << (FLEN - 1)) | nums [i],
               (sj << (FLEN - 1)) | nums [j],
               (sk << (FLEN - 1)) | nums [k]
            );

        `endif

        repeat (N * 100)
            test
            (
               rand_from_num (),
               rand_from_num (),
               rand_from_num ()
            );


        repeat (N * 100)
            test
            (
                { 32' ($urandom ()), 32' ($urandom ()) },
                { 32' ($urandom ()), 32' ($urandom ()) },
                { 32' ($urandom ()), 32' ($urandom ()) }
            );

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

    function string format_result ( input [0:2][FLEN - 1:0] result );
        string result_str;
        $sformat (result_str, "%s %s %s",
                    `PG_BITS( result[0] ),
                    `PG_BITS( result[1] ),
                    `PG_BITS( result[2] ));
        return result_str;
    endfunction

    function is_err ( [FLEN - 1:0] a_bits );
        return a_bits [FLEN - 2 -: NE] === '1;
    endfunction

    task fsort3 (inout [0:2][FLEN - 1:0] arr);
        repeat (3 - 1)
            for (int i = 0; i < 3 - 1; i ++)
                if ($bitstoreal (arr [i]) > $bitstoreal (arr [i + 1]))
                    { arr [i], arr [i + 1] } = { arr [i + 1], arr [i] };
    endtask

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
            $write (" arg %s %s %s", `PG_BITS ( a ), `PG_BITS ( b ), `PG_BITS ( c ) );
        else
            $write ("                                     ");

        if (res_vld)
            $write (" res %s", format_result ( res ) );

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    // This queue carries both the expected value and error status
    logic [FLEN * 3 + 1 - 1:0] queue [$];

    logic [0:2][FLEN - 1:0] res_expected;
    logic                   err_expected;

    logic was_reset = 0;

    //--------------------------------------------------------------------------

    function farr_eq3 (input [0:2][FLEN - 1:0] arr_a, arr_b);

        logic [FLEN - 1:0] a, b;
        logic both_zeros;

        for (int i = 0; i < $size (arr_a); i ++)
        begin
            a = arr_a [i];
            b = arr_b [i];

            both_zeros =    { a [FLEN - 2:0] , b [FLEN - 2:0] } === '0
                         && ( a [FLEN - 1  ] ^ b [FLEN - 1  ] ) !== 'x;

            if (a !== b && ! both_zeros)
                return 0;
        end

        return 1;

    endfunction

    //--------------------------------------------------------------------------

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
                res_expected = { a, b, c };
                fsort3 ( res_expected );

                queue.push_back
                ({
                    res_expected,
                    (is_err (a) | is_err (b) | is_err (c))
                });
            end

            if (res_vld)
            begin
                if (queue.size () == 0)
                begin
                    $display ("FAIL %s: unexpected result %s %s",
                        test_id, format_result ( res ), `PB(err));

                    $finish;
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        { res_expected, err_expected } = queue [0];
                        queue.delete (0);
                    `else
                        { res_expected, err_expected } = queue.pop_front ();
                    `endif

                    if (err !== err_expected)
                    begin
                        $display ("FAIL %s: error mismatch. Expected %s, actual %s",
                            test_id, `PB(err_expected), `PB(err));

                        $finish;
                    end
                    else if (   (err_expected === 1'b0)
                             && ! farr_eq3 (res, res_expected))
                    begin
                        $display ("FAIL %s: res mismatch. Expected %s, actual %s",
                            test_id, format_result (res_expected), format_result (res) );

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
            begin
                { res_expected, err_expected } = queue [queue.size () - i - 1];
                $write (" %s %s", format_result ( res_expected ), `PB(err_expected));
            end

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
