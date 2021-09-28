`timescale 1ns/10ps

module axis_mm2s_sim_tb();
    import axi4stream_vip_pkg::*;
    import axis_mm2s_sim_axi4stream_vip_0_0_pkg::*;
    axis_mm2s_sim_axi4stream_vip_0_0_mst_t axis_mst_agent;

    localparam integer DATA_BASEADDR=32'h43c1_0000;

    bit aclk,aresetn;
    wire temp_aclk,temp_aresetn;

    always #5 aclk=~aclk;
    assign temp_aclk=aclk;
    assign temp_aresetn=aresetn;

    event config_finish;

    initial begin
        automatic bit resp;
        automatic bit [15:0] irq_status;
        axis_mst_agent=new("axis master vip agent",UUT.axis_mm2s_sim_i.axi4stream_vip_0.inst.IF);
        axis_mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axis_mst_agent.set_agent_tag("AXIS MASTER VIP");
        axis_mst_agent.set_verbosity(0);
        axis_mst_agent.start_master();

        aresetn = 1'b0;
        repeat(20)@(posedge aclk);        
        aresetn = 1'b1;
        @(posedge aclk);

        repeat(5) @(posedge aclk);
        axis_mm2s_sim_tb.UUT.axis_mm2s_sim_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        axis_mm2s_sim_tb.UUT.axis_mm2s_sim_i.processing_system7_0.inst.set_debug_level_info(1'b0);
        axis_mm2s_sim_tb.UUT.axis_mm2s_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        axis_mm2s_sim_tb.UUT.axis_mm2s_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        $display("PL reset complete...");

        ->config_finish;
    end

    initial begin
        @(config_finish);
        $display("basic config finish");
        begin
            for(int i=0;i<768;i++) begin
                mst_gen_transaction();
            end  
            $display("Looped master to slave transfers example with randomization completes");
        end
    end
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
    /*
     * simulate 
     */
    initial begin
        automatic bit resp;
        @(config_finish);
        fork
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                automatic bit [31:0] write_data;
                for(int i=0;i<50;i++) begin
                    axis_mm2s_sim_tb.UUT.axis_mm2s_sim_i.processing_system7_0.inst.read_data(DATA_BASEADDR,4,read_data,resp);
                    $display("data=%d",read_data);
                end
            end
        join
        // wait for data check finish
        repeat(5)@(posedge aclk);
        $finish;
    end

  axis_mm2s_sim_wrapper UUT
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