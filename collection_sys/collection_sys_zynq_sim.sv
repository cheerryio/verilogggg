`timescale 1ns/10ps

package my_collection_sys_zynq_sim_pkg;
    class item;
        rand bit [23:0] din;
        rand bit wr_en,rd_en;

        constraint c1 {wr_en==1 -> rd_en==0;}
        constraint c2 {rd_en==1 -> wr_en==0;}
    endclass
endpackage

module collection_sys_zynq_sim_tb();
import my_collection_sys_zynq_sim_pkg::*;
    localparam integer FIFO_IRQ_THRESHOLD = 32'd512;
    localparam integer FIFO_BASE_ADDR  = 32'h43c0_0000;
    localparam integer FIFO_IRQ_ID  = 4'b0000;
    bit aclk,aresetn;
    wire temp_aclk,temp_aresetn;
    bit resp;
    bit empty_i,empty_q,full_i,full_q;
    bit signed [31:0] freq;
    bit [23:0] din;
    bit [9:0] data_count_i,data_count_q;
    bit intr_i,intr_q;
    bit down_conversion_sys_en;

    bit [31:0] offset_addr;
    bit signed [31:0] data;
    bit signed [23:0] sin_in,cos_in;
    bit signed [31:0] freq_in;
    bit signed [31:0] datai[$],dataq[$];

    always #5 aclk=~aclk;
    initial begin
        aresetn=1'b0;
        #100 aresetn=1'b1;
    end
    assign temp_aclk=aclk;
    assign temp_aresetn=aresetn;
    
    assign freq_in=2.0**32*22e3/10e6;
    orthDds #(32, 24, 13) theOrthDdsInst(
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0_FCLK_CLK0,
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0_FCLK_RESET0_N,
        1'b1, freq_in, 32'sd0,sin_in,cos_in
    );
    assign din=cos_in;
    item gen=new;

    basic_sim_wrapper UUT
    (.DDR_addr(),
    .DDR_ba(),
    .DDR_cas_n(),
    .DDR_ck_n(),
    .DDR_ck_p(),
    .DDR_cke(),
    .DDR_cs_n(),
    .DDR_dm(),
    .DDR_dq(),
    .DDR_dqs_n(),
    .DDR_dqs_p(),
    .DDR_odt(),
    .DDR_ras_n(),
    .DDR_reset_n(),
    .DDR_we_n(),
    .FIXED_IO_ddr_vrn(),
    .FIXED_IO_ddr_vrp(),
    .FIXED_IO_mio(),
    .FIXED_IO_ps_clk(temp_aclk),
    .FIXED_IO_ps_porb(temp_aresetn),
    .FIXED_IO_ps_srstb(temp_aresetn),
    .din(din),
    .freq(freq)
    );

    event config_finish;
    initial begin
        repeat(5) @(posedge aclk);
        // Initialize
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.set_debug_level_info(1'b1);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        // configure down_conversion_sys dds freq
        offset_addr=0;
        data=32'h0a00_0000;
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FREQ_GPIO_BASE_ADDR+offset_addr,4,data,resp);
        // configure ip axi4l_fifo
        offset_addr=4*8;
        data=2'b01;
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFOI_BASE_ADDR+offset_addr,4,data,resp);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFOQ_BASE_ADDR+offset_addr,4,data,resp);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);
        offset_addr=4*3;
        data=FIFO_IRQ_THRESHOLD;
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFOI_BASE_ADDR+offset_addr,4,data,resp);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFOQ_BASE_ADDR+offset_addr,4,data,resp);
        collection_sys_zynq_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);
        $display("config finish...");
        ->config_finish;
    end
    /*
     * simulate 
     */
    initial begin
        @(config_finish);
        fork
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                automatic bit resp;
                forever begin
                    collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.wait_interrupt(FIFOI_IRQ_ID,irq_status);
                    for(int i=0;i<FIFO_IRQ_THRESHOLD;i++) begin
                        collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.read_data(FIFOI_BASE_ADDR,4,read_data,resp);
                        datai.push_back(read_data);
                    end
                    $display("finish collecting data i...");
                end
            end
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                automatic bit resp;
                forever begin
                    collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.wait_interrupt(FIFOQ_IRQ_ID,irq_status);
                    for(int i=0;i<FIFO_IRQ_THRESHOLD;i++) begin
                        collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.read_data(FIFOQ_BASE_ADDR,4,read_data,resp);
                        dataq.push_back(read_data);
                    end
                    $display("finish collecting data q...");
                end
            end
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                automatic bit resp;
                forever begin
                    collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.wait_interrupt(FIFO_IRQ_ID,irq_status);
                    for(int i=0;i<FIFO_IRQ_THRESHOLD;i++) begin
                        collection_sys_basic_sim_tb.UUT.basic_sim_i.processing_system7_0.inst.read_data(FIFO_BASE_ADDR,4,read_data,resp);
                        dataq.push_back(read_data);
                    end
                    $display("finish collecting data main...");
                end
            end
        join
    end
endmodule