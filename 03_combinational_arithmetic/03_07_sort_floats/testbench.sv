//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

`include "util.svh"

// In this code we assume FLEN=64 and use "real" type, 64-bit constants,
// $bitstoreal, $realtobits and the corresponding macros for printing.
// If we ever change FLEN to 32, we have to use "shortreal" type,
// 32-bit constants, $bitstoshortreal and $shortrealtobits.

module testbench;

    // If we change FLEN to 32, we have to change these constants

    localparam [FLEN - 1:0] inf     = 64'h7FF0_0000_0000_0000,
                            neg_inf = 64'hFFF0_0000_0000_0000,
                            zero    = 64'h0000_0000_0000_0000,
                            nan     = 64'h7FF1_2345_6789_ABCD;

    //--------------------------------------------------------------------------

    function is_err ( [FLEN - 1:0] a_bits );

        // This covers both Infinity (positive and negative)
        // and NaN (Not a Number)

        return a_bits [FLEN - 2 -: NE] === '1;

    endfunction

    //--------------------------------------------------------------------------

    `define DEFINE_SORT(N)                                              \
                                                                        \
        task fsort``N (inout [0:N - 1][FLEN - 1:0] a);                  \
            repeat (N - 1)                                              \
                for (int i = 0; i < N - 1; i ++)                        \
                    if ($bitstoreal (a [i]) > $bitstoreal (a [i + 1]))  \
                        { a [i], a [i + 1] } = { a [i + 1], a [i] };    \
        endtask                                                         \

    `DEFINE_SORT (2)
    `DEFINE_SORT (3)

    `undef DEFINE_SORT

    //--------------------------------------------------------------------------

    `define DEFINE_ARR_EQUAL(N)                                              \
                                                                             \
        function farr_eq``N (input [0:N - 1][FLEN - 1:0] arr_a, arr_b);      \
                                                                             \
            logic [FLEN - 1:0] a, b;                                         \
            logic both_zeros;                                                \
                                                                             \
            for (int i = 0; i < N; i ++)                                     \
            begin                                                            \
                a = arr_a [i];                                               \
                b = arr_b [i];                                               \
                                                                             \
                both_zeros =    { a [FLEN - 2:0] , b [FLEN - 2:0] } === '0   \
                             && ( a [FLEN - 1  ] ^ b [FLEN - 1  ] ) !== 'x;  \
                                                                             \
                if (a !== b && ! both_zeros)                                 \
                    return 0;                                                \
            end                                                              \
                                                                             \
            return 1;                                                        \
                                                                             \
        endfunction                                                          \

    `DEFINE_ARR_EQUAL (2)
    `DEFINE_ARR_EQUAL (3)

    `undef DEFINE_ARR_EQUAL

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic [FLEN - 1:0] a, b, c;

    wire [FLEN - 1:0] res1_ab0;
    wire [FLEN - 1:0] res1_ab1;

    wire [0:1][FLEN - 1:0] res2_array;
    wire [0:2][FLEN - 1:0] res3_array;

    wire err1, err2, err3;

    //--------------------------------------------------------------------------
    // Instantiating DUT

    sort_two_floats_ab dut_sort_2_ab (
        .a    ( a        ),
        .b    ( b        ),
        .res0 ( res1_ab0 ),
        .res1 ( res1_ab1 ),
        .err  ( err1     )
    );

    sort_two_floats_array dut_sort_2_array (
        .unsorted ( { a, b }   ),
        .sorted   ( res2_array ),
        .err      ( err2       )
    );

    sort_three_floats dut_sort_3 (
        .unsorted ( { a, b, c } ),
        .sorted   ( res3_array  ),
        .err      ( err3        )
    );

    //--------------------------------------------------------------------------
    // Run single test

    logic [0:1][FLEN - 1:0] expected2;
    logic [0:2][FLEN - 1:0] expected3;

    logic exp_err2;
    logic exp_err3;

    int passed_tests_count = 0;

    task test
        (
        input [FLEN - 1:0] ta, tb, tc
        );

        a = ta;
        b = tb;
        c = tc;

        expected2 = { ta, tb };
        expected3 = { ta, tb, tc };

        # 1;

        fsort2 ( expected2 );
        fsort3 ( expected3 );

        exp_err2 = is_err ( ta ) || is_err ( tb );
        exp_err3 = exp_err2      || is_err ( tc );

        // Testing testbench for 0 detection
        //
        // force { res1_ab0, res1_ab1 } = { 1'b0, 63'b0, 1'b1, 63'b0 };
        // force res2_array = { 1'b1, 63'b0, 1'b0, 63'b0 };
        // expected2  = { 1'b0, 63'b0, 1'b1, 63'b0 };
        // force res3_array = { 1'b1, 63'b0, 1'b1, 63'b0, 1'b0, 63'b0 };
        // expected3  = { 1'b0, 63'b0, 1'b1, 63'b0, 1'b1, 63'b0 };

        if ( err1 !== exp_err2 || err2 !== exp_err2 || err3 !== exp_err3)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ INPUT    => {%s, %s, %s}", `PF(a), `PF(b), `PF(c)    );
            $display ("++ EXPECTED => {%s, %s, %s}", `PB(exp_err2), `PB(exp_err2), `PB(exp_err3)  );
            $display ("++ ACTUAL   => {%s, %s, %s}", `PB(err1), `PB(err2),  `PB(err3) );
            $finish  (1);
        end
        else if ( ( exp_err2 === '0 && exp_err3 === '0)    && (
                  ( ! farr_eq2 ( { res1_ab0, res1_ab1 }, expected2) ) ||
                  ( ! farr_eq2 (   res2_array,           expected2) ) ||
                  ( ! farr_eq3 (   res3_array,           expected3) ) ) )
        begin
            $display ("FAIL %s", `__FILE__);

            $display ("++ INPUT    => {%s, %s, %s}", `PF_BITS(a), `PF_BITS(b), `PF_BITS(c));

            $display ("++ EXPECTED => {%s, %s} and {%s, %s} and {%s, %s, %s}",
                `PF_BITS(expected2[0]),
                `PF_BITS(expected2[1]),

                `PF_BITS(expected2[0]),
                `PF_BITS(expected2[1]),

                `PF_BITS(expected3[0]),
                `PF_BITS(expected3[1]),
                `PF_BITS(expected3[2]));

            $display ("++ ACTUAL   => {%s, %s} and {%s, %s} and {%s, %s, %s}",
                `PF_BITS(res1_ab0),
                `PF_BITS(res1_ab1),

                `PF_BITS(res2_array[0]),
                `PF_BITS(res2_array[1]),

                `PF_BITS(res3_array[0]),
                `PF_BITS(res3_array[1]),
                `PF_BITS(res3_array[2]));

            $finish (1);
        end
        else
        begin
            // $display("-- TRACE => {%s, %s} and {%s, %s, %s}",
            //     `PF_BITS(res_two0), `PF_BITS(res_two1), `PF_BITS(res_three0), `PF_BITS(res_three1), `PF_BITS(res_three2));
            passed_tests_count += 1;
        end
    endtask


    //--------------------------------------------------------------------------
    // Run testbench

    localparam N = 7;

    // If we change FLEN to 32, we have to use $shortrealtobits

    logic [0:N - 1][FLEN - 1:0] nums =
    {
        zero,
        inf,
        nan,
        $realtobits ( 1     ),
        $realtobits ( 2.34  ),
        $realtobits ( 5.6e5 ),
        $realtobits ( 8e-7  )
    };

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following line
            // to generate a VCD file and analyze it using GTKwave

            // $dumpvars (0, testbench);
        `endif

        for (int i  = 0; i  <  N; i  ++)
        for (int j  = 0; j  <  N; j  ++)
        for (int k  = 0; k  <  N; k  ++)
        for (int si = 0; si <= 1; si ++)
        for (int sj = 0; sj <= 1; sj ++)
        for (int sk = 0; sk <= 1; sk ++)
            test
            (
               (si << (FLEN - 1)) | nums [i],
               (sj << (FLEN - 1)) | nums [j],
               (sk << (FLEN - 1)) | nums [k]
            );

        $display ("-- %s TRACE => %d tests passed", `__FILE__, passed_tests_count);
        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
