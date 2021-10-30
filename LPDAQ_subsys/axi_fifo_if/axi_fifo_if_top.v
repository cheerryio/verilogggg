`timescale 1ns/10ps

module axi_fifo_if_top #(
    parameter integer S_AXI_ID_WIDTH=1,
    parameter integer S_AXI_DATA_WIDTH=32,
    parameter integer S_AXI_ADDR_WIDTH=6,
    parameter integer S_AXI_AWUSER_WIDTH=0,
    parameter integer S_AXI_ARUSER_WIDTH=0,
    parameter integer S_AXI_WUSER_WIDTH=0,
    parameter integer S_AXI_RUSER_WIDTH=0,
    parameter integer S_AXI_BUSER_WIDTH=0,

    parameter integer S_AXIS_DATA_WIDTH=24
)(
    input wire clk,
    input wire rst_n,
    input wire [S_AXI_ID_WIDTH-1:0] s_axi_awid,
    input wire [S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [7:0] s_axi_awlen,
    input wire [2:0] s_axi_awsize,
    input wire [1:0] s_axi_awburst,
    input wire  s_axi_awlock,
    input wire [3:0] s_axi_awcache,
    input wire [2:0] s_axi_awprot,
    input wire [3:0] s_axi_awqos,
    input wire [3:0] s_axi_awregion,
    input wire [S_AXI_AWUSER_WIDTH-1:0] s_axi_awuser,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire s_axi_wlast,
    input wire [S_AXI_WUSER_WIDTH-1 : 0] s_axi_wuser,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    output wire [S_AXI_ID_WIDTH-1 : 0] s_axi_bid,
    output wire [1:0] s_axi_bresp,
    output wire [S_AXI_BUSER_WIDTH-1 : 0] s_axi_buser,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    input wire [S_AXI_ID_WIDTH-1 : 0] s_axi_arid,
    input wire [S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire [7:0] s_axi_arlen,
    input wire [2:0] s_axi_arsize,
    input wire [1:0] s_axi_arburst,
    input wire s_axi_arlock,
    input wire [3:0] s_axi_arcache,
    input wire [2:0] s_axi_arprot,
    input wire [3:0] s_axi_arqos,
    input wire [3:0] s_axi_arregion,
    input wire [S_AXI_ARUSER_WIDTH-1 : 0] s_axi_aruser,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [S_AXI_ID_WIDTH-1 : 0] s_axi_rid,
    output wire [S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rlast,
    output wire [S_AXI_RUSER_WIDTH-1 : 0] s_axi_ruser,
    output wire s_axi_rvalid,
    input wire s_axi_rready,

    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [S_AXIS_DATA_WIDTH-1:0] s_axis_tdata,

    input wire prog_empty,
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 PROG_EMPTY INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    output wire prog_empty_intr,
    input wire prog_full,
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 PROG_FULL INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    output wire prog_full_intr
);

    axi_fifo_data #(
        S_AXI_ID_WIDTH,S_AXI_DATA_WIDTH,S_AXI_ADDR_WIDTH,
        S_AXI_AWUSER_WIDTH,S_AXI_ARUSER_WIDTH,
        S_AXI_WUSER_WIDTH,S_AXI_RUSER_WIDTH,S_AXI_BUSER_WIDTH
    ) the_axi_fifo_data_Inst(
		.clk(clk),
		.rst_n(rst_n),
		.s_axi_awid(s_axi_awid),
		.s_axi_awaddr(s_axi_awaddr),
		.s_axi_awlen(s_axi_awlen),
		.s_axi_awsize(s_axi_awsize),
		.s_axi_awburst(s_axi_awburst),
		.s_axi_awlock(s_axi_awlock),
		.s_axi_awcache(s_axi_awcache),
		.s_axi_awprot(s_axi_awprot),
		.s_axi_awqos(s_axi_awqos),
		.s_axi_awregion(s_axi_awregion),
		.s_axi_awuser(s_axi_awuser),
		.s_axi_awvalid(s_axi_awvalid),
		.s_axi_awready(s_axi_awready),
		.s_axi_wdata(s_axi_wdata),
		.s_axi_wstrb(s_axi_wstrb),
		.s_axi_wlast(s_axi_wlast),
		.s_axi_wuser(s_axi_wuser),
		.s_axi_wvalid(s_axi_wvalid),
		.s_axi_wready(s_axi_wready),
		.s_axi_bid(s_axi_bid),
		.s_axi_bresp(s_axi_bresp),
		.s_axi_buser(s_axi_buser),
		.s_axi_bvalid(s_axi_bvalid),
		.s_axi_bready(s_axi_bready),
		.s_axi_arid(s_axi_arid),
		.s_axi_araddr(s_axi_araddr),
		.s_axi_arlen(s_axi_arlen),
		.s_axi_arsize(s_axi_arsize),
		.s_axi_arburst(s_axi_arburst),
		.s_axi_arlock(s_axi_arlock),
		.s_axi_arcache(s_axi_arcache),
		.s_axi_arprot(s_axi_arprot),
		.s_axi_arqos(s_axi_arqos),
		.s_axi_arregion(s_axi_arregion),
		.s_axi_aruser(s_axi_aruser),
		.s_axi_arvalid(s_axi_arvalid),
		.s_axi_arready(s_axi_arready),
		.s_axi_rid(s_axi_rid),
		.s_axi_rdata(s_axi_rdata),
		.s_axi_rresp(s_axi_rresp),
		.s_axi_rlast(s_axi_rlast),
		.s_axi_ruser(s_axi_ruser),
		.s_axi_rvalid(s_axi_rvalid),
		.s_axi_rready(s_axi_rready),

        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tdata(s_axis_tdata)
    );

    axi_fifo_intr the_axi_fifo_intr_Inst(
        .prog_empty(prog_empty),.prog_empty_mask(1'b0),
        .prog_empty_intr(prog_empty_intr),
        .prog_full(prog_full),.prog_full_mask(1'b1),
        .prog_full_intr(prog_full_intr)
    );
endmodule