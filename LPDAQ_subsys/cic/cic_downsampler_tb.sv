`timescale 1ns/10ps

module cicDownSampler_tb #(

)(

);
    localparam integer W = 10;
    logic clk,rst_n;
    initial begin
        clk=0;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    logic en50,en25;
    counter #(2)
    theCounterInst50(clk,rst_n,1'b1,en50);
    counter #(4)
    theCounterInst25(clk,rst_n,1'b1,en25);
    logic signed [W-1:0] in,out;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin in<='0; end
        else in<=in+1'b1;
    end
    cicDownSampler #()
    theCicDownSamplerInst(clk,rst_n,en50,en25,in,out);
endmodule