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
VERILOG_SOURCES = tb.v my_soc.v picorv32.v simpleuart.v my_accel.v my_conv_accel.v my_quant_accel.v my_dw_conv_accel.v my_pw_conv_accel.v

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

# Standalone pointwise verification; unique temporary artifact, removed on exit.
test_pw:
	@set -eu; artifact=$$(mktemp /tmp/tb_pw_conv_accel.XXXXXX); \
	trap 'rm -f "$$artifact"' EXIT HUP INT TERM; \
	$(IVERILOG) -g2012 -Wall -s tb_pw_conv_accel -o "$$artifact" tb_pw_conv_accel.v my_pw_conv_accel.v; \
	$(VVP) "$$artifact"

# Production batch arithmetic and actual SoC PW handshake, without inference.
test_pw_batch:
	@set -eu; artifact=$$(mktemp /tmp/tb_pw_batch.XXXXXX); \
	trap 'rm -f "$$artifact"' EXIT HUP INT TERM; \
	$(IVERILOG) -g2012 -Wall -s tb_pw_conv_accel_batch -o "$$artifact" tb_pw_conv_accel.v my_pw_conv_accel.v; \
	$(VVP) "$$artifact"

test_pw_bus:
	@set -eu; artifact=$$(mktemp /tmp/tb_pw_bus.XXXXXX); \
	trap 'rm -f "$$artifact"' EXIT HUP INT TERM; \
	$(IVERILOG) -g2012 -Wall -s tb_pw_bus -o "$$artifact" tb_pw_bus.v $(filter-out tb.v,$(VERILOG_SOURCES)); \
	$(VVP) "$$artifact"

# Persistent PW1 cache arithmetic and firmware trace equivalence.
test_pw_cache:
	@set -eu; artifact=$$(mktemp /tmp/tb_pw_cache.XXXXXX); \
	trap 'rm -f "$$artifact"' EXIT HUP INT TERM; \
	$(IVERILOG) -g2012 -Wall -s tb_pw_cache -o "$$artifact" tb_pw_cache.v my_pw_conv_accel.v; \
	$(VVP) "$$artifact"

verify_pw_firmware:
	@set -eu; artifact=$$(mktemp /tmp/verify_pw_firmware.XXXXXX); \
	trap 'rm -f "$$artifact"' EXIT HUP INT TERM; \
	cc -O2 -fwrapv verify_pw_firmware.c quantize.c tinymobilenet_model_data.c -o "$$artifact"; \
	"$$artifact"

verify_pw_cache:
	python3 -B verify_pw_cache.py

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

.PHONY: all sim clean train generate extract_test pipeline test_pw test_pw_batch test_pw_bus test_pw_cache verify_pw_firmware verify_pw_cache
