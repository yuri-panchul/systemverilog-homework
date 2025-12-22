The set for the Mock Verilog Interview at Cal Poly San Luis Obispo

© Yuri Panchul, Verilog Meetup
[https://verilog-meetup.com](https://verilog-meetup.com/) and the
participants to
[systemverilog-homework](https://github.com/verilog-meetup/systemverilog-homework)
open-source project.

To make the mock interview realistic, you cannot use any form of AI, Google
anything or even access the Internet when answering this question. A
candidate usually answers this question on a dry-erase board with no access
to anything electronic.

### Question 31. Modify the following shift register design to reduce dynamic power

```v
module shift_register
# (
    parameter width = 256, depth = 10
)
(
    input                clk,
    input                rst,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);

    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule
```
