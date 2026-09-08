#####################################################################################################
#                                         SIMULATION MAKEFILE                                       #
#                      Supports: Xcelium (xrun) for module-level and SoC-level testbenches          #
#####################################################################################################

# Simulator options
XR = xrun -64bit -sv -uvmhome CDNS-1.1d -uvm -fst -createdebugdb -comb_depth -intermod_path -multview -notarget_svbind -primbind -timescale 1ps/1ps -access +rwc -status -status3 -licqueue

# Source directories and include flags
SRC_DIRS = Source Source/al_accel
SRC_INCFLAGS = $(addprefix +incdir+,$(SRC_DIRS))

# All Verilog source files
SRC_FILES = $(wildcard Source/*.v) $(wildcard Source/al_accel/*.v)
ALPICO_FILES = $(filter-out Source/picosoc.v Source/ultra96v2.v, $(SRC_FILES))
PICO_FILES = $(wildcard Source/ultra96v2.v Source/simpleuart.v Source/picosoc.v)
AL_FILE = $(wildcard Source/al_accel/*.v)
# Testbench directory
TB_DIR = Testbench

# SOC Testbench top module and firmware file
AL_SOC = al_ultra96v2_tb
ORIG_SOC = ultra96v2_tb
FW_ALSOC_FILE = firmware/soc_firmware/al_ultra96v2_fw.hex
FW_SOC_FILE = firmware/soc_firmware/ultra96v2_fw.hex



# Output directories
XR_LOG_DIR = run/sim_xr/accel_log
XR_VCD_DIR = run/sim_xr/accel_vcd

# Default help target
help:
	@echo "Usage:"
	@echo "  make sim_xr TB=<name>         - Run simulation with Xcelium for module testbench (e.g., TB=adder)"
	@echo "  make sim_al_ultra96v2         - Run simulation for SoC testbench (al_ultra96v2_tb)"
	@echo "  make clean_all                - Clean all generated files"
	@echo ""
	@echo "Examples:"
	@echo "  make sim_xr TB=al_accel_mac"
	@echo "  make sim_al_ultra96v2"
	@echo "  make clean_all"

#####################################################################################################
#                               Simulation for individual modules (Xcelium)                         #
#####################################################################################################

sim_xr:
ifndef TB
	$(error ❌ Please provide TB=<source_file>, e.g., make sim_xr TB=adder)
endif
	@echo "🚀 Running simulation with Xcelium for testbench '$(TB)_tb.v'..."
	mkdir -p $(XR_LOG_DIR)
	mkdir -p $(XR_VCD_DIR)
	mkdir -p run/sim_xr
	pushd run/sim_xr && \
	$(XR) $(SRC_INCFLAGS) \
		$(addprefix ../../,$(AL_FILE)) \
		../../$(TB_DIR)/$(TB)_tb.v \
		|tee accel_log/$(basename $(TB))_tb.log ; \
	popd
	@echo "✅ Simulation completed. Log saved in $(XR_LOG_DIR)/$(basename $(TB))_tb.log"

#####################################################################################################
#                                         Clean up                                                   #
#####################################################################################################

clean_all:
	@echo "🧹 Cleaning all generated simulation files..."
	rm -rf run/*
	@echo "✅ All files cleaned."



RISCV_PATH := /tools/riscv/bin
export PATH := $(RISCV_PATH):$(PATH)
TOOLCHAIN_PREFIX = riscv64-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
CPP     = $(TOOLCHAIN_PREFIX)cpp

TOOL_DIR = python_tools
VITIS_ALPICO_DIR = vitis_fw/al_pico
VITIS_PICO_DIR = vitis_fw/pico
SOC_FW_DIR = firmware/soc_firmware

TD = CNN_TEST

ULTRA96V2_FW_C_OBJS = 	$(SOC_FW_DIR)/c/al_accel_cfg.c \
						$(SOC_FW_DIR)/c/pico_fw.c \
						$(SOC_FW_DIR)/c/dl_ops.c \
					 	$(SOC_FW_DIR)/c/dl_quantize.c \
						$(SOC_FW_DIR)/c/fw_utils.c \
						$(SOC_FW_DIR)/c/pico_io.c \
						$(SOC_FW_DIR)/c/fw_layer_test.c $(SOC_FW_DIR)/c/fw_layer_data.c \
						$(SOC_FW_DIR)/c/fw_model_test.c $(SOC_FW_DIR)/c/mnist_input_data.c \
						$(SOC_FW_DIR)/c/mnist_pico_model_data.c \
						$(SOC_FW_DIR)/c/cnn_pico_model_data.c \
						$(SOC_FW_DIR)/c/cnnnew_pico_model_data.c

AL_ULTRA96V2_FW_C_OBJS = 	$(SOC_FW_DIR)/c/fw_model_test.c $(SOC_FW_DIR)/c/mnist_input_data.c \
							$(SOC_FW_DIR)/c/mnist_alpico_model_data.c \
							$(SOC_FW_DIR)/c/cnn_alpico_model_data.c \
							$(SOC_FW_DIR)/c/cnnnew_alpico_model_data.c \
							$(SOC_FW_DIR)/c/al_accel_cfg.c \
							$(SOC_FW_DIR)/c/al_pico_fw.c \
							$(SOC_FW_DIR)/c/dl_ops.c \
					 		$(SOC_FW_DIR)/c/dl_quantize.c \
							$(SOC_FW_DIR)/c/fw_utils.c \
							$(SOC_FW_DIR)/c/pico_io.c \
							$(SOC_FW_DIR)/c/fw_layer_test.c $(SOC_FW_DIR)/c/fw_layer_data.c \


HELLO_WORD_FW_C_OBJS = 	$(SOC_FW_DIR)/c/pico_io.c \
						$(SOC_FW_DIR)/c/hello_word.c \

# Tùy chọn biên dịch cho PicoRV32
CFLAGS = -march=rv32imc -mabi=ilp32 -nostdlib -Os -ffreestanding
LDFLAGS = -Wl,--build-id=none,-Bstatic,--strip-debug -lgcc

# Build ELF
hello.elf: hello.c hello.lds
	$(CC) $(CFLAGS) -nostdlib -nostartfiles -ffreestanding \
		-Wl,--build-id=none,-Bstatic,-T,hello.lds,--strip-debug \
		-o $@ hello.c -lgcc

# Try objcopy with verilog; if not supported, fall back to binary + python
hello.hex: hello.elf
	-$(OBJCOPY) -O verilog --verilog-data-width=8 hello.elf hello.hex 2>/dev/null || \
	( $(OBJCOPY) -O binary hello.elf hello.bin && python3 bin2hex.py > hello.hex )

clean:
	rm -f hello.elf hello.hex hello.bin


#########################################################################################################################
###################################################### TEST AL_SOC ######################################################
#########################################################################################################################
sim_fs_zcu106: fs_zcu106_firmware
	@echo "🚀 Running SoC simulation for $(AL_SOC) with firmware: $(FW_ALSOC_FILE)"
	@echo "ℹ️  Using define: TD = $(TD)"
	mkdir -p $(XR_LOG_DIR)
	mkdir -p $(XR_VCD_DIR)
	mkdir -p run/sim_xr
	cd run/sim_xr && \
	$(XR) $(SRC_INCFLAGS) +define+$(TD) \
		$(addprefix ../../,$(ALPICO_FILES)) \
		../../$(TB_DIR)/soc_tb/$(AL_SOC).v \
		+firmware=$(abspath $(FW_ALSOC_FILE)) \
		| tee  accel_log/$(basename $(AL_SOC)).log ; \
	@echo "✅ Simulation completed. Log saved in $(XR_LOG_DIR)/$(AL_SOC).log"

al_ultra96v2_sections.lds: $(SOC_FW_DIR)/section/al_sections.lds
	$(CPP) -P -DULTRA96V2 -o $(SOC_FW_DIR)/section/$@ $^

al_ultra96v2_fw.elf: al_ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)
	$(CC) $(CFLAGS) -DULTRA96V2 -DAL_ACCEL -D$(TD) \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/al_ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/al_ultra96v2_fw.elf \
		$(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS) \
		-lgcc

al_ultra96v2_fw.hex: al_ultra96v2_fw.elf
	$(OBJCOPY) -O verilog $(SOC_FW_DIR)/al_ultra96v2_fw.elf $(SOC_FW_DIR)/al_ultra96v2_fw.hex

clean_al_ultra96v2: 
	rm -vrf \
		$(AL_ULTRA96V2_FW_OBJS)  \
		$(SOC_TB_DIR)/al_ultra96v2_tb.vvp \
		$(SOC_LOG_DIR)/al_ultra96v2_tb*\

#########################################################################################################################
###################################################### TEST SOC ######################################################
#########################################################################################################################
sim_zcu106: ultra96v2_fw.hex
	@echo "🚀 Running SoC simulation for $(ORIG_SOC) with firmware: $(FW_SOC_FILE)"
	@echo "ℹ️  Using define: TD = $(TD)"
	mkdir -p $(XR_LOG_DIR)
	mkdir -p $(XR_VCD_DIR)
	mkdir -p run/sim_xr
	cd run/sim_xr && \
	$(XR) $(SRC_INCFLAGS) +define+$(TD) \
		$(addprefix ../../,$(PICO_FILES)) \
		../../$(TB_DIR)/soc_tb/$(ORIG_SOC).v \
		+firmware=$(abspath $(FW_SOC_FILE)) \
		| tee  accel_log/$(basename $(ORIG_SOC)).log ; \
	@echo "✅ Simulation completed. Log saved in $(XR_LOG_DIR)/$(ORIG_SOC).log"
	
ultra96v2_sections.lds: $(SOC_FW_DIR)/section/sections.lds
	$(CPP) -P -DULTRA96V2 -o $(SOC_FW_DIR)/section/$@ $^

ultra96v2_fw.elf: ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)
	$(CC) $(CFLAGS) -DULTRA96V2 -D$(TD) -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS) \
		-lgcc

ultra96v2_fw.hex: ultra96v2_fw.elf
	$(OBJCOPY) -O verilog $(SOC_FW_DIR)/ultra96v2_fw.elf $(SOC_FW_DIR)/ultra96v2_fw.hex

clean_ultra96v2: 
	rm -vrf \
		$(AL_ULTRA96V2_FW_OBJS)  \
		$(SOC_TB_DIR)/ultra96v2_tb.vvp \
		$(SOC_LOG_DIR)/ultra96v2_tb*\


#########################################################################################################################
###################################################### For Vitis ########################################################
#########################################################################################################################
# For AL_SoC
hex_al_ultra96v2_fw: vitis_al_ultra96v2_fw.hex
	python 	$(TOOL_DIR)/write_hex_to_c.py $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.hex \
			$(VITIS_ALPICO_DIR)/al_ultra96v2_fw_hex_data.c $(VITIS_ALPICO_DIR)/al_ultra96v2_fw_hex_data.h

vitis_al_ultra96v2_fw.hex: vitis_al_ultra96v2_fw.elf
	$(OBJCOPY) -O verilog $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.elf $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.hex

vitis_al_ultra96v2_fw.elf: al_ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)
	$(CC) $(CFLAGS) -DULTRA96V2 -DAL_ACCEL -D$(TD) -DVITIS -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/al_ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS) \
		-lgcc

# For SoC
hex_ultra96v2_fw: vitis_ultra96v2_fw.hex
	python 	$(TOOL_DIR)/write_hex_to_c.py $(SOC_FW_DIR)/vitis_ultra96v2_fw.hex \
			$(VITIS_PICO_DIR)/ultra96v2_fw_hex_data.c $(VITIS_PICO_DIR)/ultra96v2_fw_hex_data.h

vitis_ultra96v2_fw.hex: vitis_ultra96v2_fw.elf
	$(OBJCOPY) -O verilog $(SOC_FW_DIR)/vitis_ultra96v2_fw.elf $(SOC_FW_DIR)/vitis_ultra96v2_fw.hex

vitis_ultra96v2_fw.elf: ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)
	$(CC) $(CFLAGS) -DULTRA96V2 -D$(TD) -DVITIS -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/vitis_ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS) \
		-lgcc


#################################################################################################################################
###################################################### For Firmware.hex ########################################################
#################################################################################################################################
Source/firmware.mem: $(SOC_FW_DIR)/al_ultra96v2_fw.hex $(TOOL_DIR)/hex_convert.py
	python $(TOOL_DIR)/hex_convert.py $< $@

fs_zcu106_firmware: al_ultra96v2_fw.hex Source/firmware.mem


convert_mem_to_hex: 
	python $(TOOL_DIR)/convert_mem_to_coe.py Source/firmware.mem coe/firmware.coe


zcu106_firmware: ultra96v2_fw.hex Source/ultra96v2_firmware.mem
Source/ultra96v2_firmware.mem: $(SOC_FW_DIR)/ultra96v2_fw.hex $(TOOL_DIR)/hex_convert.py
	python $(TOOL_DIR)/hex_convert.py $< $@