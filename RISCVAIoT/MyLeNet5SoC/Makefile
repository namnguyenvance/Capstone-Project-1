# Compiler and tool definitions
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
IVERILOG = iverilog
VVP      = vvp

# Compile flags for RISC-V 32-bit (base integer only, no float, no compressed)
CFLAGS = -mabi=ilp32 -march=rv32im -ffreestanding -nostdlib -O2

# Default target
all: sim

# 1. Compile C and Assembly firmware into ELF
firmware.elf: start.s main_lenet.c dl_ops.c quantize.c sections.lds ../DLCProgram/CSource/lenet_model_data.c mnist_test_images.h
	$(CC) $(CFLAGS) -T sections.lds -o firmware.elf start.s main_lenet.c dl_ops.c quantize.c ../DLCProgram/CSource/lenet_model_data.c

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
