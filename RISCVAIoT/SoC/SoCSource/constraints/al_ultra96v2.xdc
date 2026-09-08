create_clock -period 10.00 [get_ports CLK]

#set_property -dict { PACKAGE_PIN A9 IOSTANDARD LVCMOS18 } [get_ports LEDS[0]];
#set_property -dict { PACKAGE_PIN B9 IOSTANDARD LVCMOS18 } [get_ports LEDS[1]];
#set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS18 } [get_ports TX];
#set_property -dict { PACKAGE_PIN F8 IOSTANDARD LVCMOS18 } [get_ports RX];