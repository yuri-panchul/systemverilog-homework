//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module formula_tb
# (
    parameter homework    = 0,
              formula     = 1,
              pipe        = 0,
              distributor = 0,
              impl        = 1
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

        if (homework == 3)
        begin : if_homework_3

            if (formula == 1 && impl == 1)
            begin : if_1_1
                formula_1_impl_1_top i_formula_1_impl_1_top (.*);
            end
            else if (formula == 1 && impl == 2)
            begin : if_1_2
                formula_1_impl_2_top i_formula_1_impl_2_top (.*);
            end
            else
            begin : if_else
                formula_2_top        i_formula_2_top        (.*);
            end
        end

        else if (homework == 4 && ! distributor)
        begin : if_homework_4_not_distributor

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
        end

        else if (homework == 4 && distributor)
        begin : if_homework_4_distributor

            sqrt_formula_distributor
            # (.formula (formula), .impl (impl))
            i_sqrt_formula_distributor (.*);
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

    initial $sformat (test_id, "%s homework %0d formula %0d pipe %0d distributor %0d impl %0d",
        `__FILE__,                 homework,    formula,    pipe,    distributor,    impl);

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

        if (! (pipe | distributor))
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

    bit run_completed = '0;

    task run ();

        run_completed = '0;

        // Enabling the testbench
        clk_enable = '1; # 1

        `ifdef USE_FORK_JOIN_NONE

        // Setting timeout against hangs

        fork
        begin
            repeat (100000) @ (posedge clk);
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

        a <= 1;
        b <= 4;
        c <= 9;

        drive_arg_vld_and_wait_res_vld_if_necessary ();
        make_gap_between_tests ();

        // Direct testing - a group of tests
        // A group of tests back-to-back

        for (int i = 0; i < 100; i = i * 3 + 1)
        begin
            a <= i;
            b <= i;
            c <= i;

            drive_arg_vld_and_wait_res_vld_if_necessary ();
        end

        make_gap_between_tests ();

        if (pipe | distributor)
        begin
            // A group of tests with delays

            for (int i = 0; i < 1000; i = i * 3 + 1)
            begin
                a       <= i;
                b       <= i + 1;
                c       <= i * 2;

                drive_arg_vld_and_wait_res_vld_if_necessary
                (
                    0,      // random_gap
                    i / 10  // gap
                );
            end

            make_gap_between_tests ();
        end

        // Random testing

        repeat (100)
        begin
            a <= $urandom ();
            b <= $urandom ();
            c <= $urandom ();

            drive_arg_vld_and_wait_res_vld_if_necessary (1); // random_gap
        end

        make_gap_between_tests ();

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
        $write ("%s time %7d cycle %5d", test_id, $time, cycle);
        cycle <= cycle + 1'b1;

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
                    $display ("FAIL %s: unexpected result %0d",
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
                        $display ("FAIL %s: res mismatch. Expected %0d, actual %0d",
                            test_id, res_expected, res);

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
            if (run_completed)
                $display ("PASS %s", test_id);
            else
                $display ("FAIL %s: did not run or run was not completed",
                    test_id);
        end
        else
        begin
            $write ("FAIL %s: data is left sitting in the model queue (%d left):",
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
        repeat (100000) @ (posedge clk);
        $display ("FAIL %s: timeout!", test_id);
        $finish;
    end

endmodule
