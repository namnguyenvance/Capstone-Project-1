# Gen 1 pipeline audit for Gen 2A

Inspected current Gen 1 sources read-only; architecture context:
`../../TinyMobileNet_RISCV_SoC_Walkthrough.md`. Current source takes precedence.
No Gen 1 assets, generated model parameters, results, firmware or RTL were copied.

| Area | Current source / finding | Gen 2 decision |
|---|---|---|
| Training | `train_model.py`: MNIST, reshape 28×28×1, divide by 255, Adam 0.001, 10 epochs, batch 64; test set doubles as validation; no explicit seed | Reuse separable topology/ReLU6 concepts; use CIFAR RGB, seeded disjoint train/validation, untouched test set |
| Conversion | Same script: first 200 training images calibrate INT8 TFLite, INT8 input/output | Use 500 seeded training images; keep full integer builtin restriction; inspect actual graph |
| Evaluation | Training script evaluates first 1,000 MNIST images; casts quantized inputs directly to int8 without rounding/clamping | Round and saturate inputs; evaluate 10,000 by default; record sample counts |
| Export | `generate_model_data.py`: fixed nine-layer execution ordering, positional tensor-detail indexing, Conv OHWI→OIHW, DW 1HWC→CHW | Reuse layout concepts, independently parse FlatBuffer options and tensor indices; reject unsupported graphs; preserve each channel's scales |
| Native inference | `verify_native.c`, `dl_ops.c`: CHW generic Conv/DW, fixed 28/14/7 shapes, two 28×28×32 buffers, GAP64, FC10 | Independent host kernels and graph-driven runner; fresh RGB weights required |
| Conv0 | Generic C sums over Cin with OIHW indexing; accelerated tile path in `dl_ops.c` has hardcoded 28, plane stride 784, single-channel tiles and dispatch guard Cin=1 | Do not transplant accelerated Conv0; RGB requires 27 products per output and explicit channel accumulation |
| Arithmetic | `quantize.c`: signed int64 multiply/nudge/division; overflow test uses INT32_MAX pair rather than INT32_MIN pair; `dl_ops.c` uses positive-right/negative-left shifts | Explicit bounded saturating Gen 2 host arithmetic; independently test signed edges; no assertion of Gen 1 hardware or TFLite equivalence |
| Activations | Firmware passes full [-128,127] bounds; generated output offsets do not establish fused ReLU6 bounds by themselves | Export actual fused activation and compute its INT8 limits |
| Dense | Exporter takes first weight multiplier for FC | Preserve/repeat per-tensor metadata or retain all per-channel multipliers |
| Integration | `start.s`→`main_tinymobilenet.c`; fixed layer calls, MNIST image/header/class names, CPU MMIO loads; `sections.lds` shares 256 KiB for code/data | Keep all integration deferred; Gen 2 kernels are host software, not RV32 firmware |
| Build | `Makefile` pipeline train→generate→extract→sim is serial-sensitive; generated header/linker dependency coverage incomplete | Gen 2 commands are explicit and sequential; no Gen 1 build run |
| Verification | `verify_native.c`, `evaluation/evaluate_mnist.py`, `evaluation/run_cpu_baseline.py`, `verify_pw_cache.py`, `verify_dw2_profile.py`, `verify_dw2_firmware.py`, focused C checks | Reuse staged verification principle; historical binaries/results are not evidence for Gen 2 |

Other MNIST assumptions include grayscale calibration and extraction,
`mnist_test_images.h`, digit class names, input Cin=1, fixed first-convolution
kernel shape [16,1,3,3], and fixed intermediate tensor sizes in firmware.
`extract_cifar_test.py` existing in Gen 1 does not establish an RGB training or
inference baseline. Gen 1's one-image firmware run versus 100-image denominator
is also unsuitable as a Gen 2 correctness criterion.

Reusable architectural concepts: depthwise separable layers, CHW planes,
per-channel convolution quantization, CPU bias/offset/clamp orchestration,
focused arithmetic checks followed by integrated score comparisons. MMIO
protocols, quantization RTL, startup/linker code and board support need their
own review at a later hardware milestone. Accelerators have no DMA interface;
DW stride 2, GAP and FC currently use CPU arithmetic with hardware requantization.
