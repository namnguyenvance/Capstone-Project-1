# Compiler and tool definitions
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
IVERILOG = iverilog
VVP      = vvp

# Compile flags for RISC-V 32-bit (base integer only, no float, no compressed)
CFLAGS = -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -O2

# Default target
all: sim

# 1. Compile C and Assembly firmware into ELF
firmware.elf: start.s main_nn.c sections.lds nn_data.h
	$(CC) $(CFLAGS) -T sections.lds -o firmware.elf start.s main_nn.c

# 2. Convert ELF to Verilog Hex file
firmware.hex: firmware.elf
	$(OBJCOPY) -O verilog firmware.elf firmware.hex

# 3. Compile Verilog design using Icarus Verilog
sim.vvp: tb.v my_soc.v picorv32.v simpleuart.v my_accel.v my_conv_accel.v my_quant_accel.v
	$(IVERILOG) -o sim.vvp tb.v my_soc.v picorv32.v simpleuart.v my_accel.v my_conv_accel.v my_quant_accel.v

# 4. Run the simulation
sim: firmware.hex sim.vvp
	$(VVP) sim.vvp

# Clean temporary files
clean:
	rm -f firmware.elf firmware.hex sim.vvp

.PHONY: all sim clean
