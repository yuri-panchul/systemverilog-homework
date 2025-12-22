/*
Задача - реализовать модуль принимающий на вход целое число N_tokens и генерирующий N_tokens импульсов.
Модуль должен использовать сигналы valid-ready при передаче данных.
*/

/*
  Task:
  Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
  transfer tokens.
*/


module  generate_tokens_fc(
                         input                   clk,
                         input                   rst,
                         input                   up_valid,
                         output                  up_ready,
                         input    [WIDTH-1 : 0]  n_tokens,
                         output                  down_valid,
                         output                  down_token,
                         input                   down_ready
    );
    localparam WIDTH = 4;

    /* START SOLUTION */

    logic [WIDTH-1:0] tokens_count;


    wire up_handshake   = up_ready & up_valid;
    wire down_handshake = down_ready & down_valid;

    always_ff @(posedge clk)
      if (rst ) begin
        tokens_count <= '0;
      end

      else begin

        if (up_handshake)   tokens_count <= n_tokens;
        if ((down_handshake) & (tokens_count > 0)) tokens_count <= tokens_count - 1;

      end

      assign down_token  = (|tokens_count);
      assign down_valid = 1'b1;
      assign up_ready   = (tokens_count == 0);


   /* END SOLUTION */
endmodule