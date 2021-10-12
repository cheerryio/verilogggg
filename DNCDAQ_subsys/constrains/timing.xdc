create_clock -period 10.417 -name adc_sclk -add [get_ports sclk_p]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_ports adc_sclk_p]
set_clock_groups -name clk_async1 -asynchronous -group [get_clocks -include_generated_clocks clk_fpga_0] -group [get_clocks -include_generated_clocks adc_sclk]

set_input_delay -clock [get_clocks adc_sclk] -min -add_delay 1.000 [get_ports dout_p]
set_input_delay -clock [get_clocks adc_sclk] -max -add_delay 3.000 [get_ports dout_p]
set_input_delay -clock [get_clocks adc_sclk] -min -add_delay 1.500 [get_ports drdy_p]
set_input_delay -clock [get_clocks adc_sclk] -max -add_delay 3.500 [get_ports drdy_p]
