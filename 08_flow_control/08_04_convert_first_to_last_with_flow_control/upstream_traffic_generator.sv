module upstream_traffic_generator
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_enable,

    output               up_valid,
    input                up_ready,
    output               up_first,
    output               up_last,
    output [width - 1:0] up_data
);

    logic               valid;
    logic               first;
    logic               last;
    logic [width - 1:0] data;

    assign up_valid = valid;
    wire   ready    = up_ready;
    assign up_first = valid ? first : 'x;
    assign up_last  = valid ? last  : 'x;
    assign up_data  = valid ? data  : 'x;

    always @ (posedge clock)
    begin
        if (reset)
        begin
            valid   <= 1'b0;
            first   <= 1'b1;
            last    <= $urandom_range (0, 99) < 10;
            data    <= "A";
        end
        else
        begin
            if (~ (valid & ~ ready))
                valid <= up_enable & $urandom_range (0, 99) < 60;

            if (valid & ready)
            begin
                first <= last;
                last  <= $urandom_range (0, 99) < 30;
                data  <= $urandom_range ("A", "Z");
            end
        end
    end

endmodule
