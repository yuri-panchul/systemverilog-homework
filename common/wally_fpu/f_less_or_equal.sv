module f_less_or_equal
(
    input [FLEN - 1:0] a, b,
    output             res, err
);

    // OpCtrl values
    //    110   min
    //    101   max
    //    010   equal
    //    001   less than
    //    011   less than or equal

    logic [XLEN - 1:0] CmpIntRes;

    fcmp i_fcmp
    (
        .Fmt        ( FMTBITS' (1)             ),  // format of fp number - double
        .OpCtrl     ( 3'b011                   ),  // see above table
        .Zfa        ( 1'b0                     ),  // Zfa variants: fminm, fmaxm, fleq, fltq

        .X          ( a                        ),  // original input (before unpacker)
        .Xs         ( a [FLEN - 1]             ),  // input sign
        .Xe         ( a [FLEN - 2 -: NE]       ),  // input exponent
        .Xm         ( a [NF        :  0]       ),  // input mantissa
        .XZero      ( a [FLEN - 2  :  0] == '0 ),  // is zero
        .XNaN       ( a [FLEN - 2 -: NE] == '1 ),  // is NaN
        .XSNaN      ( a [FLEN - 2 -: NE] == '1 ),  // is signaling NaN

        .Y          ( b                        ),  // original input (before unpacker)
        .Ys         ( b [FLEN - 1]             ),  // input sign
        .Ye         ( b [FLEN - 2 -: NE]       ),  // input exponent
        .Ym         ( b [NF        :  0]       ),  // input mantissa
        .YZero      ( b [FLEN - 2  :  0] == '0 ),  // is zero
        .YNaN       ( b [FLEN - 2 -: NE] == '1 ),  // is NaN
        .YSNaN      ( b [FLEN - 2 -: NE] == '1 ),  // is signaling NaN

        .CmpNV      ( err                      ),  // invalid flag
        .CmpFpRes   (                          ),  // compare floating-point result
        .CmpIntRes  ( CmpIntRes                )   // compare integer result
    );

    assign res = CmpIntRes [0];

endmodule
