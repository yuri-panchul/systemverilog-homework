`include "../include/util.svh"

module testbench;

    // Clock and reset

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

    // Instantiation

    localparam width = 8;

    logic               serial_valid;
    logic               serial_data;

    wire                parallel_valid;
    wire  [width - 1:0] parallel_data;

    serial_to_parallel  # (.width (width)) dut (.*);

    //------------------------------------------------------------------------

    // Monitor

    bit was_reset = 1'b0;

    logic queue [$];
    logic [width - 1:0] parallel_data_expected;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            was_reset <= 1'b1;
            queue = {};
        end
        else if (was_reset)
        begin
            if (parallel_valid)
            begin
                if (queue.size () < width)
                begin
                    $display ("FAIL %s", `__FILE__);

                    $display ("++ TEST     => {%s, %s}",
                        `PD (queue.size ()), `PD (width));

                    $finish (1);
                end
                else
                begin
                    for (int i = 0; i < width; i ++)
                        parallel_data_expected [i] = queue.pop_front ();

                    if (parallel_data !== parallel_data_expected)
                    begin
                        $display ("FAIL %s", `__FILE__);

                        $display ("++ TEST     => {%s, %s}",
                            `PH (parallel_data), `PH (parallel_data_expected));

                        $finish (1);
                    end
                end
            end

            if (serial_valid)
                queue.push_back (serial_data);
        end
    end

    //------------------------------------------------------------------------

    // Stimulus generation

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif

        { serial_valid, serial_data } <= '0;

        @ (negedge rst);

        repeat (1000)
        begin
            { serial_valid, serial_data } <= 2' ($urandom ());
            @ (posedge clk);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
