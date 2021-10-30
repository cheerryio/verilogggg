`timescale 1ns/10ps

module axi_fifo_data #(
    parameter int S_AXI_ID_WIDTH=1,
    parameter int S_AXI_DATA_WIDTH=32,
    parameter int S_AXI_ADDR_WIDTH=6,
    parameter int S_AXI_AWUSER_WIDTH=0,
    parameter int S_AXI_ARUSER_WIDTH=0,
    parameter int S_AXI_WUSER_WIDTH=0,
    parameter int S_AXI_RUSER_WIDTH=0,
    parameter int S_AXI_BUSER_WIDTH=0,
    
    parameter int S_AXIS_DATA_WIDTH=24
)(
    input wire clk,
    input wire rst_n,
    input wire [S_AXI_ID_WIDTH-1:0] s_axi_awid,
    input wire [S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [7:0] s_axi_awlen,
    input wire [2:0] s_axi_awsize,
    input wire [1:0] s_axi_awburst,
    input wire s_axi_awlock,
    input wire [3:0] s_axi_awcache,
    input wire [2:0] s_axi_awprot,
    input wire [3:0] s_axi_awqos,
    input wire [3:0] s_axi_awregion,
    input wire [S_AXI_AWUSER_WIDTH-1:0] s_axi_awuser,
    input wire s_axi_awvalid,
    output logic s_axi_awready,
    input wire [S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire s_axi_wlast,
    input wire [S_AXI_WUSER_WIDTH-1:0] s_axi_wuser,
    input wire  s_axi_wvalid,
    output logic s_axi_wready,
    output logic [S_AXI_ID_WIDTH-1:0] s_axi_bid,
    output logic [1:0] s_axi_bresp,
    output logic [S_AXI_BUSER_WIDTH-1:0] s_axi_buser,
    output logic s_axi_bvalid,
    input wire s_axi_bready,
    input wire [S_AXI_ID_WIDTH-1:0] s_axi_arid,
    input wire [S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire [7:0] s_axi_arlen,
    input wire [2:0] s_axi_arsize,
    input wire [1:0] s_axi_arburst,
    input wire s_axi_arlock,
    input wire [3:0] s_axi_arcache,
    input wire [2:0] s_axi_arprot,
    input wire [3:0] s_axi_arqos,
    input wire [3:0] s_axi_arregion,
    input wire [S_AXI_ARUSER_WIDTH-1:0] s_axi_aruser,
    input wire s_axi_arvalid,
    output logic s_axi_arready,
    output logic [S_AXI_ID_WIDTH-1:0] s_axi_rid,
    output logic [S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0] s_axi_rresp,
    output logic s_axi_rlast,
    output logic [S_AXI_RUSER_WIDTH-1:0] s_axi_ruser,
    output logic s_axi_rvalid,
    input wire s_axi_rready,

    input wire s_axis_tvalid,
    output logic s_axis_tready,
    input wire s_axis_tlast,
    input wire [S_AXIS_DATA_WIDTH-1:0] s_axis_tdata
);
    localparam int ADDR_LSB=S_AXI_ADDR_WIDTH/32+1;
    logic [S_AXI_ADDR_WIDTH-1:0] araddr;
    logic arv_flag;
    logic [7:0] arlen_cnt;
    logic [1:0] arburst;
    logic [7:0] arlen;
    logic [2:0] arsize;

    wire ar_shake=s_axi_arvalid&s_axi_arready;
    wire r_shake=s_axi_rvalid&s_axi_rready;
    assign s_axi_awready=1'b0;
    assign s_axi_wready=1'b0;
    assign s_axi_bvalid=1'b0;
    // assert ready for one cycle
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            s_axi_arready<=1'b0;
            arburst<='0;
            arlen<='0;
            arsize<='0;
        end
        else begin
            if(!s_axi_arready&&s_axi_arvalid&&~arv_flag) begin
                s_axi_arready<=1'b1;
                arburst<=s_axi_arburst;
                arlen<=s_axi_arlen;
                arsize<=s_axi_arsize;
            end
            else begin
                s_axi_arready<=1'b0;
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            arv_flag<=1'b0;
        end
        else begin
            if(ar_shake&&~arv_flag) begin
                arv_flag<=1'b1;
            end
            else if(s_axi_rvalid&&s_axi_rready&&arlen_cnt==arlen) begin
                arv_flag<=1'b0;
            end
        end
    end
    assign s_axi_rlast=(arlen_cnt==arlen)&arv_flag;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            araddr<='0;
            arlen_cnt<='0;
        end
        else begin
            if(!s_axi_arready&&s_axi_arvalid&&~arv_flag) begin
                araddr<=s_axi_araddr;
                arlen_cnt<='0;
            end
            else if((arlen_cnt<=arlen)&&r_shake) begin
                araddr[S_AXI_ADDR_WIDTH-1:ADDR_LSB]<=araddr[S_AXI_ADDR_WIDTH-1:ADDR_LSB]+1;
                arlen_cnt<=arlen_cnt+1'b1;
            end
        end
    end
    assign s_axi_rvalid=s_axis_tvalid&arv_flag;
    assign s_axis_tready=s_axi_rready&arv_flag;
    assign s_axi_rdata={{(S_AXI_DATA_WIDTH-S_AXIS_DATA_WIDTH){s_axis_tdata[S_AXIS_DATA_WIDTH-1]}},s_axis_tdata};
    assign s_axi_rresp=2'b0;
endmodule