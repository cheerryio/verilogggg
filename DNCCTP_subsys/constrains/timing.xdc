create_clock -period 31.250 -name clk_32M [get_ports clk_32M]
create_generated_clock -name sclk_dac -source [get_pins DNCCTP_subsys_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT1] -divide_by 2 -add -master_clock clk_out2_DNCCTP_subsys_clk_wiz_0_0 [get_ports sclk]

set_clock_groups -name clk_async1 -asynchronous -group [get_clocks -include_generated_clocks clk_fpga_0] -group [get_clocks -include_generated_clocks clk_32M]

