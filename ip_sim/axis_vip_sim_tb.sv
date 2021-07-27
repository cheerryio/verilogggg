`timescale 1ns/10ps

module axis_vip_sim_tb;
    import axi_vip_pkg::*;
    import axi4stream_vip_pkg::*;
    import axis_vip_sim_axi4stream_vip_0_0_pkg::*;
    import axis_vip_sim_axi4stream_vip_1_0_pkg::*;

    axis_vip_sim_axi4stream_vip_1_0_mst_t mst_agent;
    axis_vip_sim_axi4stream_vip_0_0_slv_t slv_agent;
    axi4stream_transaction wr_transaction,mst_monitor_transaction;
    axi4stream_transaction mst_monitor_transaction_queue[$];
    axi4stream_ready_gen ready_gen;

    bit aclk_0,aresetn_0;
    always #50 aclk_0=~aclk_0;
    initial begin
        aresetn_0=0;
        #100;
        aresetn_0=1;
    end
    axis_vip_sim_wrapper UUT(
        .aclk_0(aclk_0),.aresetn_0(aresetn_0)
    );
    initial begin
        mst_agent=new("mst agent",UUT.axis_vip_sim_i.axi4stream_vip_1.inst.IF);
        mst_agent.start_master();
        slv_agent=new("slv agent",UUT.axis_vip_sim_i.axi4stream_vip_0.inst.IF);
        slv_agent.start_slave();

        mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        mst_agent.set_agent_tag("master vip");
        slv_agent.set_agent_tag("slave vip");
        mst_agent.set_verbosity(0);
        slv_agent.set_verbosity(0);
        fork
            begin
                repeat(5)
                begin
                    wr_transaction=mst_agent.driver.create_transaction("new transaction");
                    //WR_TRANSACTION_FAIL:assert(wr_transaction.randomize());
                    wr_transaction.set_last(1'b1);
                    $display("set last=%d,isset=%d",wr_transaction.get_last(),C_XIL_AXI4STREAM_SIGNAL_SET[XIL_AXI4STREAM_SIGSET_POS_LAST]);
                    mst_agent.driver.send(wr_transaction); 
                end
            end
            begin
                #600;
                ready_gen=slv_agent.driver.create_ready("ready_gen");
                ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_OSC);
                ready_gen.set_low_time(2);
                ready_gen.set_high_time(3);
                slv_agent.driver.send_tready(ready_gen);
            end
        join
    end

    initial begin
        forever begin
            mst_agent.monitor.item_collected_port.get(mst_monitor_transaction);
            mst_monitor_transaction_queue.push_back(mst_monitor_transaction);
            $display("%p\n\n",mst_monitor_transaction);
        end
    end
    
    
endmodule