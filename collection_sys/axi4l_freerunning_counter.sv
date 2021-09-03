module CounterMax #(
    parameter DW = 8
)(
    input wire clk, rst, en,
    input wire [DW - 1 : 0] max,
    output logic [DW - 1 : 0] cnt,
    output logic co
);
    assign co = en & (cnt == max);
    always_ff@(posedge clk) begin
        if(rst) cnt <= '0;
        else if(en) begin
            if(cnt < max) cnt <= cnt + 1'b1;
            else cnt <= '0;
        end
    end
endmodule

// reg num      rd                                      wr
//    0         counter value                           reset counter
//    1         pre divider of clk & clear intr         pre divider of clk

module Axi4lFreeRunningCounter #(
    parameter integer PRE_DIV = 999,
    localparam integer RAW = 1       // reg number = 2**RAW
)(
    input wire clk, rst_n,
    // --- s_axi ---
    (* mark_debug = "true" *) input   wire [RAW+1:0]  s_axi_awaddr,
    input   wire [2 : 0]    s_axi_awprot,
    (* mark_debug = "true" *) input   wire            s_axi_awvalid,
    (* mark_debug = "true" *) output  logic           s_axi_awready,
    (* mark_debug = "true" *) input   wire [31 : 0]   s_axi_wdata,
    input   wire [3 : 0]    s_axi_wstrb,
    (* mark_debug = "true" *) input   wire            s_axi_wvalid,
    (* mark_debug = "true" *) output  logic           s_axi_wready,
    output  logic [1 : 0]   s_axi_bresp,
    (* mark_debug = "true" *) output  logic           s_axi_bvalid,
    (* mark_debug = "true" *) input   wire            s_axi_bready,
    (* mark_debug = "true" *) input   wire [RAW+1:0]  s_axi_araddr,
    input   wire [2 : 0]    s_axi_arprot,
    (* mark_debug = "true" *) input   wire            s_axi_arvalid,
    (* mark_debug = "true" *) output  logic           s_axi_arready,
    (* mark_debug = "true" *) output  logic [31 : 0]  s_axi_rdata,
    output  logic [1 : 0]   s_axi_rresp,
    (* mark_debug = "true" *) output  logic           s_axi_rvalid,
    (* mark_debug = "true" *) input   wire            s_axi_rready,
    // --- interrupt ---
    (* mark_debug = "true" *) output logic intr
);
    wire rst = ~rst_n;
    (* mark_debug = "true" *) logic regs_wr, regs_rd;
    // ==== aw channel ====
    assign s_axi_awready = 1'b1;    // always ready
    (* mark_debug = "true" *) logic [RAW-1 : 0] waddr_reg;   // byte addr --> reg addr
    always_ff@(posedge clk) begin
        if(rst) waddr_reg <= '0;
        else if(s_axi_awvalid) waddr_reg <= s_axi_awaddr[2+:RAW];
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
    (* mark_debug = "true" *) logic [RAW-1 : 0] raddr_reg;
    always_ff@(posedge clk) begin
        if(rst) raddr_reg <= 1'b0;
        else if(s_axi_arvalid) raddr_reg <= s_axi_araddr[2+:RAW];
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

    // === user logic below ===
    // - drive s_axi_rdata by user regs/logic & raddr_reg @ regs_rd == 1
    // - drive user regs/logics by s_axi_wdata, s_axi_wstrb & waddr_reg @ regs_wr == 1
    // - drive intr and associated ie, is and etc if interrupts are need

    logic [31:0] prem;
    logic [31:0] cnt;
    wire pco;
    wire cnt_rst = rst | (regs_wr & (waddr_reg == 1'b0));

    CounterMax #(32) preCnt(clk, cnt_rst, 1'b1, prem, , pco);
    CounterMax #(32) theCnt(clk, cnt_rst, pco, 32'hffffffff, cnt, );

    always_ff@(posedge clk) begin : proc_prem
        if(rst) begin
            prem <= PRE_DIV;
        end
        else begin
            if(regs_wr && waddr_reg == 1'b1) begin
                prem <= s_axi_wdata;
            end
        end
    end

    always_ff@(posedge clk) begin : proc_s_axi_rdata
        if(rst) begin
            s_axi_rdata <= '0;
        end 
        else if(regs_rd) begin
            s_axi_rdata <= raddr_reg ? prem: cnt;
        end
    end

    always_ff@(posedge clk) begin : proc_intr
        if(rst) begin
            intr <= 1'b0;
        end 
        else if(pco) begin
            intr <= 1'b1;
        end
        else if(regs_rd & (raddr_reg == 1'b1))
            intr <= 1'b0;
    end

endmodule
