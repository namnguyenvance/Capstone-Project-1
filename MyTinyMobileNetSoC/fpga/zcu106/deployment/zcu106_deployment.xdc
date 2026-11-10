# Official AMD/Xilinx ZCU106 board files v2.6, installed with Vivado 2024.1.
# part0_pins.xml: indices 122/123 (clock), 132 (LED0), 121 (CPU_RESET).
# board.xml: user_si570_sysclk frequency=300000000; LED/reset active high.
set_property -dict {PACKAGE_PIN AH12 IOSTANDARD DIFF_SSTL12} [get_ports clk_p]
set_property -dict {PACKAGE_PIN AJ12 IOSTANDARD DIFF_SSTL12} [get_ports clk_n]
set_property -dict {PACKAGE_PIN AL11 IOSTANDARD LVCMOS12} [get_ports led]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS18} [get_ports reset]
create_clock -name board_clk -period 3.333333 [get_ports clk_p]

# Button is asynchronous and drives only the release synchronizer's async set.
set_false_path -from [get_ports reset]
# Human-visible LED is not sampled by a clocked external receiver.
set_false_path -to [get_ports led]
# No exceptions apply to the counter or internal reset-release paths.
