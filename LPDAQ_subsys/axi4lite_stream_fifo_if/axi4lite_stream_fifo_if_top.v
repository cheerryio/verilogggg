`timescale 1ns/10ps
module axi4lite_stream_fifo_if_top #(
    parameter integer AXI_DW=32,
    parameter integer AXIS_DW=24
)(
    input wire clk,rst_n,

    input wire [5:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [AXI_DW-1:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire  s_axi_wready,
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,

    input wire [5:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [AXI_DW-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready,

    input wire [AXIS_DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,

    input wire [31:0] rd_cnt
);
    axi4lite_stream_fifo_if #(AXI_DW,AXIS_DW) the_axi4lite_stream_fifo_if_Inst(
        clk,rst_n,
        s_axi_awaddr,s_axi_awprot,
        s_axi_awvalid,s_axi_awready,
        s_axi_wdata,
        s_axi_wstrb,
        s_axi_wvalid,s_axi_wready,
        s_axi_bresp,
        s_axi_bvalid,s_axi_bready,
        s_axi_araddr,s_axi_arprot,
        s_axi_arvalid,s_axi_arready,
        s_axi_rdata,
        s_axi_rresp,
        s_axi_rvalid,s_axi_rready,
        s_axis_tdata,s_axis_tvalid,s_axis_tready,
        rd_cnt
    );
endmodule
