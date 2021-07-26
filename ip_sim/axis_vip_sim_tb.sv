`timescale 1ns/10ps

module axis_vip_sim_tb;
    import axi4stream_vip_pkg::*;
    import axis_vip_sim_0_0_pkg::*;
    import axis_vip_sim_1_0_pkg::*;

    axis_vip_sim_axi4stream_vip_0_0_mst_t mst_agent;
    axis_vip_sim_axi4stream_vip_0_0_slv_t slv_agent;

    bit aclk_0,aresetn_0;
    always #50 aclk_0=~aclk_0;
    initial begin
        aresetn_0=0;
        #100;
        aresetn_0=1;
    end
    axis_vip_sim_wrapper UUT(
        .aclk_0(aclk_0)
    )
    
endmodule