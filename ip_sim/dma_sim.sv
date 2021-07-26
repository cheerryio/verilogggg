`timescale 1ns/10ps

module dma_sim_tb;
    import axi4stream_vip_pkg::*;
    import axi_vip_pkg::*;
    import dma_sim_axi4stream_vip_0_0_pkg::*;
    import dma_sim_axi_vip_0_0_pkg::*;
    import dma_sim_axi_vip_1_0_pkg::*;

    dma_sim_axi4stream_vip_0_0_mst_t axis_mst_agent;
    dma_sim_axi_vip_0_0_mst_t axi_mst_agent;
    dma_sim_axi_vip_1_0_slv_t axi_slv_agent;

    bit aclk_0,aresetn_0,s2mm_introut_0;
    always #50 aclk_0=~aclk_0;
    initial begin
        aresetn_0=0;
        #100;
        aresetn_0=1;
    end
    dma_sim_wrapper UUT(
        .aclk_0(aclk_0),.aresetn_0(aresetn_0),.s2mm_introut_0(s2mm_introut_0)
    );

    axi4stream_transaction wr_transaction; 
    axi_transaction wr_reactive;
    xil_axi_resp_t resp;
    bit [31:0] base_addr=32'h44a0_0000,offset_addr;
    bit [31:0] data;
    event configure_finish;
    initial begin
        axis_mst_agent=new("axis master vip agent",UUT.dma_sim_i.axi4stream_vip_0.inst.IF);
        axi_mst_agent=new("axi master vip agent",UUT.dma_sim_i.axi_vip_0.inst.IF);
        axi_slv_agent=new("axi slv vip agent",UUT.dma_sim_i.axi_vip_1.inst.IF);

        axis_mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axi_mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
        axi_slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);

        axis_mst_agent.set_agent_tag("AXIS MASTER VIP");
        axi_mst_agent.set_agent_tag("AXI MASTER VIP");
        axi_slv_agent.set_agent_tag("AXI SLV VIP");

        axis_mst_agent.set_verbosity(0);
        axi_mst_agent.set_verbosity(0);
        axi_slv_agent.set_verbosity(0);

        axis_mst_agent.start_master();
        axi_mst_agent.start_master();
        axi_slv_agent.start_slave();
        ->configure_finish;
    end

    initial begin
        @(configure_finish);
        $display("base configure finish");
        
        #1000;
        $display("gen axis transaction");
        $display("try start dma transaction");
        offset_addr=32'h30;
        data=32'h0000_0000_0000_0000_0010_1000_0000_0001;
        axi_mst_agent.AXI4LITE_WRITE_BURST(base_addr+offset_addr,0,data,resp);
        $display("configure dma RD and INTR resp:%d",resp);
        offset_addr=32'h34;
        data=32'h0;
        axi_mst_agent.AXI4LITE_WRITE_BURST(base_addr+offset_addr,0,data,resp);
        $display("configure dma deassert halted resp:%d",resp);
        ->configure_finish;
        // set destination address
        offset_addr=32'h48;
        data=32'h41e0_0000;
        axi_mst_agent.AXI4LITE_WRITE_BURST(base_addr+offset_addr,0,data,resp);
        $display("set dma destination address resp:%d",resp);
        // set write length
        offset_addr=32'h58;
        data=32'd64;
        axi_mst_agent.AXI4LITE_WRITE_BURST(base_addr+offset_addr,0,data,resp);
        $display("set write byte length resp:%d",resp);

        for(int i=0,trans_num=5;i<trans_num;i++) begin
            wr_transaction = axis_mst_agent.driver.create_transaction("Master VIP write transaction");
            wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
            wr_transaction.set_driver_return_item_policy(XIL_AXI4STREAM_AT_ACCEPT_RETURN );
            WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
            $display("wr_transaction data is:%d",wr_transaction);
            wr_transaction.set_data_beat(8'd5);
            wr_transaction.set_last(1);
            if(i==trans_num-1) begin
                wr_transaction.set_last(1);
            end
            axis_mst_agent.driver.send(wr_transaction);
        end
    end

    initial begin
        forever begin
            axi_slv_agent.wr_driver.get_wr_reactive(wr_reactive);
            wr_reactive.set_buser(1);
            wr_reactive.set_bresp(XIL_AXI_RESP_OKAY);
            axi_slv_agent.wr_driver.send(wr_reactive);
            $display("axi slv agent send ok back");
        end
    end

    axi_monitor_transaction slv_monitor_transaction;
    axi_monitor_transaction slave_moniter_transaction_queue[$];
    initial begin
        forever begin
          axi_slv_agent.monitor.item_collected_port.get(slv_monitor_transaction);
          slave_moniter_transaction_queue.push_back(slv_monitor_transaction);
          $display(slv_monitor_transaction);
          $display("get new packet");
        end
    end
endmodule