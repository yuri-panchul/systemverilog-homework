module reorder
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                               clk,
    input                               rst,
    
    input [n_inputs - 1:0]              up_vlds,
    input [n_inputs - 1:0][width - 1:0] up_data,

    output                              down_vld,
    output                [width - 1:0] down_data
);

localparam dwdt = $clog2(n_inputs);

//latch input data
logic [n_inputs - 1:0][width - 1:0]     in_data_latch;
logic [n_inputs - 1:0]                  in_vld_latch;
always_ff @(posedge clk) begin
    if (rst) begin
        in_data_latch <= '0;
        in_vld_latch  <= '0;
    end else begin

        for ( int i = 0; i < n_inputs; i++ ) begin
            if ( up_vlds[i] == 1'b1 ) begin
                in_data_latch[i] <= up_data[i];
                in_vld_latch[i]  <= 1'b1;
            end  
        end
        //Не уверен, что так можно делать
        //Мы должны сбросить бит валидности после выставления данных, но есть моменты, когда 
        //буфер, который мы хотим сбросить уже снова должен содержать валидные данные
        if ( in_vld_latch[data_ptr] == 1'b1 &&
             up_vlds[data_ptr]      != 1'b1 ) begin
            in_vld_latch[data_ptr] <= 1'b0;
        end
    end
end

//Ring ones
logic[n_inputs-1:0] expected_vld;
always_ff @(posedge clk) begin
    if (rst) begin
        expected_vld <= 1'b1;
    end else begin

        if ( in_vld_latch[data_ptr] == 1'b1 ) begin

            for (int i = 0; i < n_inputs-1; i=i+1) begin
                expected_vld[i+1] <= expected_vld[i];
            end
            expected_vld[0] <= expected_vld[n_inputs-1];
        
        end
    end
end

//Encoder from expected_vld to counter
logic [dwdt:0] data_ptr;
always_comb begin : encoder
    for ( int i = 0; i < n_inputs; i++ ) begin
        if (expected_vld[i] == 1'b1 ) begin
            data_ptr <= i;
        end
    end
end

assign down_vld  = in_vld_latch[data_ptr];
assign down_data = in_data_latch[data_ptr];

endmodule
