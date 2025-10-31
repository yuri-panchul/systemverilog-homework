// A testbench to accomodate the cache design from:
//
// David A. Patterson and John L. Hennessy.
// Computer Organization and Design: The Hardware/Software Interface, 5th Edition
// Section 5.12. Advanced Material: Implementing Cache Controllers
// https://booksite.elsevier.com/9780124077263/downloads/advance_contents_and_appendices/section_5.12.pdf

`include "util.svh"

module testbench;

    import cache_def::*;

    //------------------------------------------------------------------------
    // Signals to drive DUT

    bit              clk;
    bit              rst;
    cpu_req_type     cpu_req;   // CPU request input (CPU->cache)
    mem_data_type    mem_data;  // memory response (memory->cache)
    mem_req_type     mem_req;   // memory request (cache->memory)
    cpu_result_type  cpu_res;   // cache result (cache->CPU)

    //------------------------------------------------------------------------
    // Instantiating DUT and the main memory model

    dm_cache_fsm      cache       (.*);
    main_memory_model main_memory (.*);

    //------------------------------------------------------------------------
    // Driving clk

    initial
    begin
        clk = 1'b1;

        forever
        begin
            # 5 clk = ~ clk;
        end
    end

    //------------------------------------------------------------------------
    // Init

    task init_signals ();

        cpu_req <= '0;

    endtask

    //------------------------------------------------------------------------
    // Reset

    task drive_reset ();

        rst <= 1'b0;
        repeat (3) @ (posedge clk);
        rst <= 1'b1;
        repeat (3) @ (posedge clk);
        rst <= 1'b0;

    endtask

    //------------------------------------------------------------------------
    // Driving stimulus

    localparam TIMEOUT = 50000;

    //------------------------------------------------------------------------

    task make_gap_between_tests ();

        repeat (50) @ (posedge clk);
        init_signals ();
        repeat (50) @ (posedge clk);

    endtask

    //------------------------------------------------------------------------
    // Tasks to drive read and write

    task drive_read_or_write (input rw, input [31:0] addr, input [31:0] data);

        cpu_req.addr  <= addr;
        cpu_req.data  <= data;
        cpu_req.rw    <= rw;
        cpu_req.valid <= 1'b1;

        do
        begin
            @ (posedge clk);
        end
        while (~ cpu_res.ready);

        cpu_req.valid <= 1'b0;

    endtask

    //------------------------------------------------------------------------

    task drive_read (input [31:0] addr);
        drive_read_or_write (1'b0, addr, 32'hdeadbeef);
    endtask

    task drive_write (input [31:0] addr, input [31:0] data);
        drive_read_or_write (1'b1, addr, data);
    endtask

    //------------------------------------------------------------------------
    // Test sequences

    task test ();

        $display ("******************** Test ********************");

        init_signals ();
        drive_reset  ();

        $display ("Write within a cache line");

        drive_write (32'h0100, 32'h11111111);
        drive_write (32'h0104, 32'h22222222);
        drive_write (32'h0108, 32'h33333333);
        drive_write (32'h010c, 32'h44444444);

        $display ("Read from within a cache line");

        drive_read  (32'h0104);
        drive_read  (32'h0102);

        $display ("Write in different cache lines");

        drive_write (32'h0200, 32'h55555555);
        drive_write (32'h3104, 32'h66666666);
        drive_write (32'h8004, 32'h77777777);

        $display ("Read from different cache lines");

        drive_read  (32'h0501);
        drive_read  (32'h2000);
        drive_read  (32'hffff);

        $display ("We are supposed to see an eviction and writeback");

        // Try to do a transaction with the same index, but different tag
        //
        // +----------+-----------------------+
        // | 31 .. 14 | 13 .. 4 | 3  2 | 1  0 |
        // +----------+-----------------------+
        // | tag      | index   | word | byte |
        // +----------+-----------------------+
        //
        // You should be able to see
        // mem: write : addr 00000100 data 44444444333333332222222211111111

        // TODO

        $display ("We are supposed to see an eviction and fill");

        // You should be able to see
        // mem: read  : addr 00000108 data 44444444333333332222222211111111

        // TODO

        make_gap_between_tests ();

    endtask

    //------------------------------------------------------------------------
    // Running testbench

    bit log_tag_index_byte, log_state;

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            $dumpvars;
        `endif

        log_tag_index_byte = 1;
        log_state          = 0;

        test ();

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    //------------------------------------------------------------------------
    // Transaction log

    cpu_req_type prev_cpu_req;
    bit          prev_cpu_res_ready;

    always @ (posedge clk)
    begin
        prev_cpu_req       <= cpu_req;
        prev_cpu_res_ready <= cpu_res.ready;
    end

    wire cpu_req_stays_pending
        =   cpu_req == prev_cpu_req
          & ~ prev_cpu_res_ready & ~ cpu_res.ready;

    //------------------------------------------------------------------------

    bit last_mem_req_rw;

    always @ (posedge clk)
        if (mem_req.valid)
             last_mem_req_rw <= mem_req.rw;

    //------------------------------------------------------------------------

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        cycle ++;

        if (log_state & cache.vstate != cache.rstate)
            $display ("%d state %s -> %s: ", cycle,
                cache.rstate.name (), cache.vstate.name ());

        if (cpu_req.valid & ~ cpu_req_stays_pending)
        begin
            $write ("%d cpu: ", cycle);

            if (cpu_req.rw)
                $write ("write");
            else
                $write ("read ");

            if (cpu_res.ready)
                $write (" response");
            else
                $write (" request ");

            $write (" : addr %h", cpu_req.addr);

            if (log_tag_index_byte)
                $write (" tag  %h index %h word %h byte %h",
                    cpu_req.addr [TAGMSB:TAGLSB],
                    cpu_req.addr [TAGLSB - 1:4],
                    cpu_req.addr [3:2],
                    cpu_req.addr [1:0]);

            if (cpu_req.rw)
                $write (" data %h", cpu_req.data);
            else if (cpu_res.ready)
                $write (" data %h", cpu_res.data);

            $display ();
        end

        if (mem_data.ready)
        begin
            $write ("%d mem: ", cycle);

            if (last_mem_req_rw)
                $display ("write response");
            else
                $display ("read  response :               data %h", mem_data.data);
        end

        if (mem_req.valid)
        begin
            $write ("%d mem: ", cycle);

            if (mem_req.rw)
                $display ("write request  : addr %h data %h",
                    mem_req.addr, mem_req.data);
            else
                $display ("read  request  : addr %h",
                    mem_req.addr);
        end
    end

    //------------------------------------------------------------------------
    // Setting timeout against hangs

    initial
    begin
        repeat (TIMEOUT) @ (posedge clk);
        $display ("FAIL: timeout!");
        $finish;
    end

    //------------------------------------------------------------------------
    // Signals to see on GTKWave

    bit [ 31:0]     wv_cpu_req_addr;
    bit [ 31:0]     wv_cpu_req_data;
    bit             wv_cpu_req_rw;
    bit             wv_cpu_req_valid;

    bit [ 31:0]     wv_cpu_res_data;
    bit             wv_cpu_res_ready;

    bit [ 31:0]     wv_mem_req_addr;
    bit [127:0]     wv_mem_req_data;
    bit             wv_mem_req_rw;
    bit             wv_mem_req_valid;

    cache_data_type wv_mem_data_data;
    bit             wv_mem_data_ready;

    //------------------------------------------------------------------------

    assign wv_cpu_req_addr   = cpu_req.addr;
    assign wv_cpu_req_data   = cpu_req.data;
    assign wv_cpu_req_rw     = cpu_req.rw;
    assign wv_cpu_req_valid  = cpu_req.valid;

    assign wv_cpu_res_data   = cpu_res.data;
    assign wv_cpu_res_ready  = cpu_res.ready;

    assign wv_mem_req_addr   = mem_req.addr;
    assign wv_mem_req_data   = mem_req.data;
    assign wv_mem_req_rw     = mem_req.rw;
    assign wv_mem_req_valid  = mem_req.valid;

    assign wv_mem_data_data  = mem_data.data;
    assign wv_mem_data_ready = mem_data.ready;

endmodule
