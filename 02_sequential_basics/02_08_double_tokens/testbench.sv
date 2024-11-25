`include "util.svh"

module testbench;

    logic clk;

    initial
    begin
        clk = '0;

        forever
            # 500 clk = ~ clk;
    end

    logic rst;

    initial
    begin
        rst <= 'x;
        repeat (2) @ (posedge clk);
        rst <= '1;
        repeat (2) @ (posedge clk);
        rst <= '0;
    end

    //------------------------------------------------------------------------

    logic a, double_b, double_overflow;

    double_tokens i_double_tokens
    (
        .clk      ( clk             ),
        .rst      ( rst             ),
        .a        ( a               ),
        .b        ( double_b        ),
        .overflow ( double_overflow )
    );

    //------------------------------------------------------------------------

    // Monitor

    bit was_reset = 1'b0;
    always @ (posedge clk) if (rst) was_reset <= 1'b1;

    int n_orig_tokens   = 0,
        n_double_tokens = 0;

    always @ (posedge clk)
        if (~ rst & was_reset)
        begin
            n_orig_tokens   <= n_orig_tokens + 32' (a);
            n_double_tokens <= n_double_tokens + 32' (double_b);
        end

    //------------------------------------------------------------------------

    logic expected_overflow = 1'b1;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif

        @ (negedge rst);

        repeat (100)
        begin
            // If probability is 50%, then b is always 1
            a <= $urandom_range (0, 100) < 30;
            @ (posedge clk);
        end

        a <= 1'b0;

        repeat (200)
            @ (posedge clk);

        //--------------------------------------------------------------------

        if (n_double_tokens !== n_orig_tokens * 2)
        begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s}",
                             `PD(n_orig_tokens));

            $display("++ TEST     => {%s}",
                             `PD(n_double_tokens));
            $finish(1);
        end

        // We assume that the internal counter width is not big enough

        repeat (1000)
        begin
            a <= 1'b1;
            @ (posedge clk);
        end

        if (double_overflow !== 1'b1)
        begin
            $display("FAIL %s", `__FILE__);
            $display("++ INPUT    => {%s} for 1000 cycles",`PD(a));
            $display("++ EXPECTED => {%s}", `PD(expected_overflow));
            $display("++ ACTUAL   => {%s}", `PD(double_overflow));
            $finish(1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
