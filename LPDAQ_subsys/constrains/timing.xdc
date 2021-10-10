create_clock -period 61.035 -name adc_sck [get_ports sck]
set_clock_groups -name clk_async1 -asynchronous -group [get_clocks -include_generated_clocks clk_fpga_0] -group [get_clocks -include_generated_clocks adc_sck]
set_input_delay -clock [get_clocks adc_sck] -min -add_delay 0.500 [get_ports dout]
set_input_delay -clock [get_clocks adc_sck] -max -add_delay 15.500 [get_ports dout]
set_input_delay -clock [get_clocks adc_sck] -min -add_delay 0.500 [get_ports fsync]
set_input_delay -clock [get_clocks adc_sck] -max -add_delay 5.500 [get_ports fsync]

