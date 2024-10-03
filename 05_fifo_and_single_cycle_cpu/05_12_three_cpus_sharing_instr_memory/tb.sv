//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

module tb;

    localparam nCPUs = 3;

    localparam [31:0] PC_Fibonacci = 32'h0,
                      PC_Factorial = 32'h30;

    localparam [ 4:0] checkReg = 10;  // a0 register

    localparam [31:0] passRegData_Fibonacci = 32'h00213d05,
                      passRegData_Factorial = 32'h1c8cfc00;

    //------------------------------------------------------------------------

    logic clk;
    logic rst;

    wire [nCPUs - 1:0][31:0] regData;

    cpu_cluster
    # (.nCPUs (nCPUs))
    cluster
    (
        .clk     ( clk ),
        .rst     ( rst ),

    //  .rstPC   ( { nCPUs { PC_Fibonacci } } ),

        .rstPC   ( {
                       { nCPUs - 2 { PC_Factorial } },
                       {         2 { PC_Fibonacci } }
                 } ),

        .regAddr ( { nCPUs { checkReg } } ),
        .regData ( regData )
    );

    //------------------------------------------------------------------------

    bit [nCPUs - 1:0] testPass;

    always @ (posedge clk)
    begin
        for (int i = 0; i < nCPUs; i ++)
        begin
            // if (regData [i] == passRegData_Fibonacci)

            if (   i <= 1 && regData [i] == passRegData_Fibonacci
                || i >  1 && regData [i] == passRegData_Factorial )
            begin
                testPass [i] <= 1;
            end
        end
    end

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following `define
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars;
        `endif

        @ (negedge rst);

        repeat (1000)
        begin
            @ (posedge clk);

            if (& testPass)
            begin
                $display ("%s PASS", `__FILE__);
                $finish;
            end
        end

        $display ("%s FAIL: the expected register value did not occured with at least some CPUs",
            `__FILE__);

        $finish;
    end

    //------------------------------------------------------------------------

    int unsigned cycle = 0;

    logic [31:0] prevImAddr   [nCPUs];
    logic [31:0] prevRegData  [nCPUs];

    always @ (posedge clk)
    begin
        $write ("cycle %5d", cycle);
        cycle <= cycle + 1'b1;

        if (rst)
        begin
            $write (" rst");
        end
        else
        begin
            $write ("    ");
        end

        for (int i = 0; i < nCPUs; i ++)
        begin
            $write (" CPU %0d:", i);

            if (cluster.imAddr [i] !== prevImAddr [i])
                $write (" %h", cluster.imAddr [i]);
            else
                $write ("         ");

            if (regData [i] !== prevRegData [i])
                $write (" %h", regData [i]);
            else
                $write ("         ");

            prevImAddr  [i] <= cluster.imAddr [i];
            prevRegData [i] <= regData        [i];
        end

        $display;
    end

endmodule
