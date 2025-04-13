//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  logic [1:0] requests,
    output logic [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01
    logic [1:0] prev_gran;

    assign grants = (requests == 2'b00) ? 2'b00      : 
                    (requests == 2'b11) ? ~prev_gran : requests;

    always_ff @ (posedge clk)
    begin
        if (rst)
            prev_gran <= 2'b01; // Initialize to favor first requester
        else
        begin
            if (requests == 2'b11)
                prev_gran <= ~prev_gran;
            else
                if (requests != 2'b00)
                    prev_gran <= requests;
        end
    end

endmodule