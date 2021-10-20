`timescale 1ns/10ps

module orthDds_tb #(

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
    real freqr = 2e4, fstepr = 49e6/(1e-3*100e6); // from 1MHz to 50MHz in 1ms
    logic signed [31:0] freq;
    always@(posedge clk) begin
        freq <= 2.0**32 * freqr / 10e6; // frequency to freq control word
    end
    logic signed [31:0] phase = '0;
    logic signed [11:0] sin,cos;
    orthDds #(32, 12, 13) theOrthDdsInst(clk, rst_n, 1'b1, freq, 32'sd0,sin,cos);
endmodule