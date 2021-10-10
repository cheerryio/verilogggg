set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports dout]
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports fsync]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports reset_n]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports sck]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports start]

set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports base_uart_txd]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports base_uart_rxd]