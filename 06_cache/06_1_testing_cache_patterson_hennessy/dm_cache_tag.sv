// Code from Patterson & Hennessy (?) Edition
// Section 5.12. Advanced Material: Implementing Cache Controllers

// cache: tag memory, single port, 1024 blocks

module dm_cache_tag
import cache_def::*;
(
    input  bit            clk,        // write clock
    input  cache_req_type tag_req,    // tag request/command, e.g. RW, valid
    input  cache_tag_type tag_write,  // write port
    output cache_tag_type tag_read    // read port
);

    timeunit      1ns;
    timeprecision 1ps;

    cache_tag_type [0:1023] tag_mem;

    initial begin
        for (int i = 0; i < 1024; i ++)
            tag_mem [i] = '0;
    end

    assign tag_read = tag_mem [tag_req.index];

    always_ff @ (posedge clk) begin
        if (tag_req.we)
            tag_mem [tag_req.index] <= tag_write;
    end

endmodule
