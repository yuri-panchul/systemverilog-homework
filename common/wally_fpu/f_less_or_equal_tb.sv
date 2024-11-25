`ifdef LOCAL_TB

`include "util.svh"

module f_less_or_equal_tb;

    real  a, b;
    logic res, err;

    f_less_or_equal dut
    (
        .a   ( $realtobits ( a ) ),
        .b   ( $realtobits ( b ) ),
        .res ( res               ),
        .err ( err               )
    );

    //------------------------------------------------------------------------

    task test
    (
        input real ta, tb,
        input tres, terr
    );

        a = ta;
        b = tb;

        # 1;

        if (res !== tres || err != terr)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ INPUT    => {%s, %s}", `PF (a), `PF(b));
            $display ("++ EXPECTED => {%s, %s}", `PB (tres), `PB(terr));
            $display ("++ ACTUAL   => {%s, %s}", `PB (res), `PB(err));
            $finish  (1);
        end
        else
        begin
            $display ("++ TRACE    => {%s, %s, %s, %s}", `PF (a), `PF(b), `PB (res), `PB(err));
        end

    endtask

    //------------------------------------------------------------------------

    real infinity          = $bitstoreal (64'h7FF0000000000000),
         negative_infinity = $bitstoreal (64'hFFF0000000000000),
         not_a_number      = $bitstoreal (64'hFFF123456789abcd);

    //------------------------------------------------------------------------

    initial
    begin
        test (   1.23            ,   1.23            , 1, 0 );
        test (   1.24            ,   1.23            , 0, 0 );
        test (   1.22            ,   1.23            , 1, 0 );

        test (   1.23e5          ,   1.23            , 0, 0 );
        test (   1.23            ,   1.23e5          , 1, 0 );

        test (   1.23e-5         ,   1.23            , 1, 0 );
        test (   1.23            ,   1.23e-5         , 0, 0 );

        test ( - 1.23            , - 1.23            , 1, 0 );
        test ( - 1.24            , - 1.23            , 1, 0 );
        test ( - 1.22            , - 1.23            , 0, 0 );

        test ( - 1.23e5          , - 1.23            , 1, 0 );
        test ( - 1.23            , - 1.23e5          , 0, 0 );

        test ( - 1.23e-5         , - 1.23            , 0, 0 );
        test ( - 1.23            , - 1.23e-5         , 1, 0 );

        test (          infinity ,          infinity , 0, 1 );
        test (          infinity , negative_infinity , 0, 1 );
        test ( negative_infinity ,          infinity , 0, 1 );
        test ( negative_infinity , negative_infinity , 0, 1 );

        test (   1.23            , not_a_number      , 0, 1 );
        test ( - 1.23            , not_a_number      , 0, 1 );
        test (          infinity , not_a_number      , 0, 1 );
        test ( negative_infinity , not_a_number      , 0, 1 );
        test ( not_a_number      , not_a_number      , 0, 1 );

        test ( not_a_number      ,   1.23            , 0, 1 );
        test ( not_a_number      , - 1.23            , 0, 1 );
        test ( not_a_number      ,          infinity , 0, 1 );
        test ( not_a_number      , negative_infinity , 0, 1 );
        test ( not_a_number      , not_a_number      , 0, 1 );
    end

endmodule

`endif
