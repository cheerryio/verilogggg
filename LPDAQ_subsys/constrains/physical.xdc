set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports dout]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports fsync]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports reset_n]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports sck]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports start]

set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports IIC_scl_io]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports IIC_sda_io]

set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports led0]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports led1]