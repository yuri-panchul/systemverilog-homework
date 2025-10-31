//----------------------------------------------------------------------------
// Top testbench file.
// Runs all testbenches
//----------------------------------------------------------------------------

module tb;

    `ifdef RUN_ALL_TBS

    formula_tb # ( .formula (1), .pipe (1) ) i_formula_1_pipe_tb           ();
    formula_tb # ( .formula (1), .pipe (0) ) i_formula_1_pipe_aware_fsm_tb ();

    shift_register_with_valid_tb # ( .width (8), .depth (8) )
    i_shift_register_with_valid_tb1 ();

    shift_register_with_valid_tb # ( .width (17), .depth (13) )
    i_shift_register_with_valid_tb2 ();

    formula_tb # ( .formula (2), .pipe (1), .fifo (0) )
    i_formula_2_pipe_tb ();

    `endif

    formula_tb # ( .formula (2), .pipe (1), .fifo (1) )
    i_formula_2_pipe_using_fifos_tb ();

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        `ifdef RUN_ALL_TBS

        i_formula_1_pipe_tb             .run ();
        i_formula_1_pipe_aware_fsm_tb   .run ();
        i_shift_register_with_valid_tb1 .run ();
        i_shift_register_with_valid_tb2 .run ();
        i_formula_2_pipe_tb             .run ();

        `endif

        i_formula_2_pipe_using_fifos_tb .run ();

        $finish;
    end

endmodule
