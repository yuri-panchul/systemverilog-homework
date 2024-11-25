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

    localparam n_outputs = 100;
    localparam n_inputs  = n_outputs * width;

    // Minimum to count at least 1000 valid inputs
    localparam in_cnt_w  = $clog2(n_inputs + 1);
    // 8 times smaller than input
    localparam out_cnt_w = $clog2(n_outputs + 1);

    logic                   serial_valid;
    logic                   serial_data;

    wire                    parallel_valid;
    wire  [    width - 1:0] parallel_data;

    logic [ in_cnt_w - 1:0] in_vld_cnt;
    logic [out_cnt_w - 1:0] out_vld_cnt;

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
            was_reset   <= 1'b1;
            out_vld_cnt <= '0;
            in_vld_cnt  <= '0;
            queue        = {};
        end
        else if (was_reset)
        begin
            if (serial_valid) begin
                in_vld_cnt <= in_vld_cnt + 1'b1;

                queue.push_back (serial_data);
            end

            if (parallel_valid)
            begin
                out_vld_cnt <= out_vld_cnt + 1'b1;

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
                        // verilator lint_off BLKSEQ
                        parallel_data_expected [i] = queue.pop_front ();
                        // verilator lint_on BLKSEQ

                    if (parallel_data !== parallel_data_expected)
                    begin
                        $display ("FAIL %s", `__FILE__);

                        $display ("++ TEST     => {%s, %s}",
                            `PH (parallel_data), `PH (parallel_data_expected));

                        $finish (1);
                    end
                end
            end
        end
    end

    //------------------------------------------------------------------------

    // Stimulus generation

    int current_inputs;
    logic d_serial_valid, d_serial_data;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            // $dumpvars;
        `endif

        { serial_valid, serial_data } <= '0;

        @ (negedge rst);

        while (current_inputs != n_inputs)
        begin
            if (current_inputs <= 20)
            begin
                d_serial_valid = 1'b1;
                d_serial_data  = ~ serial_data;
            end
            else
            begin
                d_serial_valid = 1' ($urandom());
                d_serial_data  = 1' ($urandom());
            end

            current_inputs += 32' (d_serial_valid);

            { serial_valid, serial_data } <= { d_serial_valid, d_serial_data };

            @ (posedge clk);
        end

        // Stop driving and wait for output
        // We have to wait 2 cycles here: one to get an output from the module
        // and another one to wait for non-blocking assignment to out_vld_cnt
        serial_valid <= '0;
        @(posedge clk);
        @(posedge clk);

        if (in_cnt_w' (out_vld_cnt * width) !== in_vld_cnt) begin
            $display ("FAIL %s", `__FILE__);

            $display("++ TEST     => {%s != %s}", `PD(out_vld_cnt*width), `PD(in_vld_cnt));
            $display("++ EXPECTED => out_vld_cnt * width == in_vld_cnt");

            $finish (1);
        end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
