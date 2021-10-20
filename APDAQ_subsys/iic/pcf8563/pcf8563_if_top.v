`timescale 1ns/10ps

module pcf8563_if_top #(
    parameter integer DIV = 500
)(
    input wire clk,rst_n,en,
    input wire start,
    output wire [7:0] rdata,
    output wire done,

    output wire scl,
    inout wire sda
);
    pcf8563_if #(DIV) the_pcf8563_if_Inst(
        clk,rst_n,en,
        start,
        rdata,
        done,
        scl,
        sda
    );
endmodule