`timescale 1ns/10ps

module axi4l_fifo_if_top #(
    parameter integer AXI_DW = 32,
    parameter integer DW = 32,
    parameter integer FIFO_AW = 10,
    parameter integer TXD_GRP_SIZE = 8,
    parameter integer TXD_REV_TYPE = 0, // 1 : innter-group; 2: inner-group
    parameter integer RXD_GRP_SIZE = 8,
    parameter integer RXD_REV_TYPE = 0  // 1 : innter-group; 2: inner-group
)(
    input wire clk, rst_n,
    // --- s_axi ---
    input   wire [5 : 0]    s_axi_awaddr,
    input   wire [2 : 0]    s_axi_awprot,
    input   wire            s_axi_awvalid,
    output  wire           s_axi_awready,
    input   wire [AXI_DW-1:0]   s_axi_wdata,
    input   wire [3 : 0]    s_axi_wstrb,
    input   wire            s_axi_wvalid,
    output  wire           s_axi_wready,
    output  wire [1 : 0]   s_axi_bresp,
    output  wire           s_axi_bvalid,
    input   wire            s_axi_bready,
    input   wire [5 : 0]    s_axi_araddr,
    input   wire [2 : 0]    s_axi_arprot,
    input   wire            s_axi_arvalid,
    output  wire           s_axi_arready,
    output  wire [AXI_DW-1:0]  s_axi_rdata,
    output  wire [1 : 0]   s_axi_rresp,
    output  wire           s_axi_rvalid,
    input   wire            s_axi_rready,
    // --- fifo if ----
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_DATA" *)
    input wire [DW-1:0] rx_fifo_dout,
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_EN" *)
    output wire rx_fifo_rd,
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_read:1.0 FIFO_READ EMPTY" *)
    input wire empty,
    input   wire  [FIFO_AW-1:0] rx_fifo_dcnt,
    output  wire                rx_fifo_clr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_DATA" *)
    output wire [DW-1:0] tx_fifo_din,
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_EN" *)
    output wire tx_fifo_wr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE FULL" *)
    input wire full,
    input   wire  [FIFO_AW-1:0] tx_fifo_dcnt,
    output  wire                tx_fifo_clr,
    // --- interrupt ---
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 AXI4l_FIFO_IF_INTR INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    output wire intr
);
    axi4l_fifo_if #(AXI_DW,DW,FIFO_AW,TXD_GRP_SIZE,TXD_REV_TYPE,RXD_GRP_SIZE,RXD_REV_TYPE)
    the_axi4l_fifo_if_Inst(
        clk,rst_n,
        s_axi_awaddr,
        s_axi_awprot,
        s_axi_awvalid,
        s_axi_awready,
        s_axi_wdata,
        s_axi_wstrb,
        s_axi_wvalid,
        s_axi_wready,
        s_axi_bresp,
        s_axi_bvalid,
        s_axi_bready,
        s_axi_araddr,
        s_axi_arprot,
        s_axi_arvalid,
        s_axi_arready,
        s_axi_rdata,
        s_axi_rresp,
        s_axi_rvalid,
        s_axi_rready,
        rx_fifo_rd,
        rx_fifo_dout,
        rx_fifo_dcnt,
        full,
        rx_fifo_clr,
        tx_fifo_wr,
        tx_fifo_din,
        tx_fifo_dcnt,
        tx_fifo_clr,
        intr
    );
endmodule