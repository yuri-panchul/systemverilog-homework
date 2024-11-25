`ifdef LOCAL_TB

module fpu_tb;

    logic              clk;
    logic              rst;

    real               a;
    real               b;
    logic [FLEN - 1:0] res;

    logic              error;
    logic              up_valid;
    logic              down_valid;
    logic              busy;

    real gen_a;
    real gen_b;

    real a_q [$];
    real b_q [$];

    real out_a;
    real out_b;

    enum logic [2:0] {
        ADD,
        SUB,
        MULT,
        DIV,
        SQRT
    } operation = SQRT;
/*
    initial operation = SQRT;
*/
    localparam ITERATIONS = 100;

    // f_add DUT (
    //     .clk        ( clk             ),
    //     .rst        ( rst             ),
    //     .a          ( $realtobits (a) ),
    //     .b          ( $realtobits (b) ),
    //     .up_valid   ( up_valid        ),
    //     .res        ( res             ),
    //     .down_valid ( down_valid      ),
    //     .busy       ( busy            ),
    //     .error      ( error           )
    // );

    // f_sub DUT (
    //     .clk        ( clk             ),
    //     .rst        ( rst             ),
    //     .a          ( $realtobits (a) ),
    //     .b          ( $realtobits (b) ),
    //     .up_valid   ( up_valid        ),
    //     .res        ( res             ),
    //     .down_valid ( down_valid      ),
    //     .busy       ( busy            ),
    //     .error      ( error           )
    // );

    // f_mult DUT (
    //     .clk        ( clk             ),
    //     .rst        ( rst             ),
    //     .a          ( $realtobits (a) ),
    //     .b          ( $realtobits (b) ),
    //     .up_valid   ( up_valid        ),
    //     .res        ( res             ),
    //     .down_valid ( down_valid      ),
    //     .busy       ( busy            ),
    //     .error      ( error           )
    // );

    // f_div DUT (
    //     .clk        ( clk             ),
    //     .rst        ( rst             ),
    //     .a          ( $realtobits (a) ),
    //     .b          ( $realtobits (b) ),
    //     .up_valid   ( up_valid        ),
    //     .res        ( res             ),
    //     .down_valid ( down_valid      ),
    //     .busy       ( busy            ),
    //     .error      ( error           )
    // );

    f_sqrt DUT (
        .clk        ( clk             ),
        .rst        ( rst             ),
        .a          ( $realtobits (a) ),
        .b          ( $realtobits (b) ),
        .up_valid   ( up_valid        ),
        .res        ( res             ),
        .down_valid ( down_valid      ),
        .busy       ( busy            ),
        .error      ( error           )
    );

    initial begin
        clk = '0;

        forever
            # 500 clk = ~ clk;
    end

    task reset();
        rst <= '1;
        repeat (2) @ (posedge clk);
        rst <= '0;
    endtask

    initial begin
        reset();

        forever begin
            fork
                gen_and_drive();
                scoreboard();
            join
        end
    end

    task check (input real a, input real b, input real res);
        real expected;

        case(operation)
            ADD:  expected = a + b;
            SUB:  expected = a - b;
            MULT: expected = a * b;
            DIV:  expected = a / b;
            SQRT: expected = $sqrt(a);
            default: $error("Invalid operation");
        endcase

        // Don't stop simulation after mismatch
        if (res != expected) begin
            $display("ERROR: expected: %.20f", expected);
            $display("Got: %.20f\n", res);
        end else begin
            $display("MATCH: expected: %.20f", expected);
            $display("Got: %.20f\n", res);
        end
    endtask

    task scoreboard();
        forever begin
            @(posedge clk);
            if (down_valid) begin
                if (a_q.size() == 0 || b_q.size == 0) begin
                    $error("Input queue empty");
                    $finish(1);
                end

                out_a = a_q.pop_front();
                out_b = b_q.pop_front();

                check(out_a, out_b, $bitstoreal(res));
            end
        end
    endtask

    task gen_and_drive();

        up_valid <= '0;
        a        <= '0;
        b        <= '0;

        @(posedge clk);

        for (int i = 0; i < ITERATIONS; i++) begin
            // Can't generate random real numbers in Verilog
            gen_a = real' ({$urandom, $urandom}) / $urandom;
            gen_b = real' ({$urandom, $urandom}) / $urandom;

            a <= gen_a;
            b <= gen_b;

            a_q.push_back(gen_a);
            b_q.push_back(gen_b);

            up_valid <= '1;
            @(posedge clk);

            // TODO: randomize up_valid for all operations

            // Drop valid and wait for busy for operations that take time
            if (operation == DIV || operation == SQRT) begin
                up_valid <= '0;
                @(posedge clk);

                while (busy) begin
                    @(posedge clk);
                end
            end
        end

        up_valid <= '0;

        // Wait for all results from pipeline
        repeat(100) @(posedge clk);
        $finish;
    endtask

    initial begin
        $dumpvars;
    end

endmodule

`endif
