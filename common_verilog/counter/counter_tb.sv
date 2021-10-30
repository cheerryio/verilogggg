`timescale 1ns/10ps

module counter_tb #(

)(

);
    logic clk,rst_n,en;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    logic co2,co62;
    counter #( 2) theCounterTbInst2(clk,rst_n,en,co2);
    //counter #(62) theCounterTbInst62(clk,rst_n,en,co62);
endmodule