//----------------------------------------------------------------------------
// Top testbench file.
// Runs all testbenches
//----------------------------------------------------------------------------

module tb;

    formula_tb # ( .homework (3), .formula (1), .impl (1) ) formula_1_impl_1_tb ();
    formula_tb # ( .homework (3), .formula (1), .impl (2) ) formula_1_impl_2_tb ();
    formula_tb # ( .homework (3), .formula (2)            ) formula_2_tb        ();

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        formula_1_impl_1_tb .run ();
        formula_1_impl_2_tb .run ();
        formula_2_tb        .run ();

        $finish;
    end

endmodule
