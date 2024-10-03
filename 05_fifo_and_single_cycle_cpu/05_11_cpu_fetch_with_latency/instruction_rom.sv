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

module instruction_rom
#(
    parameter SIZE   = 64,
    parameter ADDR_W = $clog2(SIZE)
)
(
    input                       clk,
    input        [ADDR_W - 1:0] a,
    output logic [        31:0] rd,
    output logic                rd_vld
);
    reg [31:0] rom [0:SIZE - 1];

    // We intentionally introduce latency here

    always_ff @ (posedge clk)
    begin
        rd  <= rom [a];
    end

    // Task: Add definition for a rd_vld signal
    // assign rd_vld = ...
    initial $readmemh ("program.hex", rom);

endmodule
