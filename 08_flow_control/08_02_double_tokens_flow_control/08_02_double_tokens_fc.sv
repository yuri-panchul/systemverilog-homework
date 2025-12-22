/*
Задача - реализовать модуль удваивающий поступающие сигналы (токены). Модуль должен использовать сигналы
valid-ready при передаче данных. Если модуль получит 100 токенов подряд, то сигнал up_ready должен быть
установлен в "0"ю
*/

/*
  Task:
  Implement module dobuble input signals (tokens). The module must use signals valid-ready for
  transfer tokens. If the module resived more 100 tokens sequentially then must set up_ready = 0;
*/


module  double_tokens_fc(
                         input    clk,
                         input    rst,
                         input    up_valid,
                         output   up_ready,
                         input    up_token,
                         output   down_valid,
                         output   down_data,
                         input    down_ready
    );

    /* START SOLUTION */

    logic [7:0] tokens_count;
    logic       error;

    wire up_handshake   = up_ready & up_valid;
    wire down_handshake = down_ready & down_valid;

    always_ff @(posedge clk)
      if (rst ) begin
        tokens_count <= '0;
        error        <= '0;
      end
      else begin
        if (up_handshake  &  down_handshake & up_token )  tokens_count <= tokens_count + 1;
        if (up_handshake  & ~down_handshake & up_token)   tokens_count <= tokens_count + 2;
        if (
           ((tokens_count  > '0) & down_handshake) &
           (~up_handshake |  ~up_token ))                 tokens_count <= tokens_count - 1;

      end

      assign down_data  = (up_token & up_valid) | (|tokens_count);
      assign down_valid = ~error;
      assign up_ready   = (tokens_count < 200);


   /* END SOLUTION */
endmodule