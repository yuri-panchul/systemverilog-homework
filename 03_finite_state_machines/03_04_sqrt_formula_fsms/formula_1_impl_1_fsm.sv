//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module formula_1_impl_1_fsm
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

    //------------------------------------------------------------------------
    // States

    enum logic [2:0]
    {
        st_idle       = 3'd0,
        st_wait_a_res = 3'd1,
        st_wait_b_res = 3'd2,
        st_wait_c_res = 3'd3
    }
    state, next_state;

    //------------------------------------------------------------------------
    // Next state and isqrt interface

    always_comb
    begin
        next_state  = state;

        isqrt_x_vld = '0;
        isqrt_x     = 'x;  // Don't care

        case (state)
        st_idle:
        begin
            isqrt_x = a;

            if (arg_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_a_res;
            end
        end

        st_wait_a_res:
        begin
            isqrt_x = b;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_b_res;
            end
        end

        st_wait_b_res:
        begin
            isqrt_x = c;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_c_res;
            end
        end

        st_wait_c_res:
        begin
            if (isqrt_y_vld)
            begin
                next_state = st_idle;
            end
        end
        endcase
    end

    //------------------------------------------------------------------------
    // Assigning next state

    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;

    //------------------------------------------------------------------------
    // Accumulating the result

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
