`timescale 1ns/10ps

module led_top(
    input wire clk,rst_n,
    input wire en,
    output wire led_out
);
    led #(100000000) the_led_Inst(clk,rst_n,en,led_out);
endmodule