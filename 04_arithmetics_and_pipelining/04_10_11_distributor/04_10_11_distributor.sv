localparam   LATENCY = 10 ;     // латентность конвейера  перенести в svh файл

// модуль имитируюший работу конвейера путем импементации нескольких N=LATENCY 
// вычислителей с латентностью = LATENCY

// вижу несколько вариантов оформления решения 
// первый выбор входов вычислителя идет через функцию "И" сигнала arg_vld и n-ного разряда one_hot
// регистра-селектора. При активном arg_vld, в каждом такте регистр-селектор сдвигается на 1 разряд 
// выходы вычислителей через мультиплексор подключены к выходу модуля. При наличии сигнала res_vld
// каждый такт инкрементирует регистр-селектор выходов n_out. Сигнал res_vld формируется из входного 
// сигнала arg_vld c задержкой в LATENCY тактов, в этом задержка реализуется на сдвиговом регистре 
// delay_vld. Модули вычислителей могут быть подключены прямым текстом (copy - paste LATENCY раз),
// а могут через generate. 

module distributor
                  (
    input                          clk,
    input                          rst,

    input                          arg_vld,
    input        [FLEN - 1:0]      a,
    input        [FLEN - 1:0]      b,
    input        [FLEN - 1:0]      c,

    output logic                   res_vld,
    output logic [FLEN - 1:0]      res,
    output logic                   res_negative,
    output logic                   err,

    output logic                   busy
);

    logic [LATENCY-1:0]            ptr_in;                                    // one-hot registre
    logic [$clog2(LATENCY-1):0]    n_out;                                     // регистр хранения номера вычислителя с валидным результатом  
    logic [LATENCY-1 :0]           delay_vld;                                 // сдвиговый регистр для сигнала vld 
    logic [FLEN - 1:0]             res_0, res_1, res_2, res_3, res_4, res_5, res_6, res_7, res_8, res_9;
    logic                          start_0, start_1, start_2, start_3, start_4, start_5, start_6, start_7, start_8, start_9;    

    logic [LATENCY-1:0]            res_vld_o, res_negative_o, err_o, busy_o;    // векторы для подключения выходных сигналов вычислителей 
    logic [FLEN - 1:0]             res_o [LATENCY-1:0];

    always_ff @ (posedge clk) begin
      if (rst) begin
        ptr_in    <= 1;                                                      // загружаем "1" в one-hot регистр селектор              
        n_out     <='0;                                                      // "0"  в регистр-селектор выходов вычислителей
        delay_vld <='0;  
      end
      else begin
        delay_vld <= {delay_vld[LATENCY-1:0],arg_vld};                       // передаем данные arg_vld с задержкой в LATENCY тактов на выход модуля
        if (arg_vld) begin 
          ptr_in    <= {ptr_in[LATENCY-2:0],ptr_in[LATENCY-1]};              // пришли данные - сдвигаем входной регистр-селектор маски
        end
       
        if (delay_vld[LATENCY-1]) begin                                      // если на выходе готовы данные то   
          if (n_out == (LATENCY-1 )) n_out <= '0;                            // и если дошли до последнего вычислителя то сбрасываем номер вычислителя    
          else                      n_out <= n_out + 1 ;                     // иначе увеличиваем номер вычислителя подключенного к выходу
        end
          
      end 
    end

  genvar i;


// создаем модули вычислителей в количестве LATENCY
  generate 
    for(i = 0; i < LATENCY; i = i + 1) begin:calc

     float_discriminant  inst (
                               .clk(clk),
                               .rst(rst),
                               .arg_vld(arg_vld & ptr_in[i]),
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


  always_comb begin
    res          = res_o[n_out]  ; 
    res_negative = res_negative_o[n_out];
    err          = err_o[n_out];
    res_vld      = delay_vld[LATENCY-1];
  end


endmodule