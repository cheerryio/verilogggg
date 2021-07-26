`timescale 1ns/10ps

class item;
    rand bit [23:0] data;
endclass

module test;
    bit clk;
    always #50 clk=~clk;
    initial begin
        item i=new;
        bit [23:0] datas[$];
        repeat(10) begin
            i.randomize();
            datas.push_back(i.data);
            $display(i.data);
        end
        $display("%p",datas);
    end
endmodule