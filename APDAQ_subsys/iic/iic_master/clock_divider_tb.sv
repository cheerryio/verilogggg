`timescale 1ns/10ps

module clock_divider_tb();
    bit clk,clk_div;
    bit rst_n,en;
    bit high_mid,low_mid,fall;
    always #5 clk=~clk;
    initial begin
        rst_n=1'b0;
        #50;
        rst_n=1'b1;
        en=1'b1;
    end
    clock_divider #(500) the_clock_divider_Inst(
        clk,rst_n,en,
        clk_div,
        high_mid,low_mid,fall
    );
endmodule