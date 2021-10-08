`timescale 1ns/10ps

module down_sample_top #(
    parameter integer DW=24
)(
    input wire clk,rst_n,
    input wire en512000,
    input wire signed [DW-1:0] data_i,
    output wire valid,
    output wire signed [DW-1:0] data_o
);
    down_sample #(DW) the_down_sample_Inst(
        clk,rst_n,
        en512000,data_i,
        valid,data_o
    );
endmodule
