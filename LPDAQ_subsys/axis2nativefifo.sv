`timescale 1ns/10ps

module axis2nativefifo #(
    parameter integer DW=24
)(
    input wire clk,rst_n,
    input wire [DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DW-1:0] fifo_din,
    output logic fifo_wr,
    input wire fifo_full
);
    assign s_axis_tready=~fifo_full;
    assign fifo_din=s_axis_tdata;
    assign fifo_wr=s_axis_tvalid&s_axis_tready;
endmodule