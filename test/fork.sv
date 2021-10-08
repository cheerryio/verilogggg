
`timescale 1ns/10ps

module fork_test;
    initial begin
        fork
            begin
                #100;
                $display("fork1:%t",$time);
            end
            begin
                #200;
                $display("fork2:%t",$time);
                hello;
            end
        join_none
    end
endmodule