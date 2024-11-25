module f_div (
    input               clk,
    input               rst,
    input  [FLEN - 1:0] a, b,
    input               up_valid,
    output [FLEN - 1:0] res,
    output              down_valid,
    output              busy,
    output              error
);

    logic [          4:0] operation;
    logic [FMTBITS - 1:0] format;
    logic [          4:0] flags;
    logic [          6:0] opcode;

    // Don't account inexact results as errors (0.1 + 0.2 = 0.30000000000000004)
    assign error = | flags[4:1];

    // Floating point opcode, for more info see The RISC-V Instruction Set Manual Volume I
    // Chapter 34. RV32/64G Instruction Set Listings | page 560
    assign opcode = 7'b1010011;

    // Arithmetic operation
    // 5'b00000 - add
    // 5'b00001 - sub
    // 5'b00010 - mult
    // 5'b00011 - div
    // 5'b01011 - sqrt

    // When no valid input, send ADD to not cause stall (similar to NOP)
    assign operation = up_valid ? 5'b00011 : 5'b00000;
    assign format    = FMTBITS' (1);

    // verilator lint_off PINMISSING
    wally_fpu i_fpu (
        .clk        ( clk        ),
        .reset      ( rst        ),
        .Operation  ( operation  ),
        .Format     ( format     ),
        .Opcode     ( opcode     ),
        .A          ( a          ),
        .B          ( b          ),
        .UpValid    ( up_valid   ),
        .Res        ( res        ),
        .DownValid  ( down_valid ),
        .FDivBusyE  ( busy       ),
        .SetFflagsM ( flags      )
    );
    // verilator lint_on PINMISSING

endmodule
