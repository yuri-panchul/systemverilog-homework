// A simple memory responder
// to accomodate the cache example from

// David A. Patterson and John L. Hennessy.
// Computer Organization and Design: The Hardware/Software Interface, 5th Edition
// Section 5.12. Advanced Material: Implementing Cache Controllers
// https://booksite.elsevier.com/9780124077263/downloads/advance_contents_and_appendices/section_5.12.pdf

module main_memory_model
import cache_def::*;
(
    input  bit           clk,
    input  mem_req_type  mem_req,  // memory request (cache->memory)
    output mem_data_type mem_data  // memory response (memory->cache)
);

    timeunit      1ns;
    timeprecision 1ps;

    mem_req_type pend_mem_req;
    cache_data_type ['h1000 - 1:0] mem;

    bit [3:0] latency_counter;

    always_ff @ (posedge clk)
    begin
        if (latency_counter > 0)
        begin
            latency_counter <= latency_counter - 1;
        end
        else if (pend_mem_req.valid)
        begin
            pend_mem_req.valid <= 1'b0;

            if (pend_mem_req.rw)
                mem [pend_mem_req.addr >> 4] <= pend_mem_req.data;
            else
                mem_data.data <= mem [pend_mem_req.addr >> 4];

            mem_data.ready <= 1'b1;
        end
        else if (mem_req.valid)
        begin
            pend_mem_req    <= mem_req;
            latency_counter <= '1;
            mem_data.ready  <= 1'b0;
        end
        else
        begin
            mem_data.ready  <= 1'b0;
        end
    end

endmodule
