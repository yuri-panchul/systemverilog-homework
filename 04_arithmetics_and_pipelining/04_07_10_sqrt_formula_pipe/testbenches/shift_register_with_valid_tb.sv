//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module shift_register_with_valid_tb
# (
    parameter width = 8, depth = 8
);

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic               clk_enable;
    logic               clk;
    logic               rst;

    logic               in_vld;
    logic [width - 1:0] in_data;

    wire                out_vld;
    wire  [width - 1:0] out_data;

    wire                expected_out_vld;
    wire  [width - 1:0] expected_out_data;

    //--------------------------------------------------------------------------
    // Instantiating reference model

    one_bit_wide_shift_register_with_reset
    # ( .depth (depth) )
    i_shift_reg_expected_vld
    (
        .clk      ( clk               ),
        .rst      ( rst               ),
        .in_data  ( in_vld            ),
        .out_data ( expected_out_vld  )
    );

    shift_register
    # ( .width (width), .depth (depth) )
    i_shift_reg_expected_data
    (
        .clk      ( clk                ),
        .in_data  ( in_data            ),
        .out_data ( expected_out_data  )
    );

    //--------------------------------------------------------------------------
    // Instantiating DUT - Design under Test

    shift_register_with_valid
    # ( .width (width), .depth (depth) )
    i_shift_register_with_valid
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .in_vld   ( in_vld   ),
        .in_data  ( in_data  ),
        .out_vld  ( out_vld  ),
        .out_data ( out_data )
    );

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

    task reset;

        rst <= 'x;
        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

    endtask

    //--------------------------------------------------------------------------
    // Test ID for error messages

    string test_id;

    initial $sformat (test_id, "%s width %0d depth %0d:",
        `__FILE__, width, depth);

    //--------------------------------------------------------------------------
    // Driving stimulus

    localparam max_latency       = depth,
               gap_between_tests = 100;

    bit run_completed = '0;

    task run;

        run_completed = '0;

        // Enabling the testbench
        clk_enable = '1; # 1

        $display ("--------------------------------------------------");
        $display ("Running %m");

        // We don't need direct tests here,
        // everything should be covered by randomization.
        //
        // However we do need to have multiple tests of the design behaviour
        // immediately after the reset
        // to make sure there are Xs on valid coming.

        repeat (3 * depth)
        begin
            in_vld <= '0;
            reset ();

            repeat (3 * depth)
            begin
                in_data <= $urandom ();
                in_vld  <= $urandom ();

                @ (posedge clk);
            end
        end

        // Disabling the testbench
        clk_enable = '0;

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

        if (in_vld)
            $write (" in_data %8h", in_data);
        else
            $write ("                 ");

        if (out_vld)
            $write (" out_data %8h", out_data);

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    always @ (posedge clk)
    begin
        if (expected_out_vld !== 'x & out_vld !== expected_out_vld)
        begin
            $display ("%s FAIL: expected out_vld mismatch. Expected %b, actual %b",
                test_id, expected_out_vld, out_vld);

            $finish;
        end

        if (expected_out_vld & (out_data !== expected_out_data))
        begin
            $display ("%s FAIL: out_data mismatch. Expected %h, actual %h",
                test_id, expected_out_data, out_data);

            $finish;
        end
    end

    //----------------------------------------------------------------------
    // Verdict

    final
    begin
        if (run_completed)
            $display ("%s PASS", test_id);
        else
            $display ("%s FAIL: did not run or run was not completed",
                test_id);
    end

    //----------------------------------------------------------------------
    // Setting timeout against hangs

    // Not needed here because we don't wait for anything
    // in stimulus generation

endmodule
