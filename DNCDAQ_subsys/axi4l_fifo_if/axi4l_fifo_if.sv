`timescale 1ns/10ps

`default_nettype none
`timescale 1ns/1ps

//    reg #       rd                  wr
//      0       rx_fifo_dout        tx_fifo_din
//      1       rx_fifo_dcnt        write any value to clear rx_fifo
//      2       tx_fifo_dcnt        ........................ tx_fifo
//      3       rxf_irq_th          rxf_irq_th
//      4       txe_irq_th          txe_irq_th
//      
//      8       ie = {txe, rxf}     ie = {txe, rxf}
//      9       is = {txe, rxf}     xxxxx

module axi4l_fifo_if #(
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
    output  logic           s_axi_awready,
    input   wire [AXI_DW-1:0]   s_axi_wdata,
    input   wire [3 : 0]    s_axi_wstrb,
    input   wire            s_axi_wvalid,
    output  logic           s_axi_wready,
    output  logic [1 : 0]   s_axi_bresp,
    output  logic           s_axi_bvalid,
    input   wire            s_axi_bready,
    input   wire [5 : 0]    s_axi_araddr,
    input   wire [2 : 0]    s_axi_arprot,
    input   wire            s_axi_arvalid,
    output  logic           s_axi_arready,
    output  logic [AXI_DW-1:0]  s_axi_rdata,
    output  logic [1 : 0]   s_axi_rresp,
    output  logic           s_axi_rvalid,
    input   wire            s_axi_rready,
    // --- fifo if ----
    output  logic               rx_fifo_rd,
    input   wire  [DW-1:0]      rx_fifo_dout,
    input   wire  [FIFO_AW-1:0] rx_fifo_dcnt,
    input   wire                full,
    output  wire                rx_fifo_clr,
    output  logic               tx_fifo_wr,
    output  logic [DW-1:0]      tx_fifo_din,
    input   wire  [FIFO_AW-1:0] tx_fifo_dcnt,
    output  wire                tx_fifo_clr,
    // --- interrupt ---
    output logic intr
);
    wire rst = ~rst_n;
    logic regs_wr, regs_rd;
    // ==== aw channel ====
    assign s_axi_awready = 1'b1;    // always ready
    logic [3 : 0] waddr_reg;   // byte addr --> reg addr
    always_ff@(posedge clk) begin
        if(rst) waddr_reg <= '0;
        else if(s_axi_awvalid) waddr_reg <= s_axi_awaddr[5 : 2];
    end
    // === w channel ===
    assign regs_wr = s_axi_wvalid & s_axi_wready;
    always_ff@(posedge clk) begin
        if(rst) s_axi_wready <= 1'b0;
        else if(s_axi_awvalid) s_axi_wready <= 1'b1;          //waddr got
        else if(s_axi_wvalid & s_axi_wready) s_axi_wready <= 1'b0; //handshake
    end
    // === b ch ===
    assign s_axi_bresp = 2'b00;     // always ok
    always_ff@(posedge clk) begin
        if(rst) s_axi_bvalid <= 1'b0;
        else if(s_axi_wvalid & s_axi_wready) s_axi_bvalid <= 1'b1;//wdata got
        else if(s_axi_bvalid & s_axi_bready) s_axi_bvalid <= 1'b0;//handshake
    end
    // === ar ch ===
    logic [3 : 0] raddr_reg;
    always_ff@(posedge clk) begin
        if(rst) raddr_reg <= 1'b0;
        else if(s_axi_arvalid) raddr_reg <= s_axi_araddr[5 : 2];
    end
    always_ff@(posedge clk) begin
        if(rst) s_axi_arready <= 1'b0;
        else if(s_axi_arvalid & ~s_axi_arready) s_axi_arready <= 1'b1; //raddr got
        else if(s_axi_arvalid &  s_axi_arready) s_axi_arready <= 1'b0; //handshake
    end
    assign regs_rd = s_axi_arvalid & s_axi_arready;
    // === r ch ===
    assign s_axi_rresp = 2'b00;     // always ok
    always_ff@(posedge clk) begin
        if(rst) s_axi_rvalid <= 1'b0;
        else if(regs_rd) s_axi_rvalid <= 1'b1;
        else if(s_axi_rvalid & s_axi_rready) s_axi_rvalid <= 1'b0;
    end

    // ====================
    logic [FIFO_AW-1:0] rxf_th, txe_th;
    logic [1:0] ie, is;
    // ==== read regs ====
    logic [AXI_DW-1:0] rdata_reg;
    // -- reg 0 --
    assign rx_fifo_rd = regs_rd & raddr_reg == 4'd0;
    //assign s_axi_rdata = raddr_reg == 4'd0 ? rx_fifo_dout : rdata_reg;
    always_comb begin
        if(raddr_reg == 4'd0) begin
            case(RXD_REV_TYPE)
                1: s_axi_rdata = {<<RXD_GRP_SIZE{rx_fifo_dout}};
                2: s_axi_rdata = {<<RXD_GRP_SIZE{{<<{rx_fifo_dout}}}};
                default: s_axi_rdata = {{(AXI_DW-DW){rx_fifo_dout[DW-1]}},rx_fifo_dout};
            endcase
        end
        else begin
            s_axi_rdata = rdata_reg;
        end
    end
    // -- reg 1~9 --
    always_ff @(posedge clk) begin : proc_s_axi_rdata
        if(rst) begin
            rdata_reg <= 32'b0;
        end else begin
            case(raddr_reg)
                4'd1: rdata_reg <= rx_fifo_dcnt;
                4'd2: rdata_reg <= tx_fifo_dcnt;
                4'd3: rdata_reg <= rxf_th;
                4'd4: rdata_reg <= txe_th;
                4'd8: rdata_reg <= ie;
                4'd9: rdata_reg <= is;
            endcase // raddr_reg
        end
    end
    // ==== write regs ====
    assign tx_fifo_wr = regs_wr & waddr_reg == 4'd0;
    //assign tx_fifo_din = s_axi_wdata[DW-1:0];
    always_comb begin
        case(TXD_REV_TYPE)
            1: tx_fifo_din = {<<TXD_GRP_SIZE{s_axi_wdata[DW-1:0]}};
            2: tx_fifo_din = {<<TXD_GRP_SIZE{{<<{s_axi_wdata[DW-1:0]}}}};
            default: tx_fifo_din = s_axi_wdata[DW-1:0];
        endcase
    end
    assign rx_fifo_clr = regs_wr & waddr_reg == 4'd1;
    assign tx_fifo_clr = regs_wr & waddr_reg == 4'd2;
    always_ff @(posedge clk) begin : proc_rxf_th
        if(rst) begin
            rxf_th <= FIFO_AW'(1) << (FIFO_AW-1);
            txe_th <= FIFO_AW'(1) << (FIFO_AW-1);
            ie <= 2'b00;
        end else begin
            if(regs_wr) begin
                case(waddr_reg)
                    4'd3: rxf_th <= s_axi_wdata[FIFO_AW-1:0];
                    4'd4: txe_th <= s_axi_wdata[FIFO_AW-1:0];
                    4'd8: ie     <= s_axi_wdata[1:0];
                endcase // waddr_reg
            end
        end
    end

    // ==== interrupt ====
    assign is[0] = (rx_fifo_dcnt >= rxf_th) || full;
    assign is[1] = tx_fifo_dcnt <= txe_th;
    // assign intr = |(ie & is);
    always_ff @(posedge clk) begin : proc_intr
        if(rst) begin
            intr <= 1'b1;
        end else begin
            intr <= |(ie & is);
        end
    end

endmodule
