module fifo_monitor
# (
    parameter width = 1,
              depth = 0,
              allow_push_when_full_with_pop = 0
)
(
    input               clk,
    input               rst,
    input               push,
    input               pop,
    input [width - 1:0] write_data,
    input [width - 1:0] read_data,
    input               empty,
    input               full
);

    logic [width - 1:0] queue [$];
    logic [width - 1:0] dummy;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            // Checking

            assert (~ (push & full & ~ (pop & allow_push_when_full_with_pop)));
            assert (~ (pop  & empty));

            assert (~ ( queue.size () == 0     & ~ empty ));
            assert (~ ( queue.size () == depth & ~ full  ));

            // The following assertions
            // will not work with some FIFO microarchitectures.
            // An exam/interview question: what kind of microarchitectures?
            //
            // assert ( empty == ( queue.size () == 0     ));
            // assert ( full  == ( queue.size () == depth ));

            assert (~ (  ~ empty
                       & queue.size () != 0
                       & read_data != queue [0] ));

            // Modeling

            if (push)
                queue.push_back (write_data);

            if (pop & queue.size () > 0)
            begin
                `ifdef __ICARUS__
                    // Some version of Icarus has a bug, and this is a workaround
                    queue.delete (0);
                `else
                    dummy = queue.pop_front ();
                `endif
            end

            // Logging

            if (push | pop)
            begin
                if (push)
                    $write ("push %h", write_data);
                else
                    $write ("       ");

                if (pop)
                    $write ("  pop %h", read_data);
                else
                    $write ("        ");

                $write ("  %5s %4s",
                    empty ? "empty" : "     ",
                    full  ? "full"  : "    ");

                $write (" [");

                for (int i = 0; i < queue.size (); i ++)
                    $write (" %h", queue [queue.size () - i - 1]);

                $display (" ]");
            end
        end
    end

endmodule
