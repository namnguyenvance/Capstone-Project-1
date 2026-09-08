######################################################################################################################
############################################# ENVIRONMENT INITIALIZATION #############################################
######################################################################################################################
RISCV_GNU_TOOLCHAIN_GIT_REVISION = 411d134
RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX = /opt/riscv32

# Give the user some easy overrides for local configuration quirks.
# If you change one of these and it breaks, then you get to keep both pieces.
SHELL = bash
PYTHON = python3
VERILATOR = verilator
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)

TEST_OBJS = $(addsuffix .o,$(basename $(wildcard toolchain_test/*.S)))
FIRMWARE_OBJS = firmware/cpu_firmware/start.o firmware/cpu_firmware/irq.o firmware/cpu_firmware/print.o firmware/cpu_firmware/hello.o firmware/cpu_firmware/sieve.o firmware/cpu_firmware/multest.o firmware/cpu_firmware/stats.o
GCC_WARNS  = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic # -Wconversion
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
COMPRESSED_ISA = C

GIT_ENV = true
NWORDS = 32768

###############################
### ALPHA ACCELERATOR MACRO ###
###############################
ACCEL_TB_DIR 		= testbench/accelerator_tb
ACCEL_HDL_OBJS_DIR 	= source/accel_source
ACCEL_LOG_DIR 		= out_log/accel_log

PU_SUB_VOBJS	=	$(ACCEL_HDL_OBJS_DIR)/al_accel_mac.v 		$(ACCEL_HDL_OBJS_DIR)/al_accel_lut.v \
					$(ACCEL_HDL_OBJS_DIR)/al_accel_lpureg.v

ELW_SUB_VOBJS   = 	$(ACCEL_HDL_OBJS_DIR)/al_accel_quant_unit.v	$(ACCEL_HDL_OBJS_DIR)/al_accel_act_func_unit.v \
				  	$(ACCEL_HDL_OBJS_DIR)/al_accel_cp_unit.v	$(ACCEL_HDL_OBJS_DIR)/al_accel_quant_lut.v

PU_ARR_SUB_VOBJS = 	$(ACCEL_HDL_OBJS_DIR)/al_accel_wreg.v 		$(ACCEL_HDL_OBJS_DIR)/al_accel_ireg.v \
				   	$(ACCEL_HDL_OBJS_DIR)/al_accel_pu.v	\
					$(PU_SUB_VOBJS)

PU_MAT_SUB_VOBJS = 	$(ACCEL_HDL_OBJS_DIR)/al_accel_wdemux.v		$(ACCEL_HDL_OBJS_DIR)/al_accel_idemux.v \
				   	$(ACCEL_HDL_OBJS_DIR)/al_accel_pu_array.v \
					$(PU_ARR_SUB_VOBJS)
					
FLW_CTRL_SUB_VOBJS = 	$(ACCEL_HDL_OBJS_DIR)/al_accel_RDATA_ctrl.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_COMPS_ctrl.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_WBACK_ctrl.v 

AL_ACCEL_SUB_VOBJS =	$(ACCEL_HDL_OBJS_DIR)/al_accel_bpbuf.v 		$(ACCEL_HDL_OBJS_DIR)/al_accel_wbuf.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_obuf.v 		$(ACCEL_HDL_OBJS_DIR)/al_accel_ibuf.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_pu_matrix.v 	$(PU_MAT_SUB_VOBJS) \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_acc_matrix.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_elw_unit.v	$(ELW_SUB_VOBJS) \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_config_regs.v \
						$(ACCEL_HDL_OBJS_DIR)/al_accel_flow_ctrl.v 	$(FLW_CTRL_SUB_VOBJS) 

###########################
### ALPHA PICOSOC MACRO ###
###########################
SOC_TB_DIR			= testbench/soc_tb
SOC_HDL_OBJS_DIR	= source
SOC_FW_DIR			= firmware/soc_firmware
SOC_LOG_DIR			= out_log/soc_log

ULTRA96V2_VOBJS = $(SOC_TB_DIR)/ultra96v2_tb.v \
				  $(SOC_HDL_OBJS_DIR)/ultra96v2.v \
				  $(SOC_HDL_OBJS_DIR)/simpleuart.v \
				  $(SOC_HDL_OBJS_DIR)/picosoc.v  $(SOC_HDL_OBJS_DIR)/picorv32.v 

ULTRA96V2_FW_OBJS = $(SOC_FW_DIR)/section/ultra96v2_sections.lds \
					$(SOC_FW_DIR)/ultra96v2_fw.elf \
					$(SOC_FW_DIR)/ultra96v2_fw.hex

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
						$(SOC_FW_DIR)/c/cnnnew_pico_model_data.c \
						

AL_ULTRA96V2_VOBJS =	$(SOC_TB_DIR)/al_ultra96v2_tb.v \
				  		$(SOC_HDL_OBJS_DIR)/al_ultra96v2.v \
						$(SOC_HDL_OBJS_DIR)/simpleuart.v \
						$(SOC_HDL_OBJS_DIR)/al_picosoc.v  $(SOC_HDL_OBJS_DIR)/picorv32.v \
				  		$(SOC_HDL_OBJS_DIR)/al_accel_pico_ctrl.v \
				  		$(ACCEL_HDL_OBJS_DIR)/al_accel.v $(AL_ACCEL_SUB_VOBJS)

AL_ULTRA96V2_FW_OBJS = 	$(SOC_FW_DIR)/section/al_ultra96v2_sections.lds \
						$(SOC_FW_DIR)/al_ultra96v2_fw.elf \
						$(SOC_FW_DIR)/al_ultra96v2_fw.hex

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
							
							
TD = MODEL_TEST

TOOL_DIR	= python_tools
VITIS_DIR	= vitis_out
VITIS_ALPICO_DIR	= ~/Documents/Xilinx/Vitis/FW_AlPicoSoC/src
VITIS_PICO_DIR		= ~/Documents/Xilinx/Vitis/FW_PicoSoC/src
######################################################################################################################
###################################################### TEST SOC ######################################################
######################################################################################################################

# ---- Ultra96V2 Board ----
# Alpha SoC
sim_al_ultra96v2: al_ultra96v2_tb.vvp al_ultra96v2_fw.hex
	vvp -N $(SOC_TB_DIR)/$< +firmware=$(SOC_FW_DIR)/al_ultra96v2_fw.hex > $(SOC_LOG_DIR)/al_ultra96v2_tb.log

hex_al_ultra96v2_fw: vitis_al_ultra96v2_fw.hex
	python 	$(TOOL_DIR)/write_hex_to_c.py $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.hex \
			$(VITIS_ALPICO_DIR)/al_ultra96v2_fw_hex_data.c $(VITIS_ALPICO_DIR)/al_ultra96v2_fw_hex_data.h

al_ultra96v2_tb.vvp: $(AL_ULTRA96V2_VOBJS)
	iverilog -D$(TD) -s al_ultra96v2_wrapper -o $(SOC_TB_DIR)/$@ $^

clean_al_ultra96v2: 
	rm -vrf \
		$(AL_ULTRA96V2_FW_OBJS)  \
		$(SOC_TB_DIR)/al_ultra96v2_tb.vvp \
		$(SOC_LOG_DIR)/al_ultra96v2_tb*\

al_ultra96v2_sections.lds: $(SOC_FW_DIR)/section/al_sections.lds
	$(TOOLCHAIN_PREFIX)cpp -P -DULTRA96V2 -o $(SOC_FW_DIR)/section/$@ $^

al_ultra96v2_fw.elf: al_ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -DULTRA96V2 -DAL_ACCEL -D$(TD) -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/al_ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/al_ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)

al_ultra96v2_fw.hex: al_ultra96v2_fw.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $(SOC_FW_DIR)/al_ultra96v2_fw.elf $(SOC_FW_DIR)/al_ultra96v2_fw.hex

vitis_al_ultra96v2_fw.elf: al_ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -DULTRA96V2 -DAL_ACCEL -D$(TD) -DVITIS -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/al_ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(AL_ULTRA96V2_FW_C_OBJS)

vitis_al_ultra96v2_fw.hex: vitis_al_ultra96v2_fw.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.elf $(SOC_FW_DIR)/vitis_al_ultra96v2_fw.hex

# Orignial SoC
sim_ultra96v2: ultra96v2_tb.vvp ultra96v2_fw.hex
	vvp -N $(SOC_TB_DIR)/$< +firmware=$(SOC_FW_DIR)/ultra96v2_fw.hex > $(SOC_LOG_DIR)/ultra96v2_tb.log

hex_ultra96v2_fw: vitis_ultra96v2_fw.hex
	python 	$(TOOL_DIR)/write_hex_to_c.py $(SOC_FW_DIR)/vitis_ultra96v2_fw.hex \
			$(VITIS_PICO_DIR)/ultra96v2_fw_hex_data.c $(VITIS_PICO_DIR)/ultra96v2_fw_hex_data.h

ultra96v2_tb.vvp: $(ULTRA96V2_VOBJS)
	iverilog -D$(TD) -s ultra96v2_wrapper -o $(SOC_TB_DIR)/$@ $^ 

clean_ultra96v2: 
	rm -vrf \
		$(ULTRA96V2_FW_OBJS)  \
		$(SOC_TB_DIR)/ultra96v2_tb.vvp \
		$(SOC_LOG_DIR)/ultra96v2_tb*\

ultra96v2_sections.lds: $(SOC_FW_DIR)/section/sections.lds
	$(TOOLCHAIN_PREFIX)cpp -P -DULTRA96V2 -o $(SOC_FW_DIR)/section/$@ $^

ultra96v2_fw.elf: ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -DULTRA96V2 -D$(TD) -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)

ultra96v2_fw.hex: ultra96v2_fw.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $(SOC_FW_DIR)/ultra96v2_fw.elf $(SOC_FW_DIR)/ultra96v2_fw.hex

vitis_ultra96v2_fw.elf: ultra96v2_sections.lds $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -DULTRA96V2 -D$(TD) -DVITIS -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,$(SOC_FW_DIR)/section/ultra96v2_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $(SOC_FW_DIR)/vitis_ultra96v2_fw.elf $(SOC_FW_DIR)/c/start.s $(ULTRA96V2_FW_C_OBJS)

vitis_ultra96v2_fw.hex: vitis_ultra96v2_fw.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $(SOC_FW_DIR)/vitis_ultra96v2_fw.elf $(SOC_FW_DIR)/vitis_ultra96v2_fw.hex

# Some code that Verilator not support
# ultra96v2_sim: $(SOC_TB_DIR)/ultra96v2_tb 
# 	./$(SOC_TB_DIR)/ultra96v2_tb  +vcd

# $(SOC_TB_DIR)/ultra96v2_tb: $(ULTRA96V2_VOBJS) $(SOC_TB_DIR)/ultra96v2_tb.cc
# 	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module ultra96v2_wrapper $(ULTRA96V2_VOBJS) ultra96v2_tb.cc \
# 			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir $(SOC_TB_DIR)/ultra96v2_tb_dir
# 	$(MAKE) -C $(SOC_TB_DIR)/ultra96v2_tb_dir -f Vultra96v2_wrapper.mk
# 	cp $(SOC_TB_DIR)/ultra96v2_tb_dir/Vultra96v2_wrapper $(SOC_TB_DIR)/ultra96v2_tb

######################################################################################################################
################################################## TEST ACCELERATOR ##################################################
######################################################################################################################

### al_accel ##
sim_al_accel_tb: al_accel_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_tb.log

al_accel_tb.vvp: $(ACCEL_TB_DIR)/al_accel_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel.v $(AL_ACCEL_SUB_VOBJS)
	iverilog -D$(TD) -s al_accel_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_tb.*

### al_accel_flow_ctrl ##
sim_al_accel_flow_ctrl_tb: al_accel_flow_ctrl_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_flow_ctrl_tb.log

al_accel_flow_ctrl_tb.vvp: $(ACCEL_TB_DIR)/al_accel_flow_ctrl_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_flow_ctrl.v $(FLW_CTRL_SUB_VOBJS)
	iverilog -s al_accel_flow_ctrl_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_flow_ctrl_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_flow_ctrl_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_flow_ctrl_tb.*

### al_accel_WBACK_ctrl ##
sim_al_accel_WBACK_ctrl_tb: al_accel_WBACK_ctrl_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_WBACK_ctrl_tb.log

al_accel_WBACK_ctrl_tb.vvp: $(ACCEL_TB_DIR)/al_accel_WBACK_ctrl_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_WBACK_ctrl.v 
	iverilog -s al_accel_WBACK_ctrl_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_WBACK_ctrl_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_WBACK_ctrl_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_WBACK_ctrl_tb.*

### al_accel_COMPS_ctrl ##
sim_al_accel_COMPS_ctrl_tb: al_accel_COMPS_ctrl_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_COMPS_ctrl_tb.log

al_accel_COMPS_ctrl_tb.vvp: $(ACCEL_TB_DIR)/al_accel_COMPS_ctrl_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_COMPS_ctrl.v 
	iverilog -s al_accel_COMPS_ctrl_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_COMPS_ctrl_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_COMPS_ctrl_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_COMPS_ctrl_tb.*

### al_accel_RDATA_ctrl ##
sim_al_accel_RDATA_ctrl_tb: al_accel_RDATA_ctrl_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_RDATA_ctrl_tb.log

al_accel_RDATA_ctrl_tb.vvp: $(ACCEL_TB_DIR)/al_accel_RDATA_ctrl_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_RDATA_ctrl.v 
	iverilog -s al_accel_RDATA_ctrl_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_RDATA_ctrl_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_RDATA_ctrl_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_RDATA_ctrl_tb.*

### al_accel_pu_matrix ##
sim_al_accel_pu_matrix_tb: al_accel_pu_matrix_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_pu_matrix_tb.log

al_accel_pu_matrix_tb.vvp: $(ACCEL_TB_DIR)/al_accel_pu_matrix_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_pu_matrix.v $(PU_MAT_SUB_VOBJS)
	iverilog -s al_accel_pu_matrix_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_pu_matrix_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_pu_matrix_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_pu_matrix_tb.*

### al_accel_pu_array ##
sim_al_accel_pu_array_tb: al_accel_pu_array_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_pu_array_tb.log

al_accel_pu_array_tb.vvp: $(ACCEL_TB_DIR)/al_accel_pu_array_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_pu_array.v $(PU_ARR_SUB_VOBJS)
	iverilog -s al_accel_pu_array_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_pu_array_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_pu_array_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_pu_array_tb.*

### al_accel_pu ##
sim_al_accel_pu_tb: al_accel_pu_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_pu_tb.log

al_accel_pu_tb.vvp: $(ACCEL_TB_DIR)/al_accel_pu_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_pu.v $(PU_SUB_VOBJS)
	iverilog -s al_accel_pu_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_pu_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_pu_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_pu_tb.*

### al_accel_elw_unit ##
sim_al_accel_elw_unit_tb: al_accel_elw_unit_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_elw_unit_tb.log 

al_accel_elw_unit_tb.vvp: $(ACCEL_TB_DIR)/al_accel_elw_unit_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_elw_unit.v $(ELW_SUB_VOBJS)
	iverilog -s al_accel_elw_unit_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_elw_unit_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_elw_unit_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_elw_unit_tb.*

### al_accel_cp_unit ##
sim_al_accel_cp_unit_tb: al_accel_cp_unit_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_cp_unit_tb.log

al_accel_cp_unit_tb.vvp: $(ACCEL_TB_DIR)/al_accel_cp_unit_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_cp_unit.v
	iverilog -s al_accel_cp_unit_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_cp_unit_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_cp_unit_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_cp_unit_tb.*	

### al_accel_config_regs ##
sim_al_accel_config_regs_tb: al_accel_config_regs_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_config_regs_tb.log

al_accel_config_regs_tb.vvp: $(ACCEL_TB_DIR)/al_accel_config_regs_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_config_regs.v
	iverilog -s al_accel_config_regs_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_config_regs_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_config_regs_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_config_regs_tb.*	

### al_accel_act_func_unit ##
sim_al_accel_act_func_unit_tb: al_accel_act_func_unit_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_act_func_unit_tb.log

al_accel_act_func_unit_tb.vvp: $(ACCEL_TB_DIR)/al_accel_act_func_unit_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_act_func_unit.v
	iverilog -s al_accel_act_func_unit_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_act_func_unit_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_act_func_unit_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_act_func_unit_tb.*	

### al_accel_quant_unit ##
sim_al_accel_quant_unit_tb: al_accel_quant_unit_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_quant_unit_tb.log

al_accel_quant_unit_tb.vvp: $(ACCEL_TB_DIR)/al_accel_quant_unit_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_quant_unit.v
	iverilog -s al_accel_quant_unit_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_quant_unit_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_quant_unit_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_quant_unit_tb.*

### al_accel_acc_matrix ##
sim_al_accel_acc_matrix_tb: al_accel_acc_matrix_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_acc_matrix_tb.log

al_accel_acc_matrix_tb.vvp: $(ACCEL_TB_DIR)/al_accel_acc_matrix_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_acc_matrix.v
	iverilog -s al_accel_acc_matrix_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_acc_matrix_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_acc_matrix_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_acc_matrix_tb.*


### al_accel_wreg ##
sim_al_accel_wreg_tb: al_accel_wreg_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_wreg_tb.log

al_accel_wreg_tb.vvp: $(ACCEL_TB_DIR)/al_accel_wreg_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_wreg.v
	iverilog -s al_accel_wreg_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_wreg_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_wreg_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_wreg_tb.*\

### al_accel_ireg ##
sim_al_accel_ireg_tb: al_accel_ireg_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_ireg_tb.log

al_accel_ireg_tb.vvp: $(ACCEL_TB_DIR)/al_accel_ireg_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_ireg.v
	iverilog -s al_accel_ireg_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_ireg_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_ireg_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_ireg_tb.*\

### al_accel_mac ##
sim_al_accel_mac_tb: al_accel_mac_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_mac_tb.log

al_accel_mac_tb.vvp: $(ACCEL_TB_DIR)/al_accel_mac_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_mac.v
	iverilog -s al_accel_mac_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_mac_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_mac_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_mac_tb.*\

### al_accel_lut ##
sim_al_accel_lut_tb: al_accel_lut_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_lut_tb.log

al_accel_lut_tb.vvp: $(ACCEL_TB_DIR)/al_accel_lut_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_lut.v
	iverilog -s al_accel_lut_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_lut_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_lut_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_lut_tb.*\

### al_accel_obuf ##
sim_al_accel_obuf_tb: al_accel_obuf_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_obuf_tb.log

al_accel_obuf_tb.vvp: $(ACCEL_TB_DIR)/al_accel_obuf_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_obuf.v
	iverilog -s al_accel_obuf_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_obuf_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_obuf_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_obuf_tb.*\

### al_accel_bpbuf ##
sim_al_accel_bpbuf_tb: al_accel_bpbuf_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_bpbuf_tb.log

al_accel_bpbuf_tb.vvp: $(ACCEL_TB_DIR)/al_accel_bpbuf_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_bpbuf.v
	iverilog -s al_accel_bpbuf_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_bpbuf_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_bpbuf_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_bpbuf_tb.*\

### al_accel_wbuf ##
sim_al_accel_wbuf_tb: al_accel_wbuf_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_wbuf_tb.log

al_accel_wbuf_tb.vvp: $(ACCEL_TB_DIR)/al_accel_wbuf_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_wbuf.v
	iverilog -s al_accel_wbuf_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_wbuf_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_wbuf_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_wbuf_tb.*\

### al_accel_ibuf ##
sim_al_accel_ibuf_tb: al_accel_ibuf_tb.vvp
	vvp -N $(ACCEL_TB_DIR)/$< > $(ACCEL_LOG_DIR)/al_accel_ibuf_tb.log

al_accel_ibuf_tb.vvp: $(ACCEL_TB_DIR)/al_accel_ibuf_tb.v $(ACCEL_HDL_OBJS_DIR)/al_accel_ibuf.v
	iverilog -s al_accel_ibuf_tb -o $(ACCEL_TB_DIR)/$@ $^ 

clean_al_accel_ibuf_tb: 
	rm -vrf \
		$(ACCEL_TB_DIR)/al_accel_ibuf_tb.vvp \
		$(ACCEL_LOG_DIR)/al_accel_ibuf_tb.*\

## This is for demo and have no effect on the project
# test_demo: testbench/accelerator_tb/demo_tb 
# 	./testbench/accelerator_tb/demo_tb +vcd

# testbench/accelerator_tb/demo_tb: source/accelerator_source/demo.v testbench/accelerator_tb/demo_tb.cc
# 	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module demo source/accelerator_source/demo.v demo_tb.cc \
# 			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir testbench/accelerator_tb/demo_tb_dir
# 	$(MAKE) -C testbench/accelerator_tb/demo_tb_dir -f Vdemo.mk
# 	cp testbench/accelerator_tb/demo_tb_dir/Vdemo testbench/accelerator_tb/demo_tb

# clean_demo: 
# 	rm -vrf \
# 		testbench/accelerator_tb/demo_tb testbench/accelerator_tb/demo_tb_dir \
# 		out_log/demo* 
####

######################################################################################################################
###################################################### TEST CPU ######################################################
######################################################################################################################
# Test mode code
test_ica: testbench/cpu_tb/ica_tb.vvp firmware/cpu_firmware/firmware.hex
	$(VVP) -N $< +firmware=firmware/cpu_firmware/firmware.hex > out_log/out.log

test_ica_vcd: testbench/cpu_tb/ica_tb.vvp firmware/cpu_firmware/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror +firmware=firmware/cpu_firmware/firmware.hex

test_ica_wb: testbench/cpu_tb/ica_tb_wb.vvp firmware/cpu_firmware/firmware.hex
	$(VVP) -N $< +firmware=firmware/cpu_firmware/firmware.hex

test_ica_wb_vcd: testbench/cpu_tb/ica_tb_wb.vvp firmware/cpu_firmware/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror +firmware=firmware/cpu_firmware/firmware.hex

test_ica_ez: testbench/cpu_tb/ica_tb_ez.vvp
	$(VVP) -N $<

test_ica_ez_vcd: testbench/cpu_tb/ica_tb_ez.vvp
	$(VVP) -N $< +vcd

test_ica_axi: testbench/cpu_tb/ica_tb.vvp firmware/cpu_firmware/firmware.hex
	$(VVP) -N $< +axi_test +firmware=firmware/cpu_firmware/firmware.hex

test_ver: testbench/cpu_tb/ver_tb firmware/cpu_firmware/firmware.hex
	./testbench/cpu_tb/ver_tb +firmware=firmware/cpu_firmware/firmware.hex

test_ver_vcd: testbench/cpu_tb/ver_tb firmware/cpu_firmware/firmware.hex
	./testbench/cpu_tb/ver_tb +vcd +trace +noerror +firmware=firmware/cpu_firmware/firmware.hex

# Testbench code
testbench/cpu_tb/ica_tb.vvp: testbench/cpu_tb/testbench.v source/picorv32.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

testbench/cpu_tb/ica_tb_wb.vvp: testbench/cpu_tb/testbench_wb.v source/picorv32.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

testbench/cpu_tb/ica_tb_ez.vvp: testbench/cpu_tb/testbench_ez.v source/picorv32.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

testbench/cpu_tb/ver_tb: testbench/cpu_tb/testbench.v source/picorv32.v testbench/cpu_tb/testbench.cc
	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module picorv32_wrapper testbench/cpu_tb/testbench.v source/picorv32.v testbench.cc \
			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir testbench/cpu_tb/ver_tb_dir
	$(MAKE) -C testbench/cpu_tb/ver_tb_dir -f Vpicorv32_wrapper.mk
	cp testbench/cpu_tb/ver_tb_dir/Vpicorv32_wrapper testbench/cpu_tb/ver_tb

# testbench/cpu_tb/ver_tb_wb: testbench/cpu_tb/testbench_wb.v source/picorv32.v testbench/cpu_tb/testbench.cc
# 	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module picorv32 testbench/cpu_tb/testbench_wb.v source/picorv32.v testbench.cc \
# 			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir testbench/cpu_tb/ver_tb_wb_dir
# 	$(MAKE) -C testbench/cpu_tb/ver_tb_wb_dir -f Vpicorv32.mk
# 	cp testbench/cpu_tb/ver_tb_wb_dir/Vpicorv32 testbench/cpu_tb/ver_tb_wb

# Prepare resources code
# Compile from C and Assembly to .hex file
firmware/cpu_firmware/firmware.hex: firmware/cpu_firmware/firmware.bin tools/makehex.py
	$(PYTHON) $(TOOL_DIR)/makehex.py $< $(NWORDS) > $@


firmware/cpu_firmware/firmware.bin: firmware/cpu_firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/cpu_firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/cpu_firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/cpu_firmware/sections.lds,-Map,firmware/cpu_firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

firmware/cpu_firmware/start.o: firmware/cpu_firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

firmware/cpu_firmware/%.o: firmware/cpu_firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

toolchain_test/%.o: toolchain_test/%.S toolchain_test/riscv_test.h toolchain_test/test_macros.h
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

####################################################################################################################################

## Tool chain make code
download-tools:
	sudo bash -c 'set -ex; mkdir -p /var/cache/distfiles; $(GIT_ENV); \
	$(foreach REPO,riscv-gnu-toolchain riscv-binutils-gdb riscv-gcc riscv-glibc riscv-newlib, \
		if ! test -d /var/cache/distfiles/$(REPO).git; then rm -rf /var/cache/distfiles/$(REPO).git.part; \
			git clone --bare https://github.com/riscv/$(REPO) /var/cache/distfiles/$(REPO).git.part; \
			mv /var/cache/distfiles/$(REPO).git.part /var/cache/distfiles/$(REPO).git; else \
			(cd /var/cache/distfiles/$(REPO).git; git fetch https://github.com/riscv/$(REPO)); fi;)'

define build_tools_template
build-$(1)-tools:
	@read -p "This will remove all existing data from $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)$(subst riscv32,,$(1)). Type YES to continue: " reply && [[ "$$$$reply" == [Yy][Ee][Ss] || "$$$$reply" == [Yy] ]]
	sudo bash -c "set -ex; rm -rf $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)$(subst riscv32,,$(1)); mkdir -p $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)$(subst riscv32,,$(1)); chown $$$${USER}: $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)$(subst riscv32,,$(1))"
	+$(MAKE) build-$(1)-tools-bh

build-$(1)-tools-bh:
	+set -ex; $(GIT_ENV); \
	if [ -d /var/cache/distfiles/riscv-gnu-toolchain.git ]; then reference_riscv_gnu_toolchain="--reference /var/cache/distfiles/riscv-gnu-toolchain.git"; else reference_riscv_gnu_toolchain=""; fi; \
	if [ -d /var/cache/distfiles/riscv-binutils-gdb.git ]; then reference_riscv_binutils_gdb="--reference /var/cache/distfiles/riscv-binutils-gdb.git"; else reference_riscv_binutils_gdb=""; fi; \
	if [ -d /var/cache/distfiles/riscv-gcc.git ]; then reference_riscv_gcc="--reference /var/cache/distfiles/riscv-gcc.git"; else reference_riscv_gcc=""; fi; \
	if [ -d /var/cache/distfiles/riscv-glibc.git ]; then reference_riscv_glibc="--reference /var/cache/distfiles/riscv-glibc.git"; else reference_riscv_glibc=""; fi; \
	if [ -d /var/cache/distfiles/riscv-newlib.git ]; then reference_riscv_newlib="--reference /var/cache/distfiles/riscv-newlib.git"; else reference_riscv_newlib=""; fi; \
	rm -rf riscv-gnu-toolchain-$(1); git clone $$$$reference_riscv_gnu_toolchain https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-$(1); \
	cd riscv-gnu-toolchain-$(1); git checkout $(RISCV_GNU_TOOLCHAIN_GIT_REVISION); \
	git submodule update --init $$$$reference_riscv_binutils_gdb riscv-binutils; \
	git submodule update --init $$$$reference_riscv_binutils_gdb riscv-gdb; \
	git submodule update --init $$$$reference_riscv_gcc riscv-gcc; \
	git submodule update --init $$$$reference_riscv_glibc riscv-glibc; \
	git submodule update --init $$$$reference_riscv_newlib riscv-newlib; \
	mkdir build; cd build; ../configure --with-arch=$(2) --prefix=$(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)$(subst riscv32,,$(1)); make

.PHONY: build-$(1)-tools
endef

$(eval $(call build_tools_template,riscv32i,rv32i))
$(eval $(call build_tools_template,riscv32ic,rv32ic))
$(eval $(call build_tools_template,riscv32im,rv32im))
$(eval $(call build_tools_template,riscv32imc,rv32imc))

build-tools:
	@echo "This will remove all existing data from $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)i, $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)ic, $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)im, and $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX)imc."
	@read -p "Type YES to continue: " reply && [[ "$$reply" == [Yy][Ee][Ss] || "$$reply" == [Yy] ]]
	sudo bash -c "set -ex; rm -rf $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX){i,ic,im,imc}; mkdir -p $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX){i,ic,im,imc}; chown $${USER}: $(RISCV_GNU_TOOLCHAIN_INSTALL_PREFIX){i,ic,im,imc}"
	+$(MAKE) build-riscv32i-tools-bh
	+$(MAKE) build-riscv32ic-tools-bh
	+$(MAKE) build-riscv32im-tools-bh
	+$(MAKE) build-riscv32imc-tools-bh

toc:
	gawk '/^-+$$/ { y=tolower(x); gsub("[^a-z0-9]+", "-", y); gsub("-$$", "", y); printf("- [%s](#%s)\n", x, y); } { x=$$0; }' README.md

ica_clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/cpu_firmware/firmware.elf firmware/cpu_firmware/firmware.bin firmware/cpu_firmware/firmware.hex firmware/cpu_firmware/firmware.map \
		testbench/cpu_tb/ica_tb*.vvp \
		out_log/ica_tb*\

ver_clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/cpu_firmware/firmware.elf firmware/cpu_firmware/firmware.bin firmware/cpu_firmware/firmware.hex firmware/cpu_firmware/firmware.map \
		testbench/cpu_tb/ver_tb testbench/cpu_tb/ver_tb_dir \
		out_log/ver_tb*\

clean: 
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/cpu_firmware/firmware.elf firmware/cpu_firmware/firmware.bin firmware/cpu_firmware/firmware.hex firmware/cpu_firmware/firmware.map \
		testbench/cpu_tb/ica_tb*.vvp \
		testbench/cpu_tb/ver*_tb testbench/cpu_tb/ver_tb*_dir \
		out_log/ver_tb* out_log/ica_tb*\

# clean:
# 	rm -rf riscv-gnu-toolchain-riscv32i riscv-gnu-toolchain-riscv32ic \
# 		riscv-gnu-toolchain-riscv32im riscv-gnu-toolchain-riscv32imc
# 	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) check.smt2 check.vcd synth.v synth.log \
# 		firmware/firmware.elf firmware/firmware.bin firmware/firmware.hex firmware/firmware.map \
# 		ica_tb.vvp testbench_sp.vvp testbench_synth.vvp testbench_ez.vvp \
# 		testbench_rvf.vvp testbench_wb.vvp testbench.vcd testbench.trace \
# 		ver_tb ver_tb_dir

.PHONY: test test_vcd test_sp test_axi test_wb test_wb_vcd test_ez test_ez_vcd test_synth download-tools build-tools toc clean
