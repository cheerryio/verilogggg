`timescale 1ns/1ns

interface AD5543_sim_if #(
    parameter integer DW = 16
);
    logic s_axis_aclk,s_axis_aresetn;
    logic fclk,freset_n;
    logic en;
    logic s_axis_tvalid;
    logic s_axis_tready;
    logic [DW-1:0] s_axis_tdata;
    logic aclk_b,aresetn_b;
    logic sclk,sdi,cs_n;
    logic signed [DW-1:0] recv_data;
endinterface

module AD5543_sim_tb;
    import axi4stream_vip_pkg::*;
    import AD5543_sim_axi4stream_vip_0_0_pkg::*;

    AD5543_sim_axi4stream_vip_0_0_mst_t axis_mst_agent;

    AD5543_sim_if #(16) ad_if();
    bit prog_empty;
    initial begin
        ad_if.fclk=0;
        forever #5 ad_if.fclk=~ad_if.fclk;
    end
    initial begin
        ad_if.freset_n=1'b0;
        repeat(50)@(posedge ad_if.fclk);
        ad_if.freset_n=1'b1;
    end

    AD5543_sim_wrapper UUT(
        .fclk(ad_if.fclk),
        .freset_n(ad_if.freset_n),
        .cs_n(ad_if.cs_n),
        .prog_empty(prog_empty),
        .sclk(ad_if.sclk),
        .sdi(ad_if.sdi)
    );

    bit signed [15:0] recv_data_queue[$];
    AD5543_collect_sim #(16) AD5543_collect_sim_tb_Inst(
        ad_if.sclk,
        ad_if.sdi,
        ad_if.cs_n,
        ad_if.recv_data
    );

    initial begin
        axis_mst_agent=new("axis master vip agent",UUT.AD5543_sim_i.axi4stream_vip_0.inst.IF);
        axis_mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        axis_mst_agent.set_agent_tag("AXIS MASTER VIP");
        axis_mst_agent.set_verbosity(0);
        axis_mst_agent.start_master();

        repeat(10)@(posedge ad_if.fclk);
        forever begin
            repeat(3)@(posedge ad_if.fclk);
            mst_gen_transaction(); 
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
    axi4stream_monitor_transaction axis_mst_monitor_transaction_queue[$];
    bit signed [15:0] goden_data_queue[$]={16'd0,16'd0};
    initial begin
        localparam integer ROUND = 15;
        forever begin
            automatic bit [7:0] unpacked_data[2];
            automatic bit [15:0] goden_data;
            axis_mst_agent.monitor.item_collected_port.get(axis_mst_monitor_transaction);
            axis_mst_monitor_transaction_queue.push_back(axis_mst_monitor_transaction);
            axis_mst_monitor_transaction.get_data(unpacked_data);
            goden_data={>>{unpacked_data}};
            goden_data={goden_data[7:0],goden_data[15:8]};
            goden_data_queue.push_back(goden_data);
        end
    end

    AD5543_data_collect AD5543_data_collect_Inst(ad_if,recv_data_queue);
    scoreboard #(100) thescoreboard_Inst(ad_if,goden_data_queue,recv_data_queue);
endmodule

program AD5543_data_collect(
    AD5543_sim_if ad_if,
    ref bit signed [15:0] recv_data_queue[$]
);
    bit [15:0] shift_data;
    bit signed [15:0] data;
    initial begin
        forever begin
            @(posedge ad_if.cs_n);
            data=ad_if.recv_data;
            recv_data_queue.push_back(data);
        end
    end
endprogram

program scoreboard #(
    parameter integer ROUND = 20
)(
    AD5543_sim_if ad_if,
    ref bit signed [15:0] goden_data_queue[$],
    ref bit signed [15:0] recv_data_queue[$]
);
    initial begin
        for(int i=0;i<ROUND;) begin
            @(posedge ad_if.fclk);
            if(goden_data_queue.size()!=0 && recv_data_queue.size()!=0) begin
                automatic bit signed [15:0] goden_data;
                automatic bit signed [15:0] recv_data;
                goden_data=goden_data_queue.pop_front;
                recv_data=recv_data_queue.pop_front;
                if(goden_data==recv_data) begin
                    $display("right:%4x, wrong:%4x TEST PASS",goden_data,recv_data);
                end
                else begin
                    $display("right:%4x, wrong:%4x TEST FAIL",goden_data,recv_data);
                end
                i=i+1;
            end
        end
    end
endprogram