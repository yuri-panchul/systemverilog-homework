//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts serial data to the parallel multibit value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits, the module should assert the parallel_valid
    // output and set the data.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    logic [3:0] n_bits;
    logic [width - 1:0] register;

    always_ff @(posedge clk or posedge rst) 
        begin
        if (rst) 
            begin
            register       <= 0;
            n_bits         <= 0;
            parallel_valid <= 0;
            end 
        else 
            begin
            parallel_valid <= 0; 

            if (serial_valid) 
                begin
                register = {serial_data, register[width-1:1]}; // = - to use it in following if
                n_bits   <= n_bits + 1;

                if (n_bits == width - 1) 
                    begin
                    parallel_data  <= register;
                    parallel_valid <= 1;
                    n_bits         <= 0;
                    end
                end
            end
        end

endmodule
