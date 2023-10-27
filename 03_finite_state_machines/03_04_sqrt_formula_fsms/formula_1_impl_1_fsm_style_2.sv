//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module formula_1_impl_1_fsm_style_2
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // FSM

    enum logic [2:0]
    {
        st_idle       = 3'd0,
        st_wait_a_res = 3'd1,
        st_wait_b_res = 3'd2,
        st_wait_c_res = 3'd3
    }
    state, next_state;

    always_comb
    begin
        next_state = state;

        case (state)
        st_idle       : if ( arg_vld     ) next_state = st_wait_a_res ;
        st_wait_a_res : if ( isqrt_y_vld ) next_state = st_wait_b_res ;
        st_wait_b_res : if ( isqrt_y_vld ) next_state = st_wait_c_res ;
        st_wait_c_res : if ( isqrt_y_vld ) next_state = st_idle       ;
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;

    // Datapath

    always_comb
    begin
        isqrt_x_vld = '0;

        case (state)
        st_idle       : isqrt_x_vld = arg_vld;

        st_wait_a_res ,
        st_wait_b_res : isqrt_x_vld = isqrt_y_vld;
        endcase
    end

    always_comb
    begin
        isqrt_x = 'x;  // Don't care

        case (state)
        st_idle       : isqrt_x = a;
        st_wait_a_res : isqrt_x = b;
        st_wait_b_res : isqrt_x = c;
        endcase
    end

    // The result

    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            res_vld <= (state == st_wait_c_res & isqrt_y_vld);

    always_ff @ (posedge clk)
        if (state == st_idle)
            res <= '0;
        else if (isqrt_y_vld)
            res <= res + isqrt_y;

endmodule
