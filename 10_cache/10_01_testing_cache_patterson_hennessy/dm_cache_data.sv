// Code from David A. Patterson and John L. Hennessy.
// Computer Organization and Design: The Hardware/Software Interface, 5th Edition
// Section 5.12. Advanced Material: Implementing Cache Controllers
// https://booksite.elsevier.com/9780124077263/downloads/advance_contents_and_appendices/section_5.12.pdf

// cache: data memory, single port, 1024 blocks

module dm_cache_data
import cache_def::*;
(
    input  bit             clk,
    input  cache_req_type  data_req,    // data request/command, e.g. RW, valid
    input  cache_data_type data_write,  // write port (128-bit line)
    output cache_data_type data_read    // read port
);

    timeunit      1ns;
    timeprecision 1ps;

    cache_data_type [0:1023] data_mem;

    initial begin
        for (int i = 0; i < 1024; i ++)
            data_mem [i] = '0;
    end

    assign data_read = data_mem [data_req.index];

    always_ff @ (posedge clk) begin
        if (data_req.we)
            data_mem [data_req.index] <= data_write;
    end

endmodule
