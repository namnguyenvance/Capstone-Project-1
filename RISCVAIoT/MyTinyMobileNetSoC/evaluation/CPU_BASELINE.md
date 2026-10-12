# Matched RV32 CPU-only baseline

Run from the repository root:

```sh
python3 RISCVAIoT/MyTinyMobileNetSoC/evaluation/run_cpu_baseline.py \
  --output /tmp/tmn_cpu_baseline
```

Requires the existing `riscv32-unknown-elf-*` toolchain, Verilator with timing
support, and its host C++ build tools. No Python ML dependencies are needed.
The output directory contains firmware ELF/hex/disassembly, build logs, source
hashes in `results.json`, tool versions, and the complete UART simulation log.
Production firmware, dataset headers, RTL, models, and Vivado files are untouched.

## Definition and accelerator audit

The baseline compiles the existing firmware entry and inference orchestration
with `-DNATIVE_RUN -DTINYMOBILENET_TEST_COUNT=1`. This selects existing generic C
convolution/depthwise kernels and the existing software quantizer. GAP and FC
already perform their accumulations on the CPU. All tensors, model parameters,
CHW layout, offsets, activation bounds, and embedded image 0 (label 7) are shared.
The flags remain `-mabi=ilp32 -march=rv32im -ffreestanding -nostdlib -O2`.
CPU MUL/MULH instructions are allowed; “CPU-only” excludes peripheral compute.
The unchanged SoC retains its accelerators, but a simulation assertion forbids
accesses to any of their MMIO windows, including the standalone multiplier.

The Level 6 path offloads Conv0 to the convolution accelerator; DW1 and DW2 to
the depthwise accelerator; PW1 to the cached pointwise path; and PW2/PW3 to its
batch path. DW3 accumulates on CPU. Requantization in every layer, including GAP
and FC, uses the quantizer peripheral. The standalone multiply peripheral is
not used by the inference code.

## Measurement and correctness limits

One integrated simulation executes the original testbench using Verilator.
A generated copy in the output directory adds only passive counter observations
and the no-compute-MMIO assertion. There are no extra measurement instructions.
The runner checks all UART timings against the observed CSR sampling points.
Layer timing excludes its UART messages; total timing includes inter-layer UART,
matching the historical Level 6 definition (26,523,121 cycles). PicoRV32's
`count_instr` is sampled at the same boundaries. It increments at instruction
decode; call this the CPU instruction counter rather than independently proven
architectural retirement. Both paths use the same CPU configuration, shared
256 KiB RAM, linker, clock, and UART.

The software high multiply divides the nudged signed product by 2^31 using C
truncation toward zero. RTL uses an arithmetic right shift (floor for negative
values). Saturation handling also differs. Matching final scores on this image
does not establish quantizer equivalence, RTL equivalence for all images, or
RTL/TFLite bit-exactness. This is an existing generic software reference baseline,
not an optimized CPU library. Its speedup includes software scheduling/kernel
optimizations present in Level 6 as well as accelerator offload. It is suitable
for a thesis comparison if these qualifications are stated.

The Level 6 count is a previously verified result, not a newly simulated matched
binary. Record the historical build/toolchain identity when presenting it; a
compiler or reporting-code change may affect a strict contemporary comparison.

## Measured result

With RV32 GCC 16.1.0 (g6afcc4f6d) and Verilator 5.051
(v5.050-308-gc917f04c6), the single-image run produced:

| Layer | CPU-only cycles | CPU instruction-counter delta |
|---|---:|---:|
| Conv0 | 20,981,493 | 3,351,328 |
| DW1 | 22,730,212 | 3,675,953 |
| PW1 | 98,107,436 | 17,542,816 |
| DW2 | 11,340,527 | 1,834,666 |
| PW2 | 68,239,410 | 12,297,432 |
| DW3 | 4,185,933 | 680,919 |
| PW3 | 33,231,369 | 6,005,512 |
| GAP | 206,696 | 41,289 |
| FC | 53,940 | 5,881 |
| Total including inter-layer UART | **259,218,212** | **45,455,905** |

The historical Level 6 comparison gives **9.7733x** speedup.
Prediction and expected label are both 7. Final scores are
`[7, 33, -13, -27, 19, 1, -43, 115, -44, 45]`, matching both the host native
reference and historical Level 6 scores for this image. No compute-MMIO access
or CPU trap occurred. All ten UART cycle measurements match passive CSR samples.
Firmware text/data/BSS occupy 147,164 bytes in total (before stack space).
