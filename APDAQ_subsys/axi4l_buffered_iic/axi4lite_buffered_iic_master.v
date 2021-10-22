
`timescale 1ns/10ps

module axi4lite_buffered_iic_master #
(
    parameter real CLK_FREQ = 100e6,
    // max time: 1023 / CLK_FREQ
    // T_SSU: Setup time for repeat START
    // T_SSU + T_PH = MIN BUS IDLE
    parameter real T_SSU  = 600,
    parameter real T_SH   = 600,
    // T_DSU + T_SCLH + T_DH = 1 / (BUS FREQ)
    // !!! Be sure T_DSU is the maximum one !!!
    parameter real T_DSU  = 1300,
    parameter real T_SCLH = 900,
    parameter real T_DH   = 300,
    parameter real T_PSU  = 600,
    parameter real T_PH   = 700,


    // Parameters of Axi Slave Bus Interface S_AXI
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    parameter integer C_S_AXI_ADDR_WIDTH	= 4
)
(
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 IIC_MASTER_IRQ INTERRUPT" *)
    // Supported parameter: SENSITIVITY { LEVEL_HIGH, LEVEL_LOW, EDGE_RISING, EDGE_FALLING }
    // Normally LEVEL_HIGH is assumed.  Use this parameter to force the level
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    output wire irq,
    
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SCL_I" *)
    input wire scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SCL_O" *)
    output wire scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SCL_T" *)
    output wire scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SDA_I" *)
    
    input wire sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SDA_O" *)
    output wire sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_MASTER SDA_T" *)
    output wire sda_t,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S_AXI
    input wire  s_axi_aclk,
    input wire  s_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input wire [2 : 0] s_axi_awprot,
    input wire  s_axi_awvalid,
    output wire  s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire  s_axi_wvalid,
    output wire  s_axi_wready,
    output wire [1 : 0] s_axi_bresp,
    output wire  s_axi_bvalid,
    input wire  s_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire [2 : 0] s_axi_arprot,
    input wire  s_axi_arvalid,
    output wire  s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [1 : 0] s_axi_rresp,
    output wire  s_axi_rvalid,
    input wire  s_axi_rready
);
    (* mark_debug = "true" *) wire [3:0] lc_addr;
    (* mark_debug = "true" *) wire lc_read;
    (* mark_debug = "true" *) wire [31:0] lc_rddata;
    (* mark_debug = "true" *) wire lc_write;
    (* mark_debug = "true" *) wire [31:0] lc_wrdata;
    (* mark_debug = "true" *) wire [3:0] lc_byteen;
    wire axi_rShaked;
    // Instantiation of Axi Bus Interface S_AXI
    axi4lite_buffered_iic_master_S_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) axi4lite_buffered_iic_master_S_AXI_Inst (
        .lc_address(lc_addr),
        .lc_read(lc_read),
        .lc_readdata(lc_rddata),
        .lc_write(lc_write),
        .lc_writedata(lc_wrdata),
        .lc_byteenable(lc_byteen),
        .axi_rShaked(axi_rShaked),
        .S_AXI_ACLK(s_axi_aclk),
        .S_AXI_ARESETN(s_axi_aresetn),
        .S_AXI_AWADDR(s_axi_awaddr),
        .S_AXI_AWPROT(s_axi_awprot),
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_WDATA(s_axi_wdata),
        .S_AXI_WSTRB(s_axi_wstrb),
        .S_AXI_WVALID(s_axi_wvalid),
        .S_AXI_WREADY(s_axi_wready),
        .S_AXI_BRESP(s_axi_bresp),
        .S_AXI_BVALID(s_axi_bvalid),
        .S_AXI_BREADY(s_axi_bready),
        .S_AXI_ARADDR(s_axi_araddr),
        .S_AXI_ARPROT(s_axi_arprot),
        .S_AXI_ARVALID(s_axi_arvalid),
        .S_AXI_ARREADY(s_axi_arready),
        .S_AXI_RDATA(s_axi_rdata),
        .S_AXI_RRESP(s_axi_rresp),
        .S_AXI_RVALID(s_axi_rvalid),
        .S_AXI_RREADY(s_axi_rready)
    );

    iic_master
    #(
        .CLK_FREQ(CLK_FREQ),
        .T_SSU   (T_SSU    * 1.0e-9),
        .T_SH    (T_SH     * 1.0e-9),
        .T_DSU   (T_DSU    * 1.0e-9),
        .T_SCLH  (T_SCLH   * 1.0e-9),
        .T_DH    (T_DH     * 1.0e-9),
        .T_PSU   (T_PSU    * 1.0e-9),
        .T_PH    (T_PH     * 1.0e-9)
    )  the_iic_master
    (
        .csi_clk        (s_axi_aclk),
        .csi_reset      (~s_axi_aresetn),
        .avs_address    (lc_addr[3:2]),
        .avs_write      (lc_write),
        .avs_writedata  (lc_wrdata),
        .avs_byteenable (lc_byteen),
        .avs_read       (lc_read),                 // read latency = 1
        .avs_readdata   (lc_rddata),
        .axi_rShaked    (axi_rShaked),
        .ins_irq        (irq),
        .scl_i          (scl_i),
        .scl_o          (scl_o),
        .scl_t          (scl_t),
        .sda_i          (sda_i),
        .sda_o          (sda_o),
        .sda_t          (sda_t)
    );

endmodule
