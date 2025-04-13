//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens
(
    input  clk,
    input  rst,
    input  a,
    output logic b
);
    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 110_011_101_000_1111
    // b -> 010_001_001_000_0101
    logic ignore_1;

    always_ff @ (posedge clk)
        begin
        if (rst)
            ignore_1 = '0;

        if (a)
            begin
            b        = ~ignore_1;
            ignore_1 = ~ignore_1;
            end
        else
            b = '0;
        end
endmodule
