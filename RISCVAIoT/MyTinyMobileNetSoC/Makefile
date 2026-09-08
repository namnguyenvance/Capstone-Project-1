# TinyMobileNet CIFAR-10 on PicoRV32 SoC
# Compiler and tool definitions
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
IVERILOG = iverilog
VVP      = vvp

# Compile flags for RISC-V 32-bit (base integer + multiply, no float, no compressed)
CFLAGS = -mabi=ilp32 -march=rv32im -ffreestanding -nostdlib -O2

# Source files
C_SOURCES = main_tinymobilenet.c dl_ops.c quantize.c tinymobilenet_model_data.c
VERILOG_SOURCES = tb.v my_soc.v picorv32.v simpleuart.v my_accel.v my_conv_accel.v my_quant_accel.v my_dw_conv_accel.v

# Default target
all: sim

# 1. Compile C and Assembly firmware into ELF
firmware.elf: start.s $(C_SOURCES) tinymobilenet_model_data.h mnist_test_images.h
	$(CC) $(CFLAGS) -T sections.lds -o firmware.elf start.s $(C_SOURCES)

# 2. Convert ELF to Verilog Hex file
firmware.hex: firmware.elf
	$(OBJCOPY) -O verilog firmware.elf firmware.hex

# 3. Compile Verilog design using Icarus Verilog
sim.vvp: $(VERILOG_SOURCES)
	$(IVERILOG) -o sim.vvp $(VERILOG_SOURCES)

# 4. Run the simulation
sim: firmware.hex sim.vvp
	$(VVP) sim.vvp

# Training pipeline targets
train:
	python3 train_model.py

generate:
	python3 generate_model_data.py

extract_test:
	python3 extract_mnist_test.py

# Full pipeline: train → generate → extract → build → simulate
pipeline: train generate extract_test sim

# Clean temporary files
clean:
	rm -f firmware.elf firmware.hex sim.vvp

.PHONY: all sim clean train generate extract_test pipeline
