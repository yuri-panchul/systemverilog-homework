//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    enum logic [2:0] {
        IDLE, 
        LOAD, 
        COMP1, 
        COMP2, 
        COMP3, 
        DONE
    } state, next_state;

    always_ff @(posedge clk) 
    begin
        if (rst) begin
            state     <= IDLE;
            valid_out <= 0;
        end
        else
            state <= next_state;
    end

    logic err1, err2, err3;
    assign busy = (state != IDLE) & (state != DONE);

    always_comb begin
            case (state)
                IDLE:
                if (valid_in) 
                    next_state = LOAD;

                LOAD: begin
                    sorted     = unsorted;
                    next_state = COMP1;
                end

                COMP1: begin
                    f_le_a = sorted[0];
                    f_le_b = sorted[1];

                    if (!f_le_res) begin
                        sorted[0] = sorted[1];
                        sorted[1] = sorted[0];
                    end

                    err1       = f_le_err;
                    next_state = COMP2;
                end

                COMP2: begin
                    f_le_a = sorted[1];
                    f_le_b = sorted[2];

                    if (!f_le_res) begin
                        sorted[1] = sorted[2];
                        sorted[2] = sorted[1];
                    end

                    err2       = f_le_err;
                    next_state = COMP3;
                end

                COMP3: begin
                    f_le_a = sorted[0];
                    f_le_b = sorted[1];

                    if (!f_le_res) begin
                        sorted[0] = sorted[1];
                        sorted[1] = sorted[0];
                    end

                    err3       = f_le_err;
                    next_state = DONE;
                end

                DONE: begin
                    err        = err1 | err2 | err3;                    
                    valid_out  = 1;
                    next_state = IDLE;
                end
            endcase
    end
endmodule
