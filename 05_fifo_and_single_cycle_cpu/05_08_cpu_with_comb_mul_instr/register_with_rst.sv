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

module register_with_rst
(
    input               clk,
    input               rst,
    input        [31:0] d,
    output logic [31:0] q
);

    always_ff @ (posedge clk)
        if (rst)
            q <= '0;
        else
            q <= d;

endmodule
