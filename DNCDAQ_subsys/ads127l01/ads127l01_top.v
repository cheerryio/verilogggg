`timescale 1ns/10ps

module ads127l01_top(
    input wire clk,rst_n,en,
    input wire sck,fsync,din,
    output wire start,pd, // power-down pin
    output wire [23:0] data,
    output wire valid,
    output wire cs_n,dsin,dout
);
    ads127l01 the_ads127l01_Inst(
        clk,rst_n,en,
        sck,fsync,din,
        start,pd,
        data,
        valid,
        cs_n,dsin,dout
    );
endmodule