module tb;

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
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    logic a, double_b;

    double_tokens i_double_tokens
    (
        .clk ( clk      ),
        .rst ( rst      ),
        .a   ( a        ),
        .b   ( double_b )
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
            n_orig_tokens   <= n_orig_tokens   + 32' (a);
            n_double_tokens <= n_double_tokens + 32' (double_b);
        end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            $dumpvars;
        `endif

        @ (negedge rst);

        repeat (200)
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
           $display ("\nERROR: number of tokens do not match: actual: %0d expected: %0d",
               n_double_tokens, n_orig_tokens * 2);

           $display ("%s FAIL", `__FILE__);
           $finish (1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
