//----------------------------------------------------------------------------
// Top file wiring everything together. DO NOT MODIFY
//----------------------------------------------------------------------------

module formula_2_top
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    wire        isqrt_x_vld;
    wire [31:0] isqrt_x;

    wire        isqrt_y_vld;
    wire [15:0] isqrt_y;
	
/*
    formula_2_fsm i_formula_2_fsm (.*);
	
    isqrt i_isqrt
    (
        .clk   ( clk         ),
        .rst   ( rst         ),
        .x_vld ( isqrt_x_vld ),
        .x     ( isqrt_x     ),
        .y_vld ( isqrt_y_vld ),
        .y     ( isqrt_y     )
    );
	
*/
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
     localparam  N = 49;  // Latency of a non-pipelined module formula_2_fsm -> (3*16+1)
  
     logic [N-1:0]       res_vlds;
     logic [N-1:0][31:0] ress ; 
     logic [N-1:0][31:0] c_reg; 
     logic [N-1:0][31:0] b_reg;
     logic [N-1:0][31:0] a_reg;
     logic [N-1:0]       in_vld;
     logic [  5:0]       index;
     logic [ 31:0]       res_comb;	


   // Instantiation of the required number of modules depending on the latency of each instantiated module
     generate
	   genvar i;
		  
         for( i = 0; i < N; i++)
	     begin
	   
	   wire        isqrt_x_vld_local;
           wire [31:0] isqrt_x_local; 
           wire        isqrt_y_vld_local;
           wire [15:0] isqrt_y_local; 
	 	   
           formula_2_fsm i_formula_2_fsm
	  (
	      .clk        (      clk        ),
              .rst        (      rst        ),
              .arg_vld    (   in_vld[i]     ),
              .a          (    a_reg[i]     ),
              .b          (    b_reg[i]     ),
              .c          (    c_reg[i]     ),
              .res_vld    (   res_vlds[i]   ),
              .res        (    ress[i]      ),
              .isqrt_x_vld(isqrt_x_vld_local),
              .isqrt_x    (  isqrt_x_local  ),
              .isqrt_y_vld(isqrt_y_vld_local),
              .isqrt_y    (  isqrt_y_local  )
	   );
 
           isqrt i_isqrt
           (
             .clk   (       clk         ),
             .rst   (       rst         ),
             .x_vld ( isqrt_x_vld_local ),
             .x     (   isqrt_x_local   ),
             .y_vld ( isqrt_y_vld_local ),
             .y     (   isqrt_y_local   )
           );
	
	end
     endgenerate
  
   // Register the input data and the valid signal, storing them in a vector under the current module's index
     always_ff @(posedge clk)
       begin
         if (rst)
	     index <= '0; 
	 else
           begin
             a_reg[index]  <= a;
             b_reg[index]  <= b;
             c_reg[index]  <= c;
	     in_vld[index] <= arg_vld;
             index <= (index == N-1) ? '0 : index + 1; 
	   end
       end
	 
   // Generating output signals
     always_comb
       begin
         res_comb = '0; 
         for (int i = 0; i < N; i++)
            if (res_vlds[i])
                res_comb = ress[i];
       end
	 
    assign res = res_comb; 
    assign res_vld = |res_vlds; 

endmodule
