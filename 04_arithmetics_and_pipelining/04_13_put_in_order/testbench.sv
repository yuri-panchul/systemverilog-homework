module testbench;

    testbench_1 tb_1 ();
    testbench_2 tb_2 ();

    initial
    begin
        // First, prevent tb_1 from running by stalling its clock

        force tb_1.clk = '0;

        // Now run tb_2

        tb_2.run ();

        // Finally, let tb_1 to run

        release tb_1.clk;
    end

endmodule
