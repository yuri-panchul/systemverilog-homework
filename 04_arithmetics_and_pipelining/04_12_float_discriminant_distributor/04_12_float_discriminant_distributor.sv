module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    // a module that simulates the operation of a pipeline by implementing several
    // Implement a module that uses several bloks "float_discriminant" for calculate discriminant
    // similarly, the pipeline, that is, accepts data every clock cycle and returns the result
    // after several clock cycles.
    //
    // Note:
    // the "float_discriminant" module is located in the "float_discriminant.sv" file. Do not modify
    // it, use it "as is".


endmodule
