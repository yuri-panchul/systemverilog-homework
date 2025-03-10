//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.


 
      //------------------------------------------------------------------------
      // вариант 2 FSM
      //------------------------------------------------------------------------
      
     // States
      enum logic [2:0]
      {
          st_idle       = 3'd0,
          st_1          = 3'd1,                
          st_2          = 3'd2,
          st_3          = 3'd3,
          st_4          = 3'd4,
          st_5          = 3'd5

        
      }
      state, next_state;
  
      logic [FLEN - 1:0] f_mul_a, f_mul_b, f_mul_res;       // connectors for multiplier
      logic [FLEN - 1:0] b_b, ac;                           // tmp result;   
      logic [FLEN - 1:0] b_tmp;                             // b - lach
      logic              f_mul_busy, f_mul_error, f_mul_arg_vld;
      //---------------------------------------------------------------------
      f_mult f_mul_i(                                       // module multiplier
                    .clk(clk),
                    .rst(rst),
                    .a(f_mul_a), 
                    .b(f_mul_b),
                    .up_valid(f_mul_arg_vld),
                    .res(f_mul_res),
                    .down_valid(f_mul_res_vld),
                    .busy(f_mul_busy),
                    .error(f_mul_error)
                   );

      //------------------------------------------------------------------------
 
      logic f_sub_arg_vld, f_sub_res_vld, f_sub_error;
 
      f_sub f_sub_i(
                    .clk(clk),
                    .rst(rst),
                    .a(b_b),                             // аргументы берем из предыдущих
                    .b(ac),                              // результатаов
                    .up_valid(f_sub_arg_vld),
                    .res(res),                           // подключаем к выходу модуля 
                    .down_valid(f_sub_res_vld),
                    .busy(sub_busy),
                    .error(f_sub_error)
                   );
   
      //------------------------------------------------------------------------
    
      always_comb
        begin
         next_state  = state;
         err         = '0;                               // ошибки не обнаружены
         
         case (state)
           st_idle:
                      begin
                        f_mul_a = a;
                        f_mul_b = c;
                        res_vld = '0;
                        if (arg_vld) begin
                          f_mul_arg_vld  = '1      ;     // если входные данные валидны запускаем вычисление a*c
                          busy           = '1      ;     // выставдяем флаг занятости  
                          next_state     = st_1    ;     // и переходим к следующей стадии возведение в квадрат
                          b_tmp          = b;
                        end
                       
                     end
          st_1:       
                     begin                              // умножитель у нас конвейерный на следующий такт запускаем возведение в степень b^2
                          f_mul_a       = b_tmp    ;    // загружаем умножитель значениями b 
                          f_mul_b       = b_tmp    ;    // и b
                          f_mul_arg_vld = '1       ;    // запускаем вычисление  
                          next_state  = st_2       ;    // на следующую стадию 
                    end

          st_2: 
                      begin
                        f_mul_arg_vld = '0;
                        if (f_mul_error) begin
                          err        = '1;              // и выставляем флаг ошибки 
                        end
                        if (f_mul_res_vld) begin        // ждем окончания умножения a*c   
                          f_mul_a = f_mul_res       ;   // загружаем умножитель значениями а*c 
                          f_mul_b = $realtobits(4)  ;   // и 4
                          f_mul_arg_vld = '1        ;   // запускаем  умножение 4*(a*c)
                          next_state  = st_3;           // и на следующую стадию
                        end
                      end

          st_3: 
                      begin
                        f_mul_arg_vld = '0      ;
                        if (f_mul_error) begin
                          err        = '1       ;     // за одно выставляем флаг ошибки 
                        end
                                                      // так как мы на втором такте загрузили b*b 
                                                      // проверку на готовность можно пропустить        
                          b_b   =  f_mul_res    ;     // сохраняем результат
                          next_state     = st_4 ;     // к следующей стадии 
                      end

           st_4:     
                      begin
                        f_mul_arg_vld = '0      ;
                        if (f_mul_error) begin
                          err        = '1       ;     // и выставляем флаг ошибки 
                        end
                        if (f_mul_res_vld) begin      // умножение 4*ac закончилось          
                          ac    =  f_mul_res    ;     // сохраняем результат
                                                      // аргументы к вычитателю подключены  
                          f_sub_arg_vld  = '1   ;     // запускаем вычитание
                          next_state     = st_5 ;     // к следующей стадии 
                        end
                      end

           st_5: 
                      begin
                        if (f_sub_error) begin
                          err        = '1        ;      // и выставляем флаг ошибки 
                      
                        end
                        if (f_sub_res_vld) begin         // вычитание b^2 - 4ac закончилось    
                          res_vld  = '1             ;    // выставляем флаг готовности  
                          busy     = '0             ;    // сбрасываем флаг занятости                          
                          f_sub_arg_vld = '0        ;    // данные на входе вычитателя не актуальны 
                          next_state     = st_idle  ;  
                        end
                      end
       endcase
       end
     
      //------------------------------------------------------------------------
      // Assigning next state

      always_ff @ (posedge clk)
          if (rst)
              state <= st_idle;
          else
              state <= next_state;

      //------------------------------------------------------------------------

      // конец 2 варианта FSM
  
endmodule
