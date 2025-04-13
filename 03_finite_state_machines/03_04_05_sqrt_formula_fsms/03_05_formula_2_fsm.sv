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

    enum logic [2:0] {
        IDLE,

        SEND_C,
        WAIT_C,

        SEND_B,
        WAIT_B,

        SEND_A,
        WAIT_A,

        DONE
    }
    state, next;

    logic [31:0] a_reg, b_reg, c_reg;
    logic [31:0] bc_sum;
    logic [31:0] abc_sum;

    always_comb 
    begin
        next = state;

        res_vld     = 0;
        isqrt_x_vld = 0;

        case (state)
            IDLE: 
                if (arg_vld) 
                    next = SEND_C;

            SEND_C: 
                begin
                isqrt_x_vld = 1;
                isqrt_x = c_reg;
                next = WAIT_C;
                end

            WAIT_C: 
                if (isqrt_y_vld)
                    begin
                    bc_sum = b_reg + isqrt_y;
                    next   = SEND_B;
                    end

            SEND_B: 
                begin
                isqrt_x_vld = 1;
                isqrt_x     = bc_sum;
                next        = WAIT_B;
                end

            WAIT_B: 
                if (isqrt_y_vld) 
                    begin
                    abc_sum = a_reg + isqrt_y;
                    next    = SEND_A;
                    end

            SEND_A: 
                begin
                isqrt_x_vld = 1;
                isqrt_x     = abc_sum;
                next        = WAIT_A;
                end

            WAIT_A: 
                if (isqrt_y_vld) 
                    next = DONE;

            DONE: 
                begin
                res_vld = 1;
                res     = isqrt_y;
                next    = IDLE;
                end
        endcase
    end

    always_ff @(posedge clk) 
    begin
        if (rst)
            state <= IDLE;
        else
            state <= next;
    end

    always_ff @(posedge clk) 
    begin
        if (state == IDLE && arg_vld) 
            begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            end
    end


endmodule