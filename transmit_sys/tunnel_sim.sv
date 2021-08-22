`timescale 1ns/10ps

module tunnel_sim_tb;
    import axi4stream_vip_pkg::*;
    import tunnel_sim_axi4stream_vip_0_0_pkg::*;

    localparam integer BRAM_BASE_ADDR = 32'h4000_0000;
    localparam integer DMA_BASE_ADDR  = 32'h4040_0000;

    tunnel_sim_axi4stream_vip_0_0_slv_t axis_slv_agent;

    bit aclk,aresetn;
    wire fclk0;
    wire temp_aclk,temp_aresetn;
    always #5 aclk=~aclk;
    assign temp_aclk=aclk;
    assign temp_aresetn=aresetn;

    bit [31:0] offset_addr,data;

    task slv_gen_tready();
        axi4stream_ready_gen ready_gen;
        ready_gen = axis_slv_agent.driver.create_ready("ready_gen");
        ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_SINGLE);
        ready_gen.set_low_time(100);
        ready_gen.set_high_time(1);
        axis_slv_agent.driver.send_tready(ready_gen);
    endtask

    initial begin
        axis_slv_agent=new("axis slave vip agent",UUT.tunnel_sim_i.axi4stream_vip_0.inst.IF);
        axis_slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axis_slv_agent.set_agent_tag("AXIS SLAVE  VIP");
        axis_slv_agent.set_verbosity(0);
        axis_slv_agent.start_slave();
        slv_gen_tready();
    end

    assign fclk0=tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0_FCLK_CLK0;

    initial begin
        automatic bit resp;
        automatic bit [15:0] irq_status;
        automatic bit [31:0] read_data;

        aresetn = 1'b0;
        repeat(20)@(posedge aclk);        
        aresetn = 1'b1;
        @(posedge aclk);

        repeat(5) @(posedge aclk);
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.set_debug_level_info(1'b0);
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        $display("PL reset complete...");

        for(int i=0;i<50;i++) begin
            repeat(150)@(posedge fclk0);
            tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.write_data(BRAM_BASE_ADDR+i*4,4,i,resp);
            tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.read_data(BRAM_BASE_ADDR+i*4,4,read_data,resp);
            $display("read write data:%d",i);
        end

        repeat(150)@(posedge fclk0);
        $display("try start dma transaction");
        $display("configure dma RD and INTR resp:%d",resp);
        offset_addr=32'h0;
        data=32'b0000_0000_0000_0000_0010_1000_0000_0001;
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.read_data(DMA_BASE_ADDR+offset_addr,4,read_data,resp);
        $display("MM2S_DMACR:%b",read_data);
        data=read_data|data;
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);

        $display("configure dma deassert halted resp:%d",resp);
        offset_addr=32'h4;
        data=~(32'h1);
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.read_data(DMA_BASE_ADDR+offset_addr,4,read_data,resp);
        $display("MM2S_DMASR:%b",read_data);
        data=read_data&data;
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);

        // set destination address
        $display("set dma destination address resp:%d",resp);
        offset_addr=32'h18;
        data=BRAM_BASE_ADDR;
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);

        // set write length
        $display("set write byte length resp:%d",resp);
        offset_addr=32'h28;
        data=32'd128;
        tunnel_sim_tb.UUT.tunnel_sim_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);
    end

  tunnel_sim_wrapper UUT
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
        .FIXED_IO_ps_srstb(temp_aresetn));
endmodule