localparam   LATENCY = 10 ;     // block latency

// A module that implements latency hiding by instantiating multiple FSMs
// and distributing the requests among them. In this way a user of the module
// can issue a new request every clock cycle and get a result every clock cycle,
// similar to using a pipelined module.


module discriminant_using_distributor
                  (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);


    // Task:
    // Implement a module that uses several bloks "float_discriminant" for calculate discriminant
    // similarly, the pipeline, that is, accepts data every clock cycle and returns the result
    // after several clock cycles.
    //
    // Note:
    // the "float_discriminant" module is located in the "float_discriminant.sv" file. Do not modify
    // it, use it "as is".
    //
    //
    //

    localparam  W_N_OUT = $clog2(LATENCY-1);                                   // the width of the control bus for the multiplexer
                                                                               // of results
    logic [LATENCY-1:0]             onehot_in;                                 // one-hot registre for select block
    logic [W_N_OUT-1:0]             n_out;                                     // result selection register
    logic [LATENCY-1:0]             res_vld_o, res_negative_o, err_o, busy_o;  // vectors for connecting  signals of bloks
    logic [LATENCY-1:0][FLEN - 1:0] res_o;                                     // an array for selecting results

    always_ff @ (posedge clk) begin
      if (rst) begin
        onehot_in    <= LATENCY'(1);                                           // load "0..01" to one-hot selector
        n_out        <='0;                                                     // "0" set the number of the first block with the result
      end
      else begin                                                               // witching the inputs and outputs of the blocks depending
        if (arg_vld)                                                           // on the arg_vlc and res_vld signals
          onehot_in  <= {onehot_in[LATENCY-2:0],onehot_in[LATENCY-1]};
        if (|res_vld_o) begin
          if (n_out == (LATENCY-1 )) n_out <= '0;
          else                       n_out <= n_out + 1'b1 ;
        end
      end
    end

// ----------- generating blocks ----------------------------------------------
  genvar i;
  generate
    for(i = 0; i < LATENCY; i = i + 1) begin:block

     float_discriminant  inst (
                               .clk(clk),
                               .rst(rst),
                               .arg_vld(arg_vld & onehot_in[i]),
                               .a(a),
                               .b(b),
                               .c(c),

                               .res_vld(res_vld_o[i]),
                               .res(res_o[i]),
                               .res_negative(res_negative_o[i]),
                               .err(err_o[i]),
                               .busy(busy_o[i])
                              );

    end
  endgenerate

 //----------- output multiplexer ---------------------------------------------
  always_comb begin
    res          = res_o[n_out]  ;
    res_negative = res_negative_o[n_out];
    err          = err_o[n_out];
    res_vld      = res_vld_o[n_out];
  end

endmodule