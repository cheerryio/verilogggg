
`timescale 1ns/10ps

import axi_vip_pkg::*;
import axi_fifo_if_sim_axi_vip_0_0_pkg::*;

module axi_fifo_if_tb();
    bit clk,rst_n;
    bit aux_rst_n;
    bit [23:0] data;
    bit valid;
    axi_fifo_if_sim_axi_vip_0_0_mst_t mst_agent;
    xil_axi_uint     mtestID;  
    xil_axi_ulong    mtestADDR;  
    xil_axi_len_t    mtestBurstLength;  
    xil_axi_size_t   mtestDataSize;   
    xil_axi_burst_t  mtestBurstType;   
    xil_axi_lock_t   mtestLOCK;  
    xil_axi_cache_t  mtestCacheType = 0;  
    xil_axi_prot_t   mtestProtectionType = 3'b000;  
    xil_axi_region_t mtestRegion = 4'b000;  
    xil_axi_qos_t    mtestQOS = 4'b000;
    xil_axi_data_beat         mtestARUSER = 0;
    xil_axi_resp_t[255:0]     mtestRresp;
    bit [32767:0]             mtestRDataF;
    xil_axi_data_beat [255:0] mtestRUSER;

    always #5 clk=~clk;
    initial begin
        repeat(20) @(posedge clk);
        rst_n=1'b1;
        aux_rst_n=1'b1;
        repeat(2000) @(posedge clk);
        aux_rst_n=1'b0;
        repeat(20) @(posedge clk);
        aux_rst_n=1'b1;
    end

    initial begin
        automatic bit resp;
        mtestID = 0; 
        mtestADDR = 0; 
        mtestBurstLength = 7;
        mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
        mtestBurstType = XIL_AXI_BURST_TYPE_INCR;
        mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
        mtestCacheType = 0;  
        mtestProtectionType = 0;  
        mtestRegion = 0; 
        mtestQOS = 0; 
        mst_agent=new("axi master vip agent",DUT.axi_fifo_if_sim_i.axi_vip_0.inst.IF);
        mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
        mst_agent.set_agent_tag("AXI MASTER VIP");
        mst_agent.set_verbosity(0);
        mst_agent.start_master();
    end

    initial begin
        repeat(300) @(posedge clk);
        mst_agent.AXI4_READ_BURST(
            mtestID, 
            mtestADDR,
            mtestBurstLength, 
            mtestDataSize, 
            mtestBurstType, 
            mtestLOCK, 
            mtestCacheType, 
            mtestProtectionType, 
            mtestRegion, 
            mtestQOS, 
            mtestARUSER, 
            mtestRDataF, 
            mtestRresp, 
            mtestRUSER 
        );
        $display("data is0x%x",mtestRDataF[8*32-1:0]);
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            valid<=1'b0;
        end
        else begin
            data<=data+1;
            valid<=1'b1; 
        end
    end

    axi_fifo_if_sim_wrapper DUT(
        .clk(clk),.rst_n(rst_n),.aux_rst_n(aux_rst_n),
        .data(data),.valid(valid)
    );

endmodule
