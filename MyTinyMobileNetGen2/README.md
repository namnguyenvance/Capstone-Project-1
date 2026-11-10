# TinyMobileNet Gen 2

Gen 1 lives in `../MyTinyMobileNetSoC/` as the frozen reference baseline.
The frozen Git tag is `gen1-final`; its historical tree retains the original
`RISCVAIoT/MyTinyMobileNetSoC/` path. Do not change the tag or Gen 1 behavior.

Gen 2 lives in `MyTinyMobileNetGen2/` at the repository root. Its initial goal
is RGB CIFAR-10 support first, followed by DMA/local-buffer based data movement.
The current milestone is repository organization and architecture planning only.
No Gen 2 functionality is implemented here.

## Layout

- `docs/Gen2_RGB_DMA_Plan.md`: architecture planning and open questions.
- `model/training/`, `model/quantization/`, `model/generated/`: future workload tools and outputs.
- `software/firmware/`, `software/reference/`, `software/common/`: future firmware, reference checks, and shared definitions.
- `rtl/soc/`, `rtl/conv/`, `rtl/depthwise/`, `rtl/pointwise/`, `rtl/quant/`, `rtl/memory/`: future hardware sources.
- `sim/tb/`, `sim/vectors/`, `sim/scripts/`: future simulation and verification.
- `fpga/zcu106/`: future board integration.
- `scripts/`: future project helpers.

## Reuse and independence

Gen 2 derives ideas and components from Gen 1 but must evolve independently
without modifying Gen 1 behavior. No Gen 1 files are copied at this milestone.
Future candidates to review and copy deliberately include PicoRV32, UART,
MMIO accelerator patterns, quantization routines, startup/linker code,
native reference and focused RTL tests, and ZCU106 constraints/build flows.
Review interfaces, arithmetic assumptions, memory sizes, and licensing before reuse.
Gen 1 MNIST weights, datasets, generated binaries, evaluation results, and
FPGA reports stay in Gen 1; RGB model assets require a separate validated baseline.

## Non-goals for now

YOLO, camera, PetaLinux, INT4, a large PE array, a compiler/runtime framework,
and full DMA implementation are outside this milestone.
