//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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
    // Task:
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm
	
	
	
    //------------------------------------------------------------------------
    // States

    enum logic [2:0]
    {
        st_idle         = 3'd0,
        st_wait_c_res   = 3'd1,
        st_wait_bc_res  = 3'd2,
        st_wait_abc_res = 3'd3
    }
    state, next_state;

    //------------------------------------------------------------------------
    // Next state and isqrt interface

    always_comb
    begin
        next_state  = state;

        isqrt_x_vld = '0;
        isqrt_x     = 'x;  // Don't care

        // This lint warning is bogus because we assign the default value above
        // verilator lint_off CASEINCOMPLETE

        case (state)
        st_idle:
        begin
            isqrt_x = c;
            if (arg_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_c_res;
            end
        end

        st_wait_c_res:
        begin
            if (isqrt_y_vld)
            begin
			    isqrt_x = b + 32' (isqrt_y);
                isqrt_x_vld = '1;
                next_state  = st_wait_bc_res;
            end
        end

        st_wait_bc_res:
        begin
            if (isqrt_y_vld)
            begin
			    isqrt_x = a + 32' (isqrt_y);
                isqrt_x_vld = '1;
                next_state  = st_wait_abc_res;
            end
        end

        st_wait_abc_res:
        begin
            if (isqrt_y_vld)
            begin
                next_state = st_idle;
            end
        end
        endcase

        // verilator lint_on  CASEINCOMPLETE

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
            res_vld <= (state == st_wait_abc_res & isqrt_y_vld);

    always_ff @ (posedge clk)
        if (state == st_idle)
            res <= '0;
        else if (st_wait_abc_res & isqrt_y_vld)
            res <= 32' (isqrt_y);

endmodule
