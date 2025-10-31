`include "util.svh"

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

    localparam width     = 8;

    localparam n_inputs  = 100;
    localparam n_outputs = n_inputs * width;

    // Minimum to count at least 1000 valid inputs
    localparam in_cnt_w  = $clog2(n_inputs + 1);
    // 8 times smaller than input
    localparam out_cnt_w = $clog2(n_outputs + 1);

    logic                   parallel_valid;
    logic [    width - 1:0] parallel_data;

    wire                    busy;
    wire                    serial_valid;
    wire                    serial_data;

    logic [ in_cnt_w - 1:0] in_vld_cnt;
    logic [out_cnt_w - 1:0] out_vld_cnt;

    parallel_to_serial  # (.width (width)) dut (.*);

    //------------------------------------------------------------------------

    // Monitor

    bit was_reset = 1'b0;

    logic queue [$];
    logic serial_data_expected;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            was_reset   <= 1'b1;
            in_vld_cnt  <= '0;
            out_vld_cnt <= '0;
            queue        = {};
        end
        else if (was_reset)
        begin
            if (parallel_valid) begin
                in_vld_cnt <= in_vld_cnt + 1'b1;

                for (int i = 0; i < width; i ++)
                begin
                    queue.push_back (parallel_data[i]);
                end
            end

            if (serial_valid)
            begin
                out_vld_cnt <= out_vld_cnt + 1'b1;

                serial_data_expected = queue.pop_front ();

                if (serial_data !== serial_data_expected)
                begin
                    $display ("FAIL %s", `__FILE__);

                    $display ("++ TEST     => {%s, %s}",
                        `PB (serial_data), `PB (serial_data_expected));

                    $finish (1);
                end
            end
        end
    end

    //------------------------------------------------------------------------

    // Stimulus generation

    int current_inputs;
    logic               d_parallel_valid;
    logic [width - 1:0] d_parallel_data;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif

        parallel_valid <= 1'b0;
        parallel_data  <= 'x;

        d_parallel_data = '0;

        @ (negedge rst);

        while (current_inputs != n_inputs)
        begin
            if (current_inputs <= 10)
            begin
                d_parallel_valid = 1'b1;
                d_parallel_data  = { width { 1'b1 } } - d_parallel_data;
            end
            else
            begin
                d_parallel_valid = 1' ($urandom ());
                d_parallel_data  = width' ($urandom ());
            end

            current_inputs += 32' (d_parallel_valid);

            parallel_valid <= d_parallel_valid;
            parallel_data  <= d_parallel_valid ? d_parallel_data : 'x;

            @ (posedge clk);

            parallel_valid <= 1'b0;

            // repeat (width-1) @ (posedge clk);

            # 10

            while (busy === 1'b1)
            begin
                @ (posedge clk);
                # 10 ;
            end
        end

        // Stop driving and wait for output
        // We have to wait 2 cycles here: one to get an output from the module
        // and another one to wait for non-blocking assignment to out_vld_cnt
        parallel_valid <= '0;
        @(posedge clk);
        @(posedge clk);

        if (out_cnt_w' ( in_vld_cnt * width) !== out_vld_cnt) begin
            $display ("FAIL %s", `__FILE__);

            $display("++ TEST     => {%s != %s}", `PD(in_vld_cnt * width), `PD(out_vld_cnt));
            $display("++ EXPECTED => out_vld_cnt * width == in_vld_cnt");

            $finish (1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    //----------------------------------------------------------------------
    // Setting timeout against hangs

    initial
    begin
        repeat (100000) @ (posedge clk);
        $display ("FAIL %s: timeout reached!", `__FILE__);
        $finish;
    end

endmodule
