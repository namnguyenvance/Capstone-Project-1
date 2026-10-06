# Repository Guidance

## Active target and architecture

The active TinyMobileNet target is `RISCVAIoT/MyTinyMobileNetSoC/`.
Use `TinyMobileNet_RISCV_SoC_Walkthrough.md` as architectural context;
verify details against current source.

The target contains PicoRV32, 256 KiB shared code/data RAM, UART, LEDs,
and five MMIO accelerators: multiply, 3×3 convolution, quantization,
depthwise convolution, and pointwise dot product.

The CPU loads accelerator registers and handles bias, output offsets,
clamping, and inference orchestration. Accelerators have no DMA interface.
DW stride-2, GAP, and FC use CPU arithmetic with hardware requantization.

## Directories

- Active RTL, testbench, firmware, model data, and ML scripts:
  `RISCVAIoT/MyTinyMobileNetSoC/`.
- Active RTL top: `my_soc.v`; simulation top: `tb.v`.
- Firmware entry: `start.s` → `main_tinymobilenet.c`.
- Firmware operations: `dl_ops.c`, `quantize.c`; linker: `sections.lds`.
- Separate legacy/reference projects: `RISCVAIoT/MyRISCVSoc/`,
  `RISCVAIoT/MyLeNet5SoC/`, `RISCVAIoT/SoC/SoCSource/`,
  `RISCVAIoT/DLCProgram/`, and `Thesis_RISCVCNN-main/`.

Do not treat legacy/reference modules as part of the active target or
modify them unless explicitly requested.

## Build and simulation

Run from `RISCVAIoT/MyTinyMobileNetSoC/`:

- `make firmware.hex`: build firmware and generate RAM image.
- `make sim.vvp`: compile RTL with Icarus Verilog.
- `make sim` or `make`: build and run simulation.
- `make pipeline`: train, extract model/test data, build, and simulate.
  Run serially; pipeline prerequisites do not enforce ordering under `-j`.
- `make clean`: remove generated firmware and simulation artifacts.

Native verification, when needed:

    cc -O2 -DNATIVE_RUN verify_native.c dl_ops.c quantize.c \
       tinymobilenet_model_data.c -o /tmp/tinymobilenet_verify
    /tmp/tinymobilenet_verify

Do not regenerate models, datasets, or checked-in binaries unnecessarily.
The Makefile omits some header/linker dependencies; ensure affected
artifacts are rebuilt when those files change.

## Toolchain and quantization

Firmware assumes `riscv32-unknown-elf-gcc` and `objcopy`, with
`-march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -O2`.
The CPU enables MUL but disables DIV/REM, compressed instructions, and IRQs.
Do not introduce instructions or runtime helpers unsupported by this setup.

Feature maps and weights are signed int8; feature maps use CHW layout.
Biases and accumulators are int32. Preserve tensor layouts, zero-point
offsets, per-channel convolution scaling, and the existing shift convention:
positive shifts mean right shift; negative shifts require a left shift.
MMIO operands occupy 32-bit registers.

Do not assume exact TFLite equivalence: current hardware/native rounding
differs for negative products, saturation handling is incomplete, firmware
uses full int8 activation bounds, and softmax is omitted.

## Synthesizable RTL rules

- Preserve MMIO addresses, register semantics, and bus handshakes unless
  an interface change is requested; update firmware alongside such changes.
- Use explicit widths and signedness; review overflow and truncation.
- Use nonblocking assignments for clocked state and complete combinational
  assignments to avoid unintended latches.
- Keep delays, testbench tasks, and simulation-only behavior out of
  synthesizable logic.
- Keep loops statically bounded and account for multiplier/adder timing.
- Preserve reset behavior; do not infer FPGA timing closure from simulation.

## Verification requirements

For RTL changes, compile with an explicit `tb` top and run focused checks
for affected arithmetic, reset, register access, and transaction behavior.
For firmware/model changes, rebuild firmware and run relevant native checks.
For inference or interface changes, run integrated simulation and compare
scores and predictions, not only LED completion.

Native checks do not validate accelerator arithmetic. Quantization changes
require signed edge-case checks and comparison with an independent reference.

Known baseline: target firmware runs one image but compares against 100,
so a correct prediction still produces LED `0xFF`. Total cycle timing
includes inter-layer UART output. Historical logs and binaries may be stale.

Report commands run, results, and any verification not completed.
