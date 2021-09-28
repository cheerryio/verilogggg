`timescale 1ns/10ps

module axi4lite_stream_fifo_if #(
    parameter integer AXI_DW=32,
    parameter integer AXIS_DW=24
)(
    input wire clk,rst_n,

    input wire [5:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output logic s_axi_awready,
    input wire [AXI_DW-1:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output logic  s_axi_wready,
    output logic [1:0] s_axi_bresp,
    output logic s_axi_bvalid,
    input wire s_axi_bready,

    input wire [5:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output logic s_axi_arready,
    output logic [AXI_DW-1:0]  s_axi_rdata,
    output logic [1:0] s_axi_rresp,
    output logic s_axi_rvalid,
    input wire s_axi_rready,

    input wire [AXIS_DW-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output logic s_axis_tready,

    input wire [31:0] rd_cnt
);
    logic ar_shake,r_shake;
    logic r_hold;
    logic signed [AXIS_DW-1:0] data;
    assign s_axi_awready=1'b0;
    assign s_axi_wready=1'b0;
    assign s_axi_bresp=2'b00;
    assign s_axi_bvalid=1'b0;

    assign s_axi_arready=1'b1;
    assign s_axi_rresp=2'b00;
    assign s_axi_rdata={{(AXI_DW-AXIS_DW){data[AXIS_DW-1]}},data};
    assign s_axis_tready=s_axi_rvalid&s_axi_rready;
    
    assign ar_shake=s_axi_arvalid&s_axi_arready;
    assign r_shake=s_axi_rvalid&s_axi_rready;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            s_axi_rvalid<=1'b0;
        end
        else begin
            if(r_shake) begin
                s_axi_rvalid<=1'b0;
            end
            else if(ar_shake||r_hold) begin
                s_axi_rvalid<=(rd_cnt!=1'b0); 
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            data<='0;
        end
        else begin
            if(s_axi_arvalid&&s_axi_arready) begin
                data<=s_axis_tdata;
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            r_hold<=1'b0;
        end
        else begin
            if(ar_shake) begin
                r_hold<=1'b1;
            end
            else if(r_shake) begin
                r_hold<=1'b0;
            end
        end
    end
endmodule