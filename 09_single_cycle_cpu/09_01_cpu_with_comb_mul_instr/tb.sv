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

    logic        clk;
    logic        rst;

    wire  [31:0] imAddr;   // instruction memory address
    wire  [31:0] imData;   // instruction memory data

    logic [ 4:0] regAddr;  // debug access reg address
    wire  [31:0] regData;  // debug access reg data

    localparam ROM_SIZE = 1024;
    localparam ADDR_W   = $clog2(ROM_SIZE);

    sr_cpu cpu
    (
        .clk     ( clk     ),
        .rst     ( rst     ),

        .imAddr  ( imAddr  ),
        .imData  ( imData  ),

        .regAddr ( regAddr ),
        .regData ( regData )
    );

    instruction_rom # (.SIZE (ROM_SIZE)) i_rom
    (
        .a       ( ADDR_W' (imAddr) ),
        .rd      ( imData           )
    );

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

        regAddr <= 5'd10;  // a0 register used for I/O

        @ (negedge rst);

        repeat (1000)
        begin
            @ (posedge clk);

            if (  regData == 32'h00213d05    // Fibonacci
                | regData == 32'h1c8cfc00 )  // Factorial
            begin
                $display ("%s PASS", `__FILE__);
                $finish;
            end
        end

        $display ("%s FAIL: none of expected register values occured",
            `__FILE__);

        $finish;
    end

    //------------------------------------------------------------------------

    int unsigned cycle = 0;
    bit wasRst = 1'b0;

    logic [31:0] prevImAddr;
    logic [31:0] prevRegData;

    always @ (posedge clk)
    begin
        $write ("cycle %5d", cycle);
        cycle <= cycle + 1'b1;

        if (rst)
        begin
            $write (" rst");
            wasRst <= 1'b1;
        end
        else
        begin
            $write ("    ");
        end

        if (imAddr !== prevImAddr)
            $write (" %h", imAddr);
        else
            $write ("         ");

        if (wasRst & ~ rst & $isunknown (imData))
        begin
            $display ("%s FAIL: fetched instruction at address %x contains Xs: %x",
                `__FILE__, imAddr, imData);

            $finish;
        end

        if (regData !== prevRegData)
            $write (" %h", regData);
        else
            $write ("         ");

        prevImAddr  <= imAddr;
        prevRegData <= regData;

        $display;
    end

endmodule
