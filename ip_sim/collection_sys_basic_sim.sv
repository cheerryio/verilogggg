`timescale 1ns/10ps

package my_collection_sys_basic_sim_pkg;
    class item;
        rand bit [23:0] din;
        rand bit wr_en,rd_en;

        constraint c1 {wr_en==1 -> rd_en==0;}
        constraint c2 {rd_en==1 -> wr_en==0;}
    endclass
endpackage

module collection_sys_basic_sim_tb();
import my_collection_sys_basic_sim_pkg::*;
import axi_vip_pkg::*;
import basic_sim_axi_vip_0_0_pkg::*;

    bit aclk,aresetn;
    bit empty_i,empty_q,full_i,full_q;
    bit signed [31:0] freq;
    bit [23:0] din;
    bit [9:0] data_count_i,data_count_q;
    bit intr_i,intr_q;
    bit down_conversion_sys_en;

    bit in_en;
    bit [31:0] base_addr_i=32'h44a0_0000,base_addr_q=32'h44a1_0000,offset_addr;
    bit signed [31:0] data;
    bit signed [23:0] data_i,data_q;
    xil_axi_resp_t resp;
    bit signed [23:0] sin_in,cos_in;
    bit signed [31:0] freq_in;

    assign freq_in=2.0**32*22e3/10e6;
    orthDds #(32, 24, 13) theOrthDdsInst(aclk, aresetn, 1'b1, freq_in, 32'sd0,sin_in,cos_in);
    assign din=cos_in;
    assign freq=32'h0a00_0000;
    basic_sim_wrapper UUT(
        .aclk(aclk),.aresetn(aresetn),
        .empty_i(empty_i),.empty_q(empty_q),
        .full_i(full_i),.full_q(full_q),
        .freq(freq),
        .din(din),
        .data_count_i(data_count_i),.data_count_q(data_count_q),
        .intr_i(intr_i),.intr_q(intr_q),
        .down_conversion_sys_en(down_conversion_sys_en)
    );

    always #50 aclk=~aclk;
    initial begin
        aresetn=0;
        #100;
        aresetn=1;
    end
    counter #(20) cnt512000(aclk,aresetn,in_en,down_conversion_sys_en);

    item gen=new;
    bit [23:0] datas[$];   // golden data store
    basic_sim_axi_vip_0_0_mst_t master_agent;

    initial begin
        in_en=1;
        //UUT.<design name>_i.axi_vip_0.inst.IF.clr_xilinx_slave_ready_check();
        repeat(100) begin
            @(posedge aclk);
        end
        // XILINX_AWREADY_RESET: AWREADY must be low for the first clock edge that ARESETn goes high--PG101 XILINX_AWREADY_RESET
        master_agent=new("master vip agent",UUT.basic_sim_i.axi_vip_0.inst.IF);
        master_agent.start_master();
        //configure ip axi4l_fifo
        offset_addr=4*8;    // address of register ie
        data=2'b01;         // read intr enable, write intr disable
        master_agent.AXI4LITE_WRITE_BURST(base_addr_i+offset_addr,0,data,resp);
        master_agent.AXI4LITE_WRITE_BURST(base_addr_q+offset_addr,0,data,resp);
        offset_addr=3*8;
        data=10'd512;       // set rxf_th
        master_agent.AXI4LITE_WRITE_BURST(base_addr_i+offset_addr,0,data,resp);
        master_agent.AXI4LITE_WRITE_BURST(base_addr_q+offset_addr,0,data,resp);

        forever begin
            @(posedge aclk);
            if(intr_i==1'b1) begin
                in_en=1;
                repeat(512) begin
                    @(posedge aclk);
                    offset_addr=0;
                    master_agent.AXI4LITE_READ_BURST(base_addr_i+offset_addr,0,data_i,resp);
                    $display("data_i=%d",data_i);
                end
                in_en=1;
            end
            if(intr_q==1'b1) begin
                in_en=1;
                repeat(512) begin
                    @(posedge aclk);
                    offset_addr=0;
                    master_agent.AXI4LITE_READ_BURST(base_addr_q+offset_addr,0,data_q,resp);
                    $display("data_q=%d",data_q);
                end
                in_en=1;
            end
        end
    end
endmodule