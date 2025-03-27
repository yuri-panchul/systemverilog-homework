// A simple memory responder written by Yuri Panchul
// to accomodate the cache example from Patterson & Hennessy (?) Edition
// Section 5.12. Advanced Material: Implementing Cache Controllers

module main_memory_model
import cache_def::*;
(
    input  bit           clk,
    input  mem_req_type  mem_req,  // memory request (cache->memory)
    output mem_data_type mem_data  // memory response (memory->cache)
);

    timeunit      1ns;
    timeprecision 1ps;

    cache_data_type ['h1000 - 1:0] mem;

    // Probability of ready is 20%

    always_ff @ (posedge clk)
        mem_data.ready <= ($urandom_range (0, 99) < 1);

    always_ff @ (posedge clk)
        if (mem_req.valid & mem_req.rw)
            mem [mem_req.addr >> 4] <= mem_req.data;

    always_comb
        mem_data.data = mem [mem_req.addr >> 4];

endmodule
