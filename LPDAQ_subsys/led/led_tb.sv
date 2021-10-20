`timescale 1ns/10ps

module led_tb();
    bit clk,rst_n;
    bit en,led_out;
    always #5 clk=~clk;
    initial #50 rst_n=1'b1;
    initial en=1'b1;

    led #(100000000) the_led_Inst(clk,rst_n,en,led_out);
endmodule