`timescale 1ns/10ps

module axis2nativefifo_top #(
    parameter integer DW=24
)(
    input wire clk,rst_n,
    input wire [DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    output wire [DW-1:0] fifo_din,
    output wire fifo_wr,
    input wire fifo_full
);
    axis2nativefifo #(DW) the_axis2nativefifo_Inst(
        clk,rst_n,
        s_axis_tdata,s_axis_tvalid,s_axis_tready,
        fifo_din,fifo_wr,fifo_full
    );
endmodule
