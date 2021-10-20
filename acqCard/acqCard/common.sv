/*
 * @Author: ZivFung 
 * @Email: JiaxiangFeng0612@outlook.com
 * @Date: 2020-02-06 23:14:13 
 * @Last Modified by: ZivFung
 * @Last Modified time: 2020-12-03 14:44:21
 */
`ifndef __COMMON_SV__
`define __COMMON_SV__

`define SIM_DETECT_X_VALUE
//`define ENABLE_FF_MODULE

package SimComp;

	task automatic ClkGen(
		ref logic clk, 
		input realtime period
	);
		clk = 1'b0;
		forever #(period/2) clk = ~clk;
	endtask

  parameter RSTGEN_TRIGLEVEL_HIGH = 1;
  parameter RSTGEN_TRIGLEVEL_LOW = 0;
	task automatic RstGen(
		ref logic rst, 
		ref logic clk,
		input realtime delay, 
		input int duration,
		input int trigLevel       //0: low. 1: high
	);
		if(trigLevel)rst = 1'b0;
		else rst = 1'b1;

		#delay;
		rst = ~rst;
		repeat(duration) @(posedge clk);
		rst = ~rst;
	endtask

  parameter EDGEGEN_EDGETYPE_RISE = 1;
  parameter EDGEGEN_EDGETYPE_FALL = 0;
	task automatic EdgeGen(
		ref logic clk,
		ref logic edgeSim,
		input int edgeType,		//0: fall, 1: rise
		input realtime delay
	);
		if(edgeType) edgeSim = 0;
		else edgeSim = 1;
		#delay;
		edgeSim = ~edgeSim;
	endtask

	task automatic SyncPulseGen(
		ref logic clk,
		ref logic pulse,
		input int pulseLevel,		//0: fall, 1: rise
		input int duration,
		input realtime delay
	);
		if(pulseLevel) pulse = 0;
		else pulse = 1;
		#delay;
		pulse = ~pulse;
		repeat(duration) @(posedge clk);
		pulse = ~pulse;
	endtask

	task automatic AsyncPulseGen(
		ref logic pulse,
		input int pulseLevel,		//0: fall, 1: rise
		input realtime duration,
		input realtime delay
	);
		if(pulseLevel) pulse = 0;
		else pulse = 1;
		#delay;
		pulse = ~pulse;
		#duration;
		pulse = ~pulse;
	endtask

endpackage

package Axi_pkg;
    typedef enum logic [1 : 0]{
        OKAY,
        EXOKAY,
        SLVERR,
        DECERR
    } axi_resp_t;

    typedef enum logic [3 : 0]{
        No_buff_cache_ralloc_walloc,        //0000
        No_cache_ralloc_walloc_with_buff,   //0001
        No_buff_ralloc_walloc_with_cache,   //0010
        No_ralloc_walloc_with_buff_cache,   //0011
        No_buff_cache_walloc_with_ralloc,   //0100
        No_cache_walloc_with_buff_ralloc,   //0101
        No_buff_walloc_with_cache_ralloc,   //0110
        No_walloc_with_buff_cache_ralloc,   //0111
        No_buff_cache_ralloc_with_walloc,   //1000
        No_cache_ralloc_with_buff_walloc,   //1001
        No_buff_ralloc_with_cache_walloc,   //1010
        No_ralloc_with_buff_cache_walloc,   //1011
        No_buff_cache_with_ralloc_walloc,   //1100
        No_cache_with_buff_ralloc_walloc,   //1101
        No_buff_with_cache_ralloc_walloc,   //1110
        With_buff_cache_ralloc_walloc       //1111
    } axi_cache_t;
    /*
            AXI Memory type
    ARCACHE[3:0]    AWCACHE[3:0]    Memory_type
        0000        0000            Device    Non-bufferable
        0001        0001            Device Bufferable
        0010        0010            Normal Non-cacheable Non-bufferable
        0011        0011            Normal Non-cacheable Bufferable
        1010        0110            Write-through No-allocate
        1110        (0110) 0110     Write-through Read-allocate
        1010        1110 (1010)     Write-through Write-allocate
        1110        1110            Write-through Read and Write-allocate
        1011        0111            Write-back No-allocate
        1111        (0111) 0111     Write-back Read-allocate
        1011        1111 (1011)     Write-back Write-allocate
        1111        1111            Write-back Read and Write-allocate
    */

    typedef enum logic [2 : 0]{
        Unpri_Secure_Data_Access,           //000
        Privi_Secure_Data_Access,           //001
        Unpri_NonSec_Data_Access,           //010
        Privi_NonSec_Data_Access,           //011
        Unpri_Secure_Inst_Access,           //100
        Privi_Secure_Inst_Access,           //101
        Unpri_NonSec_Inst_Access,           //110
        Privi_NonSec_Inst_Access            //111
    } axi_prot_t;

    typedef enum logic [1 : 0]{
        Normal_Access,                      //00
        Exclus_Access,                      //01
        Locked_Access,                      //10
        Axilock_Reserved                    //11
    } axi_lock_t;

    typedef enum logic [1 : 0]{
        FIXED,                              //00
        INCR,                               //01
        WRAP,                               //10
        Axiburst_Reserved                   //11
    } axi_burst_t;

endpackage

interface Axi4StreamIf
    import Axi_pkg::*;
#(
    parameter DW_BYTES = 4
)(
    input wire clk, reset_n
);
    localparam DW = DW_BYTES * 8;
    logic [DW - 1 : 0] tdata;
    logic tvalid = '0, tready, tlast;
    logic [DW_BYTES - 1 : 0] tstrb, tkeep;

    modport master(
        input   clk, reset_n, tready,
        output  tdata, tvalid, tlast, tstrb, tkeep
    );
    modport slave(
        input   clk, reset_n, tdata, tvalid, tlast,
                tstrb, tkeep,
        output  tready
    );
endinterface



interface Axi4LiteIf
    import Axi_pkg::*;
#( parameter AW = 32)(
    input wire clk, reset_n
);
    logic [AW - 1 : 0]      awaddr;
    axi_prot_t              awprot;
    logic                   awvalid = '0;
    logic                   awready;
    logic [31 : 0]          wdata;
    logic [3 : 0]           wstrb;
    logic                   wvalid = '0;
    logic                   wready;
    axi_resp_t              bresp;
    logic                   bvalid = '0;
    logic                   bready;
    logic [AW - 1 : 0]      araddr;
    axi_prot_t              arprot;
    logic                   arvalid = '0;
    logic                   arready;
    logic [31 : 0]          rdata;
    axi_resp_t              rresp;
    logic                   rvalid = '0;
    logic                   rready;
    modport master(
        input clk, reset_n,
        output awaddr, awprot, awvalid, input awready,
        output wdata, wstrb, wvalid, input wready,
        input bresp, bvalid, output bready,
        output araddr, arprot, arvalid, input arready,
        input rdata, rresp, rvalid, output rready
    );
    modport slave(
        input clk, reset_n,
        input awaddr, awprot, awvalid, output awready,
        input wdata, wstrb, wvalid, output wready,
        output bresp, bvalid, input bready,
        input araddr, arprot, arvalid, output arready,
        output rdata, rresp, rvalid, input rready
    );
endinterface

interface Axi4FullIf 
    import Axi_pkg::*;
#(
  parameter AW = 32, DW_BYTES = 4,
  parameter ID_W = 2, ARUSER_W = 8, AWUSER_W = 8, RUSER_W = 8, WUSER_W = 8, BUSER_W = 8
)(
  input wire clk, reset_n
);
    localparam DW = DW_BYTES * 8;
    /************Write*************/
    logic [ID_W - 1 : 0]            awid;
    logic [7 : 0]                   awlen;
    logic [2 : 0]                   awsize;
    axi_burst_t                     awburst;
    axi_cache_t                     awcache;
    axi_lock_t                      awlock;
    logic [3 : 0]                   awqos;
    logic [3 : 0]                   awregion;
    logic [ARUSER_W - 1 : 0]        awuser;
    logic [AW - 1 : 0]              awaddr;
    axi_prot_t                      awprot;
    
    logic [ID_W - 1 : 0]            wid;
    logic                           awvalid;
    logic                           awready;
    logic [WUSER_W - 1:0]           wuser;
    logic [DW_BYTES * 8 - 1 : 0]    wdata;
    logic [DW_BYTES - 1 : 0]        wstrb;
    logic                           wvalid;
    logic                           wready;
    logic                           wlast;
    /************Response*******    ******/
    logic [BUSER_W - 1 : 0]         buser;
    logic [ID_W - 1 : 0]            bid;
    axi_resp_t                      bresp;
    logic                           bvalid;
    logic                           bready;
    /************Read***********    **/
    logic [ID_W - 1 : 0]            arid;
    logic [AW - 1 : 0]              araddr;
    logic [7 : 0]                   arlen;
    logic [2 : 0]                   arsize;
    axi_burst_t                     arburst;
    logic [ARUSER_W - 1 : 0]        aruser;
    axi_cache_t                     arcache;
    axi_lock_t                      arlock;
    axi_prot_t                      arprot;
    logic [3 : 0]                   arqos;
    logic [3 : 0]                   arregion;
    logic                           arvalid;
    logic                           arready;
    
    logic [ID_W - 1 : 0]            rid;
    logic [RUSER_W - 1 : 0]         ruser;
    logic [DW_BYTES * 8 - 1 : 0]    rdata;
    axi_resp_t                      rresp;
    logic                           rvalid;
    logic                           rready;
    logic                           rlast;
    
    modport master(
        input clk, reset_n,
        
        output arid, araddr, arprot, arvalid, arlen, arsize, arburst, arcache, arlock, arqos,
               arregion, aruser, 
		input arready,
        
        input rid, rdata, rresp, rvalid, rlast, ruser,
		output rready,

        output awid, awaddr, awprot, awvalid, awlen, awsize, awburst, awcache, awlock, awqos,
               awregion, awuser, 
		input awready,
               
        output wuser, wdata, wstrb, wvalid, wid, wlast, 
		input wready,

        input buser, bid, bresp, bvalid, output bready
    );
	
    modport slave(
        input clk, reset_n,

        input awid, awaddr, awprot, awvalid, awlen, awsize, awburst, awcache, awlock, awqos,
               awregion, awuser,
		output awready,
        
        input wuser, wdata, wstrb, wvalid, wid, wlast, 
		output wready,

        output buser, bid, bresp, bvalid, input bready,

        input arid, araddr, arprot, arvalid, arlen, arsize, arburst, arcache, arlock, arqos,
               arregion, aruser, 
		output arready,

        output ruser, rid, rdata, rresp, rvalid, rlast, 
		input rready
    );

endinterface



`endif