module tb;

    localparam fifo_width = 8,
               fifo_depth = 5,
               allow_push_when_full_with_pop = 1;

    //------------------------------------------------------------------------

    logic                    clk;
    logic                    rst;
    logic                    push;
    logic                    pop;
    logic [fifo_width - 1:0] write_data;
    wire  [fifo_width - 1:0] read_data;
    wire                     empty;
    wire                     full;

    //------------------------------------------------------------------------

    ff_fifo_with_reg_empty_full
    # (
        .width (fifo_width),
        .depth (fifo_depth)
    )
    rtl (.*);

    fifo_monitor
    # (
        .width (fifo_width),
        .depth (fifo_depth),
        .allow_push_when_full_with_pop (allow_push_when_full_with_pop)
    )
    monitor (.*);

    //------------------------------------------------------------------------

    initial
    begin
        clk = '0;
        forever #5 clk = ~ clk;
    end

    initial
    begin
        repeat (10000) @ (posedge clk);
        $display ("Timeout!");
        $finish;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following `define
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        //--------------------------------------------------------------------
        // Initialization

        push <= '0;
        pop  <= '0;

        //--------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //--------------------------------------------------------------------

        $display ("*** Fill and empty");

        push <= '1;

        for (int i = 0; i < fifo_depth; i ++)
        begin
            write_data <= i * 16 + i;
            @ (posedge clk);
        end

        push <= '0;
        pop  <= '1;

        repeat (fifo_depth)
            @ (posedge clk);

        pop  <= '0;
        repeat (2) @ (posedge clk);

        //--------------------------------------------------------------------

        $display ("*** Fill half and run back-to-back, then empty");

        push <= '1;

        for (int i = 0; i < fifo_depth / 2; i ++)
        begin
            write_data <= i * 16 + i;
            @ (posedge clk);
        end

        pop <= '1;

        repeat (5)
            for (int i = 0; i < fifo_depth; i ++)
            begin
                write_data <= i * 16 + i;
                @ (posedge clk);
            end

        push <= '0;

        do
        begin
            @ (posedge clk);
            # 1;  // This delay is necessary because of combinational logic after ff
        end
        while (~ empty);

        pop <= '0;
        repeat (2) @ (posedge clk);

        //--------------------------------------------------------------------

        $display ("*** Randomized test");

        repeat (5) @ (posedge clk);

        repeat (100)
        begin
            @ (posedge clk);
            # 1  // This delay is necessary because of combinational logic after ff

            pop  <= '0;
            push <= '0;

            if (  allow_push_when_full_with_pop
                    & full
                    & $urandom_range (1, 100) <= 40 )
            begin
                pop  <= '1;
                push <= '1;

                write_data <= $urandom;
            end

            if (~ empty & $urandom_range (1, 100) <= 50)
                pop <= '1;

            if (~ full & $urandom_range (1, 100) <= 60)
            begin
                push <= '1;
                write_data <= $urandom;
            end
        end

        //--------------------------------------------------------------------

        $display ("%s PASS", `__FILE__);
        $finish;
    end

endmodule
