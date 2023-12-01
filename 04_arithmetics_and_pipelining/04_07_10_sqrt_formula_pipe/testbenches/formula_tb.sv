//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module formula_tb
# (
    parameter formula = 1,
              pipe    = 1
);

    `include "formula_1_fn.svh"
    `include "formula_2_fn.svh"

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    localparam arg_width = 32, res_width = 32;

    logic                    clk_enable;
    logic                    clk;
    logic                    rst;

    logic                    arg_vld;
    logic  [arg_width - 1:0] a;
    logic  [arg_width - 1:0] b;
    logic  [arg_width - 1:0] c;

    wire                     res_vld;
    wire   [res_width - 1:0] res;

    //--------------------------------------------------------------------------
    // Instantiating DUT

    generate

        if (formula == 1 && pipe)
        begin : if_formula_1_pipe
                   formula_1_pipe               i_formula_1_pipe               (.*);
        end
        else if (formula == 1 && ! pipe)
        begin : if_formula_1_pipe_aware_fsm
                   formula_1_pipe_aware_fsm_top i_formula_1_pipe_aware_fsm_top (.*);
        end
        else
        begin : if_formula_2_pipe
                   formula_2_pipe               i_formula_2_pipe               (.*);
        end

    endgenerate

    //--------------------------------------------------------------------------
    // Driving clk

    initial
    begin
        clk = '1;

        forever
        begin
            # 5

            if (clk_enable)
                clk = ~ clk;
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

    initial $sformat (test_id, "%s formula %0d pipe %0d:",
        `__FILE__, formula, pipe);

    //--------------------------------------------------------------------------
    // Driving stimulus

    localparam max_latency       = 16,
               gap_between_tests = 100;

    bit run_completed = '0;

    task run ();

        run_completed = '0;

        // Enabling the testbench
        clk_enable = '1; # 1

        `ifdef USE_FORK_JOIN_NONE

        // Setting timeout against hangs

        fork
        begin
            repeat (1000) @ (posedge clk);
            $display ("%s FAIL: timeout!", test_id);
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

        a       <= 1;
        b       <= 4;
        c       <= 9;
        arg_vld <= '1;

        @ (posedge clk);
        arg_vld <= '0;

        while (~ res_vld)
             @ (posedge clk);

        // Direct testing
        // A group of tests back-to-back

        for (int i = 0; i < 100; i = i * 3 + 1)
        begin
            a       <= i;
            b       <= i;
            c       <= i;
            arg_vld <= '1;

            @ (posedge clk);
            arg_vld <= '0;

            // Wait for non-pipelined module

            while (! pipe & ~ res_vld)
                @ (posedge clk);
        end

        repeat (max_latency + gap_between_tests)
            @ (posedge clk);

        // A group of tests with delays

        for (int i = 0; i < 1000; i = i * 3 + 1)
        begin
            a       <= i;
            b       <= i + 1;
            c       <= i * 2;
            arg_vld <= '1;

            @ (posedge clk);
            arg_vld <= '0;

            // Wait for non-pipelined module

            while (! pipe & ~ res_vld)
                @ (posedge clk);

            // Variable gap in the input data

            repeat (i / 10)
            @ (posedge clk);
        end

        repeat (max_latency + gap_between_tests)
            @ (posedge clk);

        // Random testing

        repeat (10)
        begin
            a       <= $urandom ();
            b       <= $urandom ();
            c       <= $urandom ();
            arg_vld <= '1;

            @ (posedge clk);
            arg_vld <= '0;

            // Wait for non-pipelined module

            while (! pipe & ~ res_vld)
                @ (posedge clk);

            // Variable gap in the input data

            repeat ($urandom_range (0, max_latency))
            @ (posedge clk);
        end

        repeat (max_latency + gap_between_tests)
            @ (posedge clk);

        // Disabling the testbench
        clk_enable = '0;

        `ifdef USE_FORK_JOIN_NONE

            // Disabling timeout check
            disable fork;

        `endif

        run_completed = '1;

    endtask

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("%s time %7d cycle %5d", test_id, $time, cycle ++);

        if (rst)
            $write (" rst");
        else
            $write ("    ");

        if (arg_vld)
            $write (" arg %d %d %d", a, b, c);
        else
            $write ("                                     ");

        if (res_vld)
            $write (" res %d", res);

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    logic [res_width - 1:0] queue [$];
    logic [res_width - 1:0] res_expected;

    logic was_reset = 0;

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
                case (formula)
                1: res_expected = formula_1_fn (a, b, c);
                2: res_expected = formula_2_fn (a, b, c);
                default: assert (0);
                endcase

                queue.push_back (res_expected);
            end

            if (res_vld)
            begin
                if (queue.size () == 0)
                begin
                    $display ("%s FAIL: unexpected result %0d",
                        test_id, res);

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

                    if (res !== res_expected)
                    begin
                        $display ("%s FAIL: res mismatch. Expected %0d, actual %0d",
                            test_id, res_expected, res);

                        $finish;
                    end
                end
            end
        end
    end

    //----------------------------------------------------------------------

    final
    begin
        if (queue.size () == 0)
        begin
            if (run_completed)
                $display ("%s PASS", test_id);
            else
                $display ("%s FAIL: did not run or run was not completed",
                    test_id);
        end
        else
        begin
            $write ("%s FAIL: data is left sitting in the model queue (%d left):",
                test_id, queue.size());

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
        repeat (1000) @ (posedge clk);
        $display ("%s FAIL: timeout!", test_id);
        $finish;
    end

endmodule

