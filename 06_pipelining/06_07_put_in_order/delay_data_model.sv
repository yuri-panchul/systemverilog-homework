//This block emulate non-constant processing delay
//Delay variable from 1 to n_input clock cycles

// *****************************************************************************
// FOR SIMULATION PURPOSES ONLY!
//
// NOT SUITABLE FOR SYNTHESIS!
// *****************************************************************************

module delay_data_model
#(
    parameter width    = 16,
                n_inputs = 5
)
(
    input                         clk,
    input                         rst,

    input                         vld_in,
    input [ delay_width - 1 : 0 ] out_delay,
    input [ width-1 : 0 ]         data_in,

    output logic                  vld_out,
    output logic [ width-1 : 0 ]  data_out
);

    localparam delay_width = $clog2( n_inputs );

    logic [ delay_width - 1 : 0 ] delay;
    logic [ width - 1 : 0 ]       data_lock;
    logic                         ready;
    event                         delay_done;

    //Input
    initial begin
        data_lock  <= '0;
        delay      <= '0;
        ready      <= '1;
        @(!rst);

        forever begin

            while( ~vld_in ) @( posedge clk );
            ready     <= '0;
            data_lock <= data_in;
            delay     <= out_delay;

            repeat ( 32' ( delay ) ) @( posedge clk );

            ready <= 1'b1;

            @( posedge clk );
            -> delay_done;
        end
    end

    //output
    initial begin
        vld_out   <= '0;
        data_out  <= '0;
        @( !rst )

        forever begin
            //Output locked data when finished wait
            @( delay_done );
            vld_out  <= 1'b1;
            data_out <= data_lock;
            //Hold vld_out for one clk
            @( posedge clk );
            vld_out  <= 1'b0;
        end
    end

    //Self check - repeated vld_in when module in process delay forbidden
    initial begin
        forever begin
            @( posedge clk );
            if ( vld_in && !ready ) begin
            $warning("Repeated vld_in when block in process. Current vld_in will be ignored. Time: ", $realtime);
            end
        end
    end

endmodule
