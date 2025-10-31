`include "util.svh"

module testbench_2;

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

    bit was_reset = 1'b0;

    always @ (posedge clk)
        if (rst)
            was_reset <= 1'b1;

    //------------------------------------------------------------------------

    // Instantiation

    localparam width = 8, n_inputs = 10;

    logic [n_inputs - 1:0] up_vlds;

    logic [n_inputs - 1:0]
          [width    - 1:0] up_data;

    wire                   down_vld;
    wire  [width    - 1:0] down_data;

    put_in_order
    # (
        .width    ( width    ),
        .n_inputs ( n_inputs )
    )
    i_put_in_order (.*);

    //------------------------------------------------------------------------

    logic [width - 1:0] queue [$];
    logic [width - 1:0] down_data_expected;

    task receive ();

        forever
        begin
            @ (posedge clk);

            if (down_vld)
            begin
                if (queue.size () == 0)
                begin
                    $display ("FAIL %s", `__FILE__);

                    $display ("++ TEST     => {%s}",
                        `PD (queue.size ()));

                    $finish (1);
                end
                else
                begin
                    down_data_expected = queue.pop_front ();

                    if (down_data !== down_data_expected)
                    begin
                        $display ("FAIL %s", `__FILE__);

                        $display ("++ TEST     => {%s, %s}",
                            `PH (down_data), `PH (down_data_expected));

                        $finish (1);
                    end
                end
            end
        end

    endtask

    //------------------------------------------------------------------------

    int unsigned counter = 0;

    localparam ptr_width = $clog2 (n_inputs);
    localparam [ptr_width - 1:0] max_ptr = n_inputs - 1;

    localparam latency_width = $clog2 (n_inputs + 1);         // TODO: think
    localparam [latency_width - 1:0] max_latency = n_inputs;  // TODO: think

    logic [ptr_width - 1:0] ptr;

    logic [n_inputs - 1:0]                      pending;
    logic [n_inputs - 1:0][width         - 1:0] pending_data;
    logic [n_inputs - 1:0][latency_width - 1:0] pending_latency;

    logic [n_inputs - 1:0]                      pending_for_log;
    logic [n_inputs - 1:0][width         - 1:0] pending_data_for_log;

    task send (int n_reps);

        ptr     = '0;
        pending = '0;

        for (int rep = 0; rep < n_reps || pending != '0; rep ++)
        begin
            for (int i = 0; i < n_inputs; i ++)
                if (pending_latency [i] > 0)
                    pending_latency [i] --;

            //----------------------------------------------------------------

            if ($urandom_range (0, 100) < 80)
            begin
                assert (~ pending [ptr]);

                pending [ptr] = 1'b1;

                if (counter < n_inputs * 3)
                    pending_data [ptr] = counter ++;
                else
                    pending_data [ptr] = $urandom ();

                pending_latency [ptr] = $urandom_range (0, max_latency - 1);

                queue.push_back (pending_data [ptr]);

                if (ptr == max_ptr) ptr = '0; else ptr ++;
            end

            //----------------------------------------------------------------

            up_vlds <= '0;
            up_data <= 'x;

            for (int i = 0; i < n_inputs; i ++)
            begin
                if (pending [i] && pending_latency [i] == 0)
                begin
                    pending [i] = 1'b0;

                    up_vlds [i] <= 1'b1;
                    up_data [i] <= pending_data [i];
                end
            end

            // Pending for log is needed to avoid race condition.
            // Race condition may happen because of blocking assignments

            pending_for_log      <= pending;
            pending_data_for_log <= pending_data;

            @ (posedge clk);
        end

        up_vlds <= '0;
        up_data <= 'x;

        repeat (n_inputs) @ (posedge clk);

    endtask

    //------------------------------------------------------------------------

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        if (was_reset)
        begin
            $write ("%3d  pending  ", cycle);

            for (int i = 0; i < n_inputs; i ++)
                if (pending_for_log [i])
                    $write (" %h", pending_data_for_log [i]);
                else
                    $write ("   ");

            $display;

            $write ("%3d  up       ", cycle);

            for (int i = 0; i < n_inputs; i ++)
                if (up_vlds [i])
                    $write (" %h", up_data [i]);
                else
                    $write ("   ");

            $display;

            $write ("%3d  down     ", cycle);

            if (down_vld)
                $write (" %h", down_data);

            $display ("\n");
        end

        cycle ++;
    end

    //------------------------------------------------------------------------

    localparam TIMEOUT = 10000;

    task run ();

        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave or Surfer

            //$dumpvars;
        `endif

        @ (negedge rst);

        fork
            send (1000);
            receive ();

            begin
                repeat (TIMEOUT) @ (posedge clk);
                $display ("FAIL: timeout!");
                $finish (1);
            end
        join_any

        $display ("\nPASS %s", `__FILE__);

    endtask

endmodule
