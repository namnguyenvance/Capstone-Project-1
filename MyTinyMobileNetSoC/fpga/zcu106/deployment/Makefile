SHELL := /bin/sh
.DEFAULT_GOAL := help

VIVADO_VERSION ?= 2024.1
VIVADO_ROOT ?= C:\Xilinx\Vivado\$(VIVADO_VERSION)
VIVADO_BAT ?= $(VIVADO_ROOT)\bin\vivado.bat
DEPLOY_DIR_WSL := $(CURDIR)
DEPLOY_DIR_WIN = $(shell wslpath -w "$(DEPLOY_DIR_WSL)" 2>/dev/null)
export VIVADO_BAT DEPLOY_DIR_WSL DEPLOY_DIR_WIN

.PHONY: help check smoke program clean
help:
	@printf '%s\n' 'WSL orchestration of Windows Vivado' \
	  'make check   - verify tools and input files' \
	  'make smoke   - build smoke bitstream in build/' \
	  'make program - program existing bitstream (connected ZCU106 required)' \
	  'make clean   - remove deployment build/ only' \
	  "Vivado: $$VIVADO_BAT" "Windows deployment path: $$DEPLOY_DIR_WIN"

check:
	@command -v cmd.exe >/dev/null || { echo 'ERROR: cmd.exe unavailable; enable WSL Windows interop.' >&2; exit 1; }
	@command -v wslpath >/dev/null || { echo 'ERROR: wslpath unavailable.' >&2; exit 1; }
	@test -n "$$DEPLOY_DIR_WIN" || { echo 'ERROR: deployment Windows path conversion failed.' >&2; exit 1; }
	@test -f "$$(wslpath -u "$$VIVADO_BAT")" || { echo "ERROR: Vivado batch file missing: $$VIVADO_BAT" >&2; exit 1; }
	@for input in run_smoke.tcl program.tcl zcu106_smoke_top.v zcu106_deployment.xdc; do \
	  test -f "$$input" || { echo "ERROR: missing $$input" >&2; exit 1; }; \
	done
	@cd "$$(dirname "$$(wslpath -u "$$VIVADO_BAT")")" && cmd.exe /D /C exit 0 || { echo 'ERROR: Windows interop failed.' >&2; exit 1; }
	@echo 'PASS: WSL tools, Windows Vivado path, and deployment inputs available.'

# pushd maps a UNC checkout to a temporary drive in this cmd.exe process.
# Launch inside build/ so startup logs and .Xil are isolated as well.
define run_vivado
printf '%s\r\n' '@echo off' 'setlocal' \
  "pushd \"$$DEPLOY_DIR_WIN\\build\" || exit /b 1" \
  "call \"$$VIVADO_BAT\" -mode batch -source ..\\$(1).tcl -log $(2).log -journal $(2).jou" \
  'set "vivado_result=%errorlevel%"' 'popd' 'exit /b %vivado_result%' > build/$(2)_wsl.cmd
	@(cd "$$(dirname "$$(wslpath -u "$$VIVADO_BAT")")" && cmd.exe /D /C call "$$DEPLOY_DIR_WIN\\build\\$(2)_wsl.cmd")
endef

smoke: check
	@mkdir -p build
	@$(call run_vivado,run_smoke,vivado)

# Deliberately do not depend on smoke: missing hardware never rebuilds the design.
# Vivado can return zero on an uncaught program.tcl error; inspect its log too.
program: check
	@test -f build/zcu106_smoke.bit || { echo 'ERROR: missing build/zcu106_smoke.bit; run make smoke first.' >&2; exit 1; }
	@$(call run_vivado,program,program) && \
	  awk '/^ERROR:/ {failed=1} END {exit failed}' build/program.log || { \
	  echo 'ERROR: programming failed; check build/program.log. A powered ZCU106 with Windows-visible USB/JTAG is required; target discovery failure without hardware is expected. The existing build is retained.' >&2; exit 1; }

clean:
	@rm -rf -- build
