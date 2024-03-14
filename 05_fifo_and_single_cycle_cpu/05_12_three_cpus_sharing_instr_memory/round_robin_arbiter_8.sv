// A modification of an arbiter from
// Matt Weber. Arbiters: Design Ideas and Coding Styles. SNUG Boston 2001.

module round_robin_arbiter_8
(
    input              clk,
    input              rst,
    input        [7:0] req,
    output logic [7:0] gnt
);

    logic [2:0] ptr;

    logic [7:0] shift_req;
    logic [7:0] shift_gnt;

    always_comb
        case (ptr)
        3'd0: shift_req =              req [7:0]  ;
        3'd1: shift_req = { req [0:0], req [7:1] };
        3'd2: shift_req = { req [1:0], req [7:2] };
        3'd3: shift_req = { req [2:0], req [7:3] };
        3'd4: shift_req = { req [3:0], req [7:4] };
        3'd5: shift_req = { req [4:0], req [7:5] };
        3'd6: shift_req = { req [5:0], req [7:6] };
        3'd7: shift_req = { req [6:0], req [7:7] };
        endcase

    // Priority arbiter using case

    always_comb
    begin
        casez (shift_req)
        8'b????_???1: shift_gnt = 8'b0000_0001;
        8'b????_??10: shift_gnt = 8'b0000_0010;
        8'b????_?100: shift_gnt = 8'b0000_0100;
        8'b????_1000: shift_gnt = 8'b0000_1000;
        8'b???1_0000: shift_gnt = 8'b0001_0000;
        8'b??10_0000: shift_gnt = 8'b0010_0000;
        8'b?100_0000: shift_gnt = 8'b0100_0000;
        8'b1000_0000: shift_gnt = 8'b1000_0000;
        8'b0000_0000: shift_gnt = 8'b0000_0000;
        endcase
    end

    always_comb
        case (ptr)
        3'd0: gnt =   shift_gnt [7:0]                   ;
        3'd1: gnt = { shift_gnt [6:0], shift_gnt [7:7] };
        3'd2: gnt = { shift_gnt [5:0], shift_gnt [7:6] };
        3'd3: gnt = { shift_gnt [4:0], shift_gnt [7:5] };
        3'd4: gnt = { shift_gnt [3:0], shift_gnt [7:4] };
        3'd5: gnt = { shift_gnt [2:0], shift_gnt [7:3] };
        3'd6: gnt = { shift_gnt [1:0], shift_gnt [7:2] };
        3'd7: gnt = { shift_gnt [0:0], shift_gnt [7:1] };
        endcase

    always_ff @ (posedge clk)
        if (rst)
            ptr <= 3'b0;
        else
            case (1'b1)  // synopsys parallel_case
            gnt [0]: ptr <= 3'd1;
            gnt [1]: ptr <= 3'd2;
            gnt [2]: ptr <= 3'd3;
            gnt [3]: ptr <= 3'd4;
            gnt [4]: ptr <= 3'd5;
            gnt [5]: ptr <= 3'd6;
            gnt [6]: ptr <= 3'd7;
            gnt [7]: ptr <= 3'd0;
            endcase

endmodule
