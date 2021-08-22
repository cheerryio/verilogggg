`timescale 1ns/10ps

module dual_fifo_sim_tb;
    import axi4stream_vip_pkg::*;
    import dual_fifo_sim_axi4stream_vip_0_0_pkg::*;
    import dual_fifo_sim_axi4stream_vip_1_0_pkg::*;

    dual_fifo_sim_axi4stream_vip_1_0_mst_t axis_mst_agent;
    dual_fifo_sim_axi4stream_vip_0_0_slv_t axis_slv_agent;

    bit clk;
    bit [31:0] axis_rd_data_count;
    bit prog_empty;
    bit resetn;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        resetn=1'b0;
        #100;
        resetn=1'b1;
    end

    event config_finish;
    initial begin
        axis_mst_agent=new("axis master vip agent",UUT.dual_fifo_sim_i.axi4stream_vip_1.inst.IF);
        axis_slv_agent=new("axis slave  vip agent",UUT.dual_fifo_sim_i.axi4stream_vip_0.inst.IF);
        axis_mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axis_slv_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axis_mst_agent.set_agent_tag("AXIS MASTER VIP");
        axis_slv_agent.set_agent_tag("AXIS SLAVE  VIP");
        axis_mst_agent.set_verbosity(0);
        axis_slv_agent.set_verbosity(0);
        axis_mst_agent.start_master();
        axis_slv_agent.start_slave();

        ->config_finish;
    end

    initial begin
        @(config_finish);
        $display("basic config finish");

        fork
        begin
            for(int i=0;i<768;i++) begin
                mst_gen_transaction();
            end  
            $display("Looped master to slave transfers example with randomization completes");
        end
        begin
            slv_gen_tready();
        end
        join_any
    end

    task slv_gen_tready();
        axi4stream_ready_gen ready_gen;
        ready_gen = axis_slv_agent.driver.create_ready("ready_gen");
        ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_SINGLE);
        ready_gen.set_low_time(100);
        ready_gen.set_high_time(1);
        axis_slv_agent.driver.send_tready(ready_gen);
    endtask

    task mst_gen_transaction();
        axi4stream_transaction wr_transaction; 
        wr_transaction=axis_mst_agent.driver.create_transaction("Master VIP write transaction");
        wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
        WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());
        axis_mst_agent.driver.send(wr_transaction);
    endtask

    axi4stream_monitor_transaction axis_mst_monitor_transaction;
    initial begin
        forever begin
            axis_mst_agent.monitor.item_collected_port.get(axis_mst_monitor_transaction);
        end
    end

    axi4stream_monitor_transaction axis_slv_monitor_transaction;
    initial begin
        forever begin
            axis_slv_agent.monitor.item_collected_port.get(axis_slv_monitor_transaction);
        end
    end

    dual_fifo_sim_wrapper UUT(
        .clk(clk),
        .axis_rd_data_count(axis_rd_data_count),
        .prog_empty(prog_empty),
        .resetn(resetn)
    );


endmodule