`timescale 1ns/10ps

program test_task;
    initial begin
        $display("in progeam");
    end
endprogram

module learn_task;
    task normal_task(input logic in,output logic out);
        out=1'b1;
    endtask
    logic in,out;
    initial begin
        out=1'b0;
        normal_task(in,out);
        $display("out=%0b",out); 
    end
endmodule