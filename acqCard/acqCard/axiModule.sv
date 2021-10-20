/*
 * @Author: ZivFung 
 * @Email: JiaxiangFeng0612@outlook.com
 * @Date: 2020-12-03 14:43:54 
 * @Last Modified by: ZivFung
 * @Last Modified time: 2020-12-04 20:43:06
 */
 
 `include "common.sv"
module axiFull_mem_v0
    import Axi_pkg::*;
#(
    parameter BASE_ADDR = 32'h8000_0000,
    parameter MEM_AW = 15
)(
    Axi4FullIf.slave s_axi_mem
);
	localparam integer ADDR_LSB = $clog2(s_axi_mem.DW/8);
	localparam integer OPT_MEM_ADDR_BITS = MEM_AW - 1;
    localparam BYTE_NUM = (s_axi_mem.DW/8);
    localparam MEM_DEPTH = 2 ** MEM_AW;
    logic [s_axi_mem.DW - 1 : 0]mem[MEM_DEPTH];

    logic aw_en;
    always_ff@(posedge s_axi_mem.clk) begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & s_axi_mem.wvalid & aw_en)begin
                s_axi_mem.awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if(s_axi_mem.bready & s_axi_mem.bvalid)begin
                aw_en <= 1'b1;
                s_axi_mem.awready <= 1'b0;
            end
            else begin
                s_axi_mem.awready <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0] awaddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            awaddr <= '0;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & aw_en)begin
                awaddr <= s_axi_mem.awaddr - BASE_ADDR;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.wready <= 1'b0;
        else begin
            if(~s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awvalid & aw_en)begin
                s_axi_mem.wready <= 1'b1;
            end
            else s_axi_mem.wready <= 1'b0;
        end
    end

    wire mem_wen = s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awready & s_axi_mem.awvalid;

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            mem <= '{MEM_DEPTH{'0}};
        end
        else begin
            if(mem_wen)begin
                for(int byte_idx = 0; byte_idx < BYTE_NUM; byte_idx++)begin
                    if(s_axi_mem.wstrb[byte_idx])begin
                        mem[awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]][(byte_idx*8) +: 8]
                                <= s_axi_mem.wdata[(byte_idx*8) +: 8];
                    end
                end
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.bvalid <= '0;
            s_axi_mem.bresp <= OKAY;
        end
        else begin
            if(s_axi_mem.awready & s_axi_mem.awvalid & ~s_axi_mem.bvalid & s_axi_mem.wready & s_axi_mem.wvalid)begin
                s_axi_mem.bvalid <= 1'b1;
                s_axi_mem.bresp <= OKAY;
            end
            else begin
                if(s_axi_mem.bready & s_axi_mem.bvalid)s_axi_mem.bvalid <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0]araddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.arready <= 1'b0;
            araddr <= '0;
        end
        else begin
            if(~s_axi_mem.arready & s_axi_mem.arvalid)begin
                s_axi_mem.arready <= 1'b1;
                araddr <= s_axi_mem.araddr - BASE_ADDR;
            end
            else begin
                s_axi_mem.arready <= 1'b0;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.rvalid <= '0;
            s_axi_mem.rresp <= OKAY;
        end
        else begin
            if(s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid)begin
                s_axi_mem.rvalid <= 1'b1;
                s_axi_mem.rresp <= OKAY;    //OKAY
            end
            else if(s_axi_mem.rvalid & s_axi_mem.rready) s_axi_mem.rvalid <= '0;
        end
    end

    wire mem_rden = s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid;
    // wire araddr = s_axi_mem.araddr - BASE_ADDR;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.rdata <='0;
        else begin
            if(mem_rden)begin
                s_axi_mem.rdata <= mem[araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]];
            end
        end
    end
endmodule

module axiFull_mem_v1
    import Axi_pkg::*;
#(
    parameter BASE_ADDR = 32'h8000_0000,
    parameter COE_FILE = "coe.dat",
    parameter MEM_AW = 15
)(
    Axi4FullIf.slave s_axi_mem
);
	localparam integer ADDR_LSB = $clog2(s_axi_mem.DW/8);
	localparam integer OPT_MEM_ADDR_BITS = MEM_AW - 1;
    localparam BYTE_NUM = (s_axi_mem.DW/8);
    localparam MEM_DEPTH = 2 ** MEM_AW;
    logic [s_axi_mem.DW - 1 : 0]mem[MEM_DEPTH];

    logic [7 : 0]mem_temp[MEM_DEPTH * BYTE_NUM];
    initial $readmemh(COE_FILE, mem_temp);

    initial begin
        for(int i = 0; i < MEM_DEPTH; i++)begin
            mem[i] = '0;
            for(int j = 0; j < BYTE_NUM; j++)begin
                mem[i] |= mem_temp[i * 8 + j] << (8 * j);
            end
        end    
    end

    logic aw_en;
    always_ff@(posedge s_axi_mem.clk) begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & s_axi_mem.wvalid & aw_en)begin
                s_axi_mem.awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if(s_axi_mem.bready & s_axi_mem.bvalid)begin
                aw_en <= 1'b1;
                s_axi_mem.awready <= 1'b0;
            end
            else begin
                s_axi_mem.awready <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0] awaddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            awaddr <= '0;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & aw_en)begin
                awaddr <= s_axi_mem.awaddr - BASE_ADDR;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.wready <= 1'b0;
        else begin
            if(~s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awvalid & aw_en)begin
                s_axi_mem.wready <= 1'b1;
            end
            else s_axi_mem.wready <= 1'b0;
        end
    end

    wire mem_wen = s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awready & s_axi_mem.awvalid;

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            // mem <= '{MEM_DEPTH{'0}};
        end
        else begin
            if(mem_wen)begin
                for(int byte_idx = 0; byte_idx < BYTE_NUM; byte_idx++)begin
                    if(s_axi_mem.wstrb[byte_idx])begin
                        mem[awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]][(byte_idx*8) +: 8]
                                <= s_axi_mem.wdata[(byte_idx*8) +: 8];
                    end
                end
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.bvalid <= '0;
            s_axi_mem.bresp <= OKAY;
        end
        else begin
            if(s_axi_mem.awready & s_axi_mem.awvalid & ~s_axi_mem.bvalid & s_axi_mem.wready & s_axi_mem.wvalid)begin
                s_axi_mem.bvalid <= 1'b1;
                s_axi_mem.bresp <= OKAY; //OKAY
            end
            else begin
                if(s_axi_mem.bready & s_axi_mem.bvalid)s_axi_mem.bvalid <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0]araddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.arready <= 1'b0;
            araddr <= '0;
        end
        else begin
            if(~s_axi_mem.arready & s_axi_mem.arvalid)begin
                s_axi_mem.arready <= 1'b1;
                araddr <= s_axi_mem.araddr - BASE_ADDR;
            end
            else begin
                s_axi_mem.arready <= 1'b0;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.rvalid <= '0;
            s_axi_mem.rresp <= OKAY;
        end
        else begin
            if(s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid)begin
                s_axi_mem.rvalid <= 1'b1;
                s_axi_mem.rresp <= OKAY;    //OKAY
            end
            else if(s_axi_mem.rvalid & s_axi_mem.rready) s_axi_mem.rvalid <= '0;
        end
    end

    wire mem_rden = s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid;
    // wire araddr = s_axi_mem.araddr - BASE_ADDR;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.rdata <='0;
        else begin
            if(mem_rden)begin
                s_axi_mem.rdata <= mem[araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]];
            end
        end
    end
endmodule


module axiLite_mem_v0
    import Axi_pkg::*;
#(
    parameter BASE_ADDR = 32'h8000_0000,
    parameter MEM_AW = 15
)(
    Axi4LiteIf.slave                                                s_axi_mem,
    output logic [2 ** MEM_AW - 1 : 0][s_axi_mem.DW - 1 : 0]        mem_data
);
	localparam integer ADDR_LSB = $clog2(s_axi_mem.DW/8);
	localparam integer OPT_MEM_ADDR_BITS = MEM_AW - 1;
    localparam BYTE_NUM = (s_axi_mem.DW/8);
    localparam MEM_DEPTH = 2 ** MEM_AW;
    logic [s_axi_mem.DW - 1 : 0]mem[MEM_DEPTH];

    logic aw_en;
    always_ff@(posedge s_axi_mem.clk) begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & s_axi_mem.wvalid & aw_en)begin
                s_axi_mem.awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if(s_axi_mem.bready & s_axi_mem.bvalid)begin
                aw_en <= 1'b1;
                s_axi_mem.awready <= 1'b0;
            end
            else begin
                s_axi_mem.awready <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0] awaddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            awaddr <= '0;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & aw_en)begin
                awaddr <= s_axi_mem.awaddr - BASE_ADDR;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.wready <= 1'b0;
        else begin
            if(~s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awvalid & aw_en)begin
                s_axi_mem.wready <= 1'b1;
            end
            else s_axi_mem.wready <= 1'b0;
        end
    end

    wire mem_wen = s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awready & s_axi_mem.awvalid;

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            mem <= '{MEM_DEPTH{'0}};
        end
        else begin
            if(mem_wen)begin
                for(int byte_idx = 0; byte_idx < BYTE_NUM; byte_idx++)begin
                    if(s_axi_mem.wstrb[byte_idx])begin
                        mem[awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]][(byte_idx*8) +: 8]
                                <= s_axi_mem.wdata[(byte_idx*8) +: 8];
                    end
                end
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.bvalid <= '0;
            s_axi_mem.bresp <= OKAY;
        end
        else begin
            if(s_axi_mem.awready & s_axi_mem.awvalid & ~s_axi_mem.bvalid & s_axi_mem.wready & s_axi_mem.wvalid)begin
                s_axi_mem.bvalid <= 1'b1;
                s_axi_mem.bresp <= OKAY;
            end
            else begin
                if(s_axi_mem.bready & s_axi_mem.bvalid)s_axi_mem.bvalid <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0]araddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.arready <= 1'b0;
            araddr <= '0;
        end
        else begin
            if(~s_axi_mem.arready & s_axi_mem.arvalid)begin
                s_axi_mem.arready <= 1'b1;
                araddr <= s_axi_mem.araddr - BASE_ADDR;
            end
            else begin
                s_axi_mem.arready <= 1'b0;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.rvalid <= '0;
            s_axi_mem.rresp <= OKAY;
        end
        else begin
            if(s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid)begin
                s_axi_mem.rvalid <= 1'b1;
                s_axi_mem.rresp <= OKAY;    //OKAY
            end
            else if(s_axi_mem.rvalid & s_axi_mem.rready) s_axi_mem.rvalid <= '0;
        end
    end

    wire mem_rden = s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid;
    // wire araddr = s_axi_mem.araddr - BASE_ADDR;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.rdata <='0;
        else begin
            if(mem_rden)begin
                s_axi_mem.rdata <= mem[araddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB]];
            end
        end
    end

    always_comb begin
        for(int i = 0; i < MEM_DEPTH; i++)begin
            mem_data[i] = mem[i];
        end
    end
endmodule


module axiLite_mem_v1                                               //using lowest register as periph state reg
    import Axi_pkg::*;
#(
    parameter BASE_ADDR = 32'h8000_0000,
    parameter MEM_AW = 15,// $clog2(ST_REG_NUM) + ACQ_CARD_REG_NUM_W
    parameter ST_REG_NUM = 2
)(
    Axi4LiteIf.slave                                                            s_axi_mem,
    input  wire  [ST_REG_NUM - 1 : 0][31 : 0]                                   stateIn,
    output logic [2 ** MEM_AW - 1 - ST_REG_NUM : 0][31 : 0]                     mem_data
);
	localparam integer ADDR_LSB = $clog2(4);
	localparam integer OPT_MEM_ADDR_BITS = MEM_AW - 1;
    localparam BYTE_NUM = (4);
    localparam MEM_DEPTH = 2 ** MEM_AW;
    logic [31 : 0]mem[MEM_DEPTH];

    logic aw_en;
    always_ff@(posedge s_axi_mem.clk) begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & s_axi_mem.wvalid & aw_en)begin
                s_axi_mem.awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if(s_axi_mem.bready & s_axi_mem.bvalid)begin
                aw_en <= 1'b1;
                s_axi_mem.awready <= 1'b0;
            end
            else begin
                s_axi_mem.awready <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0] awaddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            awaddr <= '0;
        end
        else begin
            if(~s_axi_mem.awready & s_axi_mem.awvalid & aw_en)begin
                awaddr <= s_axi_mem.awaddr - BASE_ADDR;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.wready <= 1'b0;
        else begin
            if(~s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awvalid & aw_en)begin
                s_axi_mem.wready <= 1'b1;
            end
            else s_axi_mem.wready <= 1'b0;
        end
    end

    wire mem_wen = s_axi_mem.wready & s_axi_mem.wvalid & s_axi_mem.awready & s_axi_mem.awvalid;

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            mem <= '{MEM_DEPTH{'0}};
        end
        else begin
            if(mem_wen & (awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= ST_REG_NUM))begin        //& (awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= ST_REG_NUM)
                for(int byte_idx = 0; byte_idx < BYTE_NUM; byte_idx++)begin
                    if(s_axi_mem.wstrb[byte_idx])begin
                        mem[awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]][(byte_idx*8) +: 8]
                                <= s_axi_mem.wdata[(byte_idx*8) +: 8];
                    end
                end
            end
            for(int i = 0; i < ST_REG_NUM; i++)begin
                mem[i] <= stateIn[i];
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.bvalid <= '0;
            s_axi_mem.bresp <= OKAY;
        end
        else begin
            if(s_axi_mem.awready & s_axi_mem.awvalid & ~s_axi_mem.bvalid & s_axi_mem.wready & s_axi_mem.wvalid)begin
                s_axi_mem.bvalid <= 1'b1;
                s_axi_mem.bresp <= OKAY;
            end
            else begin
                if(s_axi_mem.bready & s_axi_mem.bvalid)s_axi_mem.bvalid <= 1'b0;
            end
        end
    end

    logic [s_axi_mem.AW - 1 : 0]araddr;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.arready <= 1'b0;
            araddr <= '0;
        end
        else begin
            if(~s_axi_mem.arready & s_axi_mem.arvalid)begin
                s_axi_mem.arready <= 1'b1;
                araddr <= s_axi_mem.araddr - BASE_ADDR;
            end
            else begin
                s_axi_mem.arready <= 1'b0;
            end
        end
    end

    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n)begin
            s_axi_mem.rvalid <= '0;
            s_axi_mem.rresp <= OKAY;
        end
        else begin
            if(s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid)begin
                s_axi_mem.rvalid <= 1'b1;
                s_axi_mem.rresp <= OKAY;    //OKAY
            end
            else if(s_axi_mem.rvalid & s_axi_mem.rready) s_axi_mem.rvalid <= '0;
        end
    end

    wire mem_rden = s_axi_mem.arready & s_axi_mem.arvalid & ~s_axi_mem.rvalid;
    // wire araddr = s_axi_mem.araddr - BASE_ADDR;
    always_ff@(posedge s_axi_mem.clk)begin
        if(~s_axi_mem.reset_n) s_axi_mem.rdata <='0;
        else begin
            if(mem_rden)begin
                s_axi_mem.rdata <= mem[araddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB]];
            end
        end
    end

    always_comb begin
        for(int i = 0; i < MEM_DEPTH - ST_REG_NUM; i++)begin
            mem_data[i] = mem[i + ST_REG_NUM];
        end
    end

endmodule

//module fifo2AxiFullSlave                //Only support read operation 
//	import Axi_pkg::*;
//#(
//    parameter BASE_ADDR = 32'h8000_0000,
//	parameter FIFO_DW = 32,
//	parameter FIFO_NUMS = 25,
//	parameter type dtype = logic [FIFO_DW - 1 : 0]
//)(
//	Axi4FullIf.slave        									s_axi_fifo,

//	input  dtype [FIFO_NUMS - 1 : 0]			                fifoDin,
//	input  wire  [FIFO_NUMS - 1 : 0]							fifoDinValid,
//	output logic [FIFO_NUMS - 1 : 0]							fifoDinReady
//);
//    localparam MAPPED_BYTE_NUM_PERFIFO = s_axi_fifo.DW / 8;
//    localparam ADDR_LSB = $clog2(MAPPED_BYTE_NUM_PERFIFO);
//    localparam MAPPED_FIFO_NUM = 2 ** $clog2(FIFO_NUMS);
//    localparam OPT_MEM_ADDR_BITS = $clog2(FIFO_NUMS) - 1;

//	logic axi_arshaked, axi_rshaked, axi_awshaked, axi_wshaked, axi_bshaked;

//	always_comb begin
//		axi_arshaked 	= s_axi_fifo.arvalid & s_axi_fifo.arready;
//		axi_rshaked		= s_axi_fifo.rvalid & s_axi_fifo.rready;
//		axi_awshaked 	= s_axi_fifo.awvalid & s_axi_fifo.awready;
//		axi_wshaked		= s_axi_fifo.wvalid & s_axi_fifo.wready;
//		axi_bshaked		= s_axi_fifo.bvalid & s_axi_fifo.bready;
//	end

//    always_comb begin
//        s_axi_fifo.wready = 1'b1;
//        s_axi_fifo.bresp = OKAY;
//    end


//    /***************************************** Axi Write response *********************************/
//    always_ff@(posedge s_axi_fifo.clk)begin
//        if(~s_axi_fifo.reset_n)begin
//            s_axi_fifo.awready <= 1'b1;
//        end
//        else begin
//            if(axi_awshaked)begin
//                s_axi_fifo.awready <= 1'b0;
//            end
//            else if(axi_bshaked)begin
//                s_axi_fifo.awready <= 1'b1;
//            end
//        end
//    end

//    always_ff@(posedge s_axi_fifo.clk) begin
//        if(~s_axi_fifo.reset_n)begin
//            s_axi_fifo.bvalid <= 1'b0;
//        end
//        else begin
//            if(axi_wshaked & s_axi_fifo.wlast)begin
//                s_axi_fifo.bvalid <= 1'b1;
//            end
//            else if(axi_bshaked)begin
//                s_axi_fifo.bvalid <= 1'b0;
//            end
//        end
//    end

//    /***************************************** Axi Read FIFO *********************************/
//    logic [7 : 0]                       axi_arlen, axi_arlenCnt;
//    logic [s_axi_fifo.ID_W - 1 : 0]     axi_arid;
//    axi_lock_t                          axi_arlock;
//    logic [2 : 0]                       axi_arsize;
//    axi_burst_t                         axi_arburst;
//    logic [s_axi_fifo.AW - 1 : 0]       axi_araddr;
//    logic                               axi_reading;
//    logic [ADDR_LSB + 5 : 0]            axi_rWrap_size; // max is MAPPED_BYTE_NUM_PERFIFO * 16
//    logic                               axi_rWrap_en;
//    always_ff@(posedge s_axi_fifo.clk)begin
//        if(~s_axi_fifo.reset_n)begin
//            axi_reading <= '0;
//        end
//        else begin
//            if(~axi_reading & axi_arshaked) axi_reading <= 1'b1;
//            else if(axi_reading & axi_rshaked & s_axi_fifo.rlast) axi_reading <= 1'b0;
//        end
//    end

//    always_ff@(posedge s_axi_fifo.clk)begin
//        if(~s_axi_fifo.reset_n)begin
//            axi_arlen <= '0;
//            axi_arsize <= '0;
//            axi_arburst <= FIXED;
//            axi_arid <= '0;
//            axi_arlock <= Normal_Access;
//        end
//        else begin
//            if(axi_arshaked)begin
//                axi_arlen <= s_axi_fifo.arlen;
//                axi_arsize <= s_axi_fifo.arsize;
//                axi_arburst <= s_axi_fifo.arburst;
//                axi_arid <= s_axi_fifo.arid;
//                axi_arlock <= s_axi_fifo.arlock;
//            end
//        end
//    end

//    always_comb begin : Axi_Burst_Wrap_Addr_Cal_Proc
//        axi_rWrap_size = MAPPED_BYTE_NUM_PERFIFO * axi_arlen;
//        axi_rWrap_en = ((axi_araddr & (s_axi_fifo.AW)'(axi_rWrap_size)) ^ (s_axi_fifo.AW)'(axi_rWrap_size)) == 0;
//    end

//    always_ff@(posedge s_axi_fifo.clk)begin
//        if(~s_axi_fifo.reset_n)begin
//            axi_araddr <= '0;
//            axi_arlenCnt <= '0;
//        end
//        else begin
//            if(axi_arshaked)begin
//                axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= s_axi_fifo.araddr[s_axi_fifo.AW - 1 : ADDR_LSB] - (BASE_ADDR >> ADDR_LSB);
//                axi_araddr[ADDR_LSB - 1 : 0] <= '0;
//                axi_arlenCnt <= '0;
//            end
//            else if(axi_reading & (axi_arlenCnt <= axi_arlen) & axi_rshaked)begin
//                axi_arlenCnt <= axi_arlenCnt + 1;
//                case(axi_arburst)
//                    FIXED:begin
//                        axi_araddr <= axi_araddr;
//                    end
//                    INCR:begin
//                        axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
//                        axi_araddr[ADDR_LSB - 1 : 0] <= '0;
//                    end
//                    WRAP:begin
//                        if(axi_rWrap_en)begin
//                            axi_araddr <= axi_araddr - (s_axi_fifo.AW)'(axi_rWrap_size);
//                        end
//                        else begin
//                            axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
//                            axi_araddr[ADDR_LSB - 1 : 0] <= '0;
//                        end
//                    end
//                    default:begin
//                        axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB];
//                        axi_araddr[ADDR_LSB - 1 : 0] <= '0;
//                    end
//                endcase
//            end
//        end
//    end

//    always_comb begin
//        s_axi_fifo.arready = ~axi_reading;
//        s_axi_fifo.rlast = (axi_arlenCnt == axi_arlen) & s_axi_fifo.rvalid;
//    end

//    always_comb begin
//        s_axi_fifo.rdata = '0;
//        s_axi_fifo.rvalid = axi_reading;                   //in case wrong addr
//        fifoDinReady = '0;
//        s_axi_fifo.rresp = OKAY;
//        s_axi_fifo.rid = axi_arid;
//        for(int i = 0; i < FIFO_NUMS; i++)begin
//            if(axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] == i)begin
//                s_axi_fifo.rdata[FIFO_DW - 1 : 0] = fifoDin[i];
//                s_axi_fifo.rvalid = fifoDinValid[i] & axi_reading;
//                fifoDinReady[i] = axi_rshaked;
//                s_axi_fifo.rresp = (axi_arlock == Exclus_Access)? EXOKAY : OKAY;
//            end
//            else if(axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] > i)begin
//                s_axi_fifo.rvalid = axi_reading;
//                s_axi_fifo.rresp = SLVERR;
//                fifoDinReady[i] = 1'b0;
//            end
//        end
//    end
//endmodule



module fifo2AxiFullSlave
	import Axi_pkg::*;
#(
    parameter BASE_ADDR = 32'h8000_0000,
	parameter FIFO_DW = 32,
	parameter READ_FIFO_NUMS = 25,
    parameter WRITE_FIFO_NUMS = 25,
	parameter type dtype = logic [FIFO_DW - 1 : 0]
)(
	Axi4FullIf.slave        									    s_axi_fifo,

	input  dtype [READ_FIFO_NUMS - 1 : 0]			                fifoDin,
	input  wire  [READ_FIFO_NUMS - 1 : 0]							fifoDinValid,
	output logic [READ_FIFO_NUMS - 1 : 0]							fifoDinReady,

	output dtype [WRITE_FIFO_NUMS - 1 : 0]			                fifoDout,
	output logic [WRITE_FIFO_NUMS - 1 : 0]							fifoDoutValid,
	input  wire  [WRITE_FIFO_NUMS - 1 : 0]							fifoDoutReady
);
    localparam MAPPED_BYTE_NUM_PERFIFO = s_axi_fifo.DW / 8;
    localparam ADDR_LSB = $clog2(MAPPED_BYTE_NUM_PERFIFO);
    localparam FIFO_NUMS = READ_FIFO_NUMS + WRITE_FIFO_NUMS;
    localparam MAPPED_FIFO_NUM = 2 ** $clog2(FIFO_NUMS);
    localparam OPT_MEM_ADDR_BITS = $clog2(READ_FIFO_NUMS) - 1;

	logic axi_arshaked, axi_rshaked, axi_awshaked, axi_wshaked, axi_bshaked;

	always_comb begin
		axi_arshaked 	= s_axi_fifo.arvalid & s_axi_fifo.arready;
		axi_rshaked		= s_axi_fifo.rvalid & s_axi_fifo.rready;
		axi_awshaked 	= s_axi_fifo.awvalid & s_axi_fifo.awready;
		axi_wshaked		= s_axi_fifo.wvalid & s_axi_fifo.wready;
		axi_bshaked		= s_axi_fifo.bvalid & s_axi_fifo.bready;
	end



    /***************************************** Axi Read FIFO *********************************/
    logic [7 : 0]                       axi_arlen, axi_arlenCnt;
    logic [s_axi_fifo.ID_W - 1 : 0]     axi_arid;
    axi_lock_t                          axi_arlock;
    logic [2 : 0]                       axi_arsize;
    axi_burst_t                         axi_arburst;
    logic [s_axi_fifo.AW - 1 : 0]       axi_araddr;
    logic                               axi_reading;
    logic [ADDR_LSB + 5 : 0]            axi_rWrap_size; // max is MAPPED_BYTE_NUM_PERFIFO * 16
    logic                               axi_rWrap_en;
    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_reading <= '0;
        end
        else begin
            if(~axi_reading & axi_arshaked) axi_reading <= 1'b1;
            else if(axi_reading & axi_rshaked & s_axi_fifo.rlast) axi_reading <= 1'b0;
        end
    end

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_arlen   <= '0;
            axi_arsize  <= '0;
            axi_arburst <= FIXED;
            axi_arid    <= '0;
            axi_arlock  <= Normal_Access;
        end
        else begin
            if(axi_arshaked)begin
                axi_arlen   <= s_axi_fifo.arlen;
                axi_arsize  <= s_axi_fifo.arsize;
                axi_arburst <= s_axi_fifo.arburst;
                axi_arid    <= s_axi_fifo.arid;
                axi_arlock  <= s_axi_fifo.arlock;
            end
        end
    end

    always_comb begin : Axi_Rd_Burst_Wrap_Addr_Cal_Proc
        axi_rWrap_size = MAPPED_BYTE_NUM_PERFIFO * axi_arlen;
        axi_rWrap_en = ((axi_araddr & (s_axi_fifo.AW)'(axi_rWrap_size)) ^ (s_axi_fifo.AW)'(axi_rWrap_size)) == 0;
    end

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_araddr <= '0;
            axi_arlenCnt <= '0;
        end
        else begin
            if(axi_arshaked)begin
                axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= s_axi_fifo.araddr[s_axi_fifo.AW - 1 : ADDR_LSB] - (BASE_ADDR >> ADDR_LSB);
                axi_araddr[ADDR_LSB - 1 : 0] <= '0;
                axi_arlenCnt <= '0;
            end
            else if(axi_reading & (axi_arlenCnt <= axi_arlen) & axi_rshaked)begin
                axi_arlenCnt <= axi_arlenCnt + 1;
                case(axi_arburst)
                    FIXED:begin
                        axi_araddr <= axi_araddr;
                    end
                    INCR:begin
                        axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
                        axi_araddr[ADDR_LSB - 1 : 0] <= '0;
                    end
                    WRAP:begin
                        if(axi_rWrap_en)begin
                            axi_araddr <= axi_araddr - (s_axi_fifo.AW)'(axi_rWrap_size);
                        end
                        else begin
                            axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
                            axi_araddr[ADDR_LSB - 1 : 0] <= '0;
                        end
                    end
                    default:begin
                        axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB];
                        axi_araddr[ADDR_LSB - 1 : 0] <= '0;
                    end
                endcase
            end
        end
    end

    always_comb begin
        s_axi_fifo.arready = ~axi_reading;
        s_axi_fifo.rlast = (axi_arlenCnt == axi_arlen) & s_axi_fifo.rvalid;
    end

    always_comb begin
        s_axi_fifo.rdata = '0;
        s_axi_fifo.rvalid = axi_reading;                   //in case wrong addr
        fifoDinReady = '0;
        // s_axi_fifo.rresp = OKAY;
        s_axi_fifo.rresp = (axi_arlock == Exclus_Access)? EXOKAY : OKAY;
        s_axi_fifo.rid = axi_arid;
        for(int i = 0; i < READ_FIFO_NUMS; i++)begin
            if(axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] == i)begin
                s_axi_fifo.rdata[FIFO_DW - 1 : 0] = fifoDin[i];
                s_axi_fifo.rvalid = fifoDinValid[i] & axi_reading;
                fifoDinReady[i] = axi_rshaked;
                
            end
            else if(axi_araddr[s_axi_fifo.AW - 1 : ADDR_LSB] > i)begin
                s_axi_fifo.rvalid = axi_reading;
                s_axi_fifo.rdata = '0;
                // s_axi_fifo.rresp = SLVERR;
                fifoDinReady[i] = 1'b0;
            end
        end
    end


    /***************************************** Axi Write FIFO *********************************/
    logic [7 : 0]                       axi_awlen;
    logic [s_axi_fifo.ID_W - 1 : 0]     axi_awid;
    axi_lock_t                          axi_awlock;
    logic [2 : 0]                       axi_awsize;
    axi_burst_t                         axi_awburst;
    logic                               axi_writing;
    logic [s_axi_fifo.AW - 1 : 0]       axi_awaddr;
    logic [ADDR_LSB + 5 : 0]            axi_wWrap_size; // max is MAPPED_BYTE_NUM_PERFIFO * 16
    logic                               axi_wWrap_en;

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_writing <= '0;
        end
        else begin
            if(~axi_writing & axi_awshaked) axi_writing <= 1'b1;
            else if(axi_writing & axi_wshaked & s_axi_fifo.wlast) axi_writing <= 1'b0;
        end
    end

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_awlen   <= '0;
            axi_awsize  <= '0;
            axi_awburst <= FIXED;
            axi_awid    <= '0;
            axi_awlock  <= Normal_Access;
        end
        else begin
            if(axi_awshaked)begin
                axi_awlen   <= s_axi_fifo.awlen;
                axi_awsize  <= s_axi_fifo.awsize;
                axi_awburst <= s_axi_fifo.awburst;
                axi_awid    <= s_axi_fifo.awid;
                axi_awlock  <= s_axi_fifo.awlock;
            end
        end
    end

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            s_axi_fifo.awready <= 1'b1;
        end
        else begin
            if(axi_awshaked)begin
                s_axi_fifo.awready <= 1'b0;
            end
            else if(axi_bshaked)begin
                s_axi_fifo.awready <= 1'b1;
            end
        end
    end

    always_ff@(posedge s_axi_fifo.clk) begin
        if(~s_axi_fifo.reset_n)begin
            s_axi_fifo.bvalid <= 1'b0;
        end
        else begin
            if(axi_wshaked & s_axi_fifo.wlast)begin
                s_axi_fifo.bvalid <= 1'b1;
            end
            else if(axi_bshaked)begin
                s_axi_fifo.bvalid <= 1'b0;
            end
        end
    end

    always_comb begin : Axi_Wr_Burst_Wrap_Addr_Cal_Proc
        axi_wWrap_size = MAPPED_BYTE_NUM_PERFIFO * axi_awlen;
        axi_wWrap_en = ((axi_awaddr & (s_axi_fifo.AW)'(axi_wWrap_size)) ^ (s_axi_fifo.AW)'(axi_wWrap_size)) == 0;
    end

    always_ff@(posedge s_axi_fifo.clk)begin
        if(~s_axi_fifo.reset_n)begin
            axi_awaddr <= '0;
        end
        else begin
            if(axi_awshaked)begin
                axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= s_axi_fifo.awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] - (BASE_ADDR >> ADDR_LSB);
                axi_awaddr[ADDR_LSB - 1 : 0] <= '0;
            end
            else if(axi_writing & axi_wshaked)begin
                case(axi_awburst)
                    FIXED:begin
                        axi_awaddr <= axi_awaddr;
                    end
                    INCR:begin
                        axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
                        axi_awaddr[ADDR_LSB - 1 : 0] <= '0;
                    end
                    WRAP:begin
                        if(axi_wWrap_en)begin
                            axi_awaddr <= axi_awaddr - (s_axi_fifo.AW)'(axi_wWrap_size);
                        end
                        else begin
                            axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] + 1;
                            axi_awaddr[ADDR_LSB - 1 : 0] <= '0;
                        end
                    end
                    default:begin
                        axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] <= axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB];
                        axi_awaddr[ADDR_LSB - 1 : 0] <= '0;
                    end
                endcase
            end
        end
    end

    always_comb begin
        s_axi_fifo.wready = axi_writing;                   //in case wrong addr
        fifoDoutValid = '0;
        s_axi_fifo.bresp = (axi_awlock == Exclus_Access)? EXOKAY : OKAY;
        s_axi_fifo.bid = axi_awid;
        fifoDout = '0;
        for(int i = 0; i < WRITE_FIFO_NUMS; i++)begin
            if(axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] == i + READ_FIFO_NUMS)begin
                fifoDout[i] = s_axi_fifo.wdata[FIFO_DW - 1 : 0];
                s_axi_fifo.wready = fifoDoutReady[i] & axi_writing;
                fifoDoutValid[i] = axi_wshaked;
            end
            else if(
                (axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] > (i + FIFO_NUMS))     | 
                (axi_awaddr[s_axi_fifo.AW - 1 : ADDR_LSB] < READ_FIFO_NUMS)
            )begin
                s_axi_fifo.wready = axi_writing;
                fifoDoutValid[i] = 1'b0;
                fifoDout[i] = '0;
            end
        end
    end
endmodule