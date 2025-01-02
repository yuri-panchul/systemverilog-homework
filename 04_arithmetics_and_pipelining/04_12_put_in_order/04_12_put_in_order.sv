`timescale 1ns/1ps

module put_in_order
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

localparam ptr_width = $clog2(n_inputs);

logic [n_inputs - 1:0][width - 1:0] data_d;
logic [n_inputs - 1:0][width - 1:0] data_q;
logic [n_inputs - 1:0]              data_vld_d;
logic [n_inputs - 1:0]              data_vld_q;

always_comb begin

    data_vld_d = data_vld_q;

    for ( int i = 0; i < n_inputs; i++ ) begin
        if ( up_vlds[i] ) begin
            data_vld_d[i] = 1'b1;
        end
    end

    if (data_vld_q[out_ptr])
        data_vld_d[out_ptr] = 1'b0;

    if (up_vlds[out_ptr])
        data_vld_d[out_ptr] = 1'b1;

end

always_comb begin
    data_d = data_q;
    
    for ( int i = 0; i < n_inputs; i++ ) begin
        data_d[i] = up_data[i];
    end
end

always_ff @(posedge clk) begin
    data_q <= data_d;
end

always_ff @(posedge clk) begin
    if (rst) begin
        data_vld_q <= '0;
    end else begin
        data_vld_q <= data_vld_d;
    end
end

//Next data ptr counter
logic [ptr_width-1:0] out_ptr_d;
logic [ptr_width-1:0] out_ptr;

always_comb begin
    
    out_ptr_d = out_ptr;

    if ( data_vld_q[out_ptr] ) begin
        if ( out_ptr_d >= (n_inputs-1) ) begin
            out_ptr_d = '0;
        end else begin
            out_ptr_d = out_ptr + 1'b1;
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        out_ptr <= '0;
    end else begin
        out_ptr <= out_ptr_d;
    end
end

assign down_vld  = data_vld_q[out_ptr];
assign down_data = data_q[out_ptr];

endmodule
