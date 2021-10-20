

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list DNCCTP_subsys_i/clk_wiz_0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[0]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[1]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[2]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[3]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[4]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[5]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[6]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[7]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[8]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[9]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[10]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[11]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[12]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[13]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[14]} {DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tdata[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/cs_n_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/s_axis_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/sclk_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list DNCCTP_subsys_i/ad5543_top/inst/the_ad5543_Inst/sdi_r]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_out2]
