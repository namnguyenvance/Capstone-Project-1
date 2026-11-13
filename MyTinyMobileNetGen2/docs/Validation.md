# Gen 2 model validation records

## Promoted reference — 2026-11-13

Active version **gen2b-cifar10-a59-int8-v1** uses A's validation-selected
epoch-59 checkpoint. Full-test Float32/INT8 accuracies are **61.72%/61.30%**.
The complete bundle is now Git-deliverable under model/references, with a
pinned immutable manifest and no ignored model/data dependency. Original
30-epoch and both 60-epoch experiment artifacts remain preserved.

Promotion checks PASS: full native/reference TFLite comparison (all
932,580,000 elements equal, max error 0, 100% prediction agreement), exact
re-export, offline native replay of all 10,000 recovered images, clean
Git-index checkout with CRLF conversion enabled, native replay from that
checkout, five frozen arithmetic tests, and five integrity failure-path tests.
See [promotion report](Gen2B_Model_Reference_Promotion.md) and
[checked-in verification JSON](validation/gen2b_reference_v1/native_tflite10000.json).
Complete firmware memory and RTL equivalence remain pending.

## Historical 30-epoch record (preserved below)

Date: 2026-11-10. Branch: `work/gen2-rgb-dma`. Existing implementation and
unit-test golden references reused without arithmetic or architecture changes.
Gen 1, thesis files and RTL untouched. No commits or pushes.

## Environment and training

Python 3.11.18; TensorFlow CPU 2.18.1; NumPy 2.0.2; Keras 3.15.1.
TensorFlow sees only CPU:0; GPU acceleration is unavailable.
The previous dependency blocker is resolved. Sandbox DNS initially blocked
the CIFAR download; approved execution downloaded the original Keras archive
successfully. Dataset shape assertions passed: train [50000,32,32,3],
test [10000,32,32,3]. No replacement dataset or grayscale conversion.

Actual Keras graph and TFLite graph both verify the requested shapes:
32²×3 → 32²×16 → 32²×16 → 32²×32 → 16²×32 → 16²×48 →
8²×48 → 8²×64 → 64 → 10. Parameter count: 7,322.
The endpoint is logits, without softmax, unchanged from the existing Gen 2 code.

Seed 2026; deterministic TensorFlow operations requested; seeded 45,000/5,000
training/validation permutation. RGB uint8 / 255 in NHWC. Adam 0.001,
30 epochs, batch 128, no augmentation. Threads: intra-op 4, inter-op 2, OMP 4.
Training runtime 520.137 seconds, including validation and checkpoints;
dataset download/loading 1,389.558 seconds separately. Final-epoch artifact
is used, with a separate best-validation checkpoint retained.

| Metric | Actual value |
|---|---:|
| Final training accuracy | 56.2867% |
| Final validation accuracy | 55.7400% |
| Float test accuracy | 55.96% (5596/10000) |
| Float test loss | 1.220976 |
| INT8 test accuracy | 55.93% (5593/10000) |
| Float minus INT8 | 0.03 percentage points |
| Float/INT8 prediction agreement | 96.54% (9654/10000) |

Float+INT8 evaluation runtime: 24.284 seconds, excluding dataset/model load.
Accuracy is modest; no architecture modifications were made to raise it.
Future separately recorded experiments may try a learning-rate schedule,
longer training and mild augmentation.

## Actual INT8 inspection and export

Calibrated on 500 seeded training images, with indices recorded. TFLite file:
19,824 bytes. Operators are exactly CONV_2D, DEPTHWISE_CONV_2D, CONV_2D,
DEPTHWISE_CONV_2D, CONV_2D, DEPTHWISE_CONV_2D, CONV_2D, MEAN,
FULLY_CONNECTED. All tensors are INT8 or INT32; biases and the reduction-axis
constant are INT32. Input/output are INT8. All weight/bias zero points are 0.
All convolution and FC weights have per-output-channel scales. Bias scales
were checked against input scale × weight scale. Exported weights use
OIHW (Conv), CHW (DW), OI (FC); activations are converted NHWC→CHW.

| Activation endpoint | Scale | Zero point |
|---|---:|---:|
| RGB input | 0.0039215688593685627 | -128 |
| Conv0 | 0.023529412224888802 | -128 |
| DW1 | 0.023521823808550835 | -128 |
| PW1 | 0.023529412224888802 | -128 |
| DW2 | 0.023529412224888802 | -128 |
| PW2 | 0.023529412224888802 | -128 |
| DW3 | 0.023529412224888802 | -128 |
| PW3 | 0.023529412224888802 | -128 |
| GAP | 0.020410770550370216 | -128 |
| FC logits | 0.069691896438598633 | 43 |

Channel-specific metadata summary (full arrays and bias scales in export.json):

| Layer | Channels | Weight scale min–max | Multiplier min–max | Shift min–max |
|---|---:|---|---|---|
| Conv0 | 16 | 0.00131435832–0.008669898845 | 1091966507–2132519338 | 9–12 |
| DW1 | 16 | 0.001012578374–0.01152986195 | 1113700873–1933649665 | 6–9 |
| PW1 | 32 | 0.002682728926–0.01681550592 | 1155180093–2106808447 | 5–8 |
| DW2 | 32 | 0.0008906347211–0.009332290851 | 1078833152–2112098432 | 6–10 |
| PW2 | 48 | 0.001898594317–0.02011897974 | 1093016064–2087526528 | 5–9 |
| DW3 | 48 | 0.0006307473523–0.007158222608 | 1080066304–2128139520 | 7–10 |
| PW3 | 64 | 0.002022087108–0.01813880727 | 1074104448–2075439232 | 5–8 |
| FC | 10 | 0.005653912667–0.01157210395 | 1309387128–2119335541 | 8–9 |

Positive shift means right shift, negative shift means saturating left shift.
Native requantization arithmetic and rounding contract are unchanged; see plan.
Full weights, INT32 biases, scales/zero points, multipliers, shifts, activation
limits, layer order, tensor IDs/shapes, strides and padding were exported.
`model_data.c` compiles with `-Wall -Wextra -Wconversion -Werror`.

## Native numerical results

First 100 test images: native/TFLite label accuracy 57%, prediction agreement
100%, all 100 logit vectors exact, all compared layer elements exact; 2.093 seconds.
Full 10,000 test images: native/TFLite label accuracy 55.93%, prediction agreement
100%, all 10,000 logit vectors exact; 162.000 seconds. Across nine layer outputs,
932,580,000 / 932,580,000 INT8 elements match; maximum absolute difference is 0
for every layer. Native inputs and constants came from the actual exported
model, not synthetic model parameters. No golden reference or kernel arithmetic
was changed to obtain this result.

| Layer | Compared elements (full test set) | Equal elements | Max abs error |
|---|---:|---:|---:|
| Conv0 | 163,840,000 | 163,840,000 | 0 |
| DW1 | 163,840,000 | 163,840,000 | 0 |
| PW1 | 327,680,000 | 327,680,000 | 0 |
| DW2 | 81,920,000 | 81,920,000 | 0 |
| PW2 | 122,880,000 | 122,880,000 | 0 |
| DW3 | 30,720,000 | 30,720,000 | 0 |
| PW3 | 40,960,000 | 40,960,000 | 0 |
| GAP | 640,000 | 640,000 | 0 |
| FC | 100,000 | 100,000 | 0 |

Prediction agreement measures argmax equality; accuracy compares argmax
against labels. Numerical equality compares actual INT8 tensor elements.
These measurements establish no universal arithmetic, optimization or RTL
equivalence. Reference target is TensorFlow 2.18.1 BUILTIN_REF, no delegates.

## Memory

Actual exported weights: 7,056 bytes; INT32 biases: 1,064; channel
multipliers/shifts: 2,128; GAP multiplier/shift: 8. Numeric model payload:
10,256 bytes. Generated C object read-only sections occupy 10,384 bytes,
including host alignment, excluding GAP metadata/descriptors. TFLite's 19,824
bytes are an alternative representation, not an additional required copy.

Input: 3,072 bytes; two planned fixed activation buffers: 65,536; separate
GAP/logits: 74. Combined numeric payload and buffers: **78,938 bytes**.
Remaining of 262,144: **183,206 bytes** before code, stack, alignment and
metadata descriptors. Peak adjacent tensor bytes: 49,152. No im2col scratch
is required by these kernels; optional trace buffers are host diagnostics.
The Python driver/TensorFlow interpreter retain much larger host allocations;
this payload budget does not describe host process RAM.

Complete RV32 firmware memory remains PENDING: no Gen 2 startup/linker,
firmware image or stack high-water measurement exists. A 32 KiB code plus
8 KiB stack reserve would give 119,898 bytes, but is illustrative only.
Measured x86 library text/data/bss = 4260/472/8 bytes; local stack frames:
Conv 232, mean/FC 80, requant 8 bytes. These do not establish RV32 size.
One image at a time and reused buffers are feasible without DDR/DMA.

## Checks and reproduction

Existing five unit tests PASS unchanged: 40 RGB outputs × four arithmetic
stages, 288 signed requantization cases, DW isolation/clamping, RGB layout,
multiplier edge handling, mean and FC. Same tests PASS under UBSan.
Python syntax checks, warnings-as-errors C build, generated constant build,
ignore probes and `git diff --check` pass. `git status --short` was inspected;
only Gen 2 source/documentation files are changed or untracked.

Run from `MyTinyMobileNetGen2/` using the existing venv:

```bash
export TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4
.venv/bin/python model/pipeline.py topology
.venv/bin/python model/pipeline.py train --seed 2026 --epochs 30 --batch-size 128
.venv/bin/python model/pipeline.py quantize --seed 2026 --calibration 500
.venv/bin/python model/pipeline.py evaluate --limit 10000
.venv/bin/python model/pipeline.py export
.venv/bin/python software/reference/test_rgb.py
cc -std=c11 -O2 -Wall -Wextra -Wconversion -Werror -c model/generated/model_data.c -o build/model_data.o
.venv/bin/python software/reference/verify_model.py --limit 100
.venv/bin/python software/reference/verify_model.py --limit 10000
.venv/bin/python scripts/memory_budget.py --export model/generated/export.json
.venv/bin/python -m compileall -q model software/reference scripts
git diff --check
git status --short
```

All datasets/checkpoints/models/logs/reports remain ignored under
`model/generated/`; build and venv directories are also ignored.
Installed package versions are captured in `environment.txt` using
`importlib.metadata` (this working venv lacks the pip module).
Small/full native reports have separate filenames to preserve sample evidence.
Rerunning training overwrites the fixed model filenames; archive a complete
run externally first. Artifact hashes bind comparisons to this run:

- Float SHA-256: `f452aab509ba5cd3bf06f207d3d6124b5db03824ac65ec0d01391852c9fadfb5`
- TFLite SHA-256: `d1544d1fad460bb0d0dda634a82fa963b4db3251ea7839b2543255f49d4c4729`
- Split SHA-256: `89ced88f01aedaa9db166a576b2a4eb11fc6597293619e835b1ba4c6e469ccdb`

## Final verification matrix

| Check | Status | Evidence |
|---|---|---|
| Actual Keras shapes / parameters | PASS | All shapes asserted, 7,322 parameters |
| CIFAR-10 loading / RGB layout | PASS | Original 50k/10k dataset, CHW checks |
| Reproducible setup / recorded training | PASS | Seed/split/config/thread settings/hashes recorded |
| Float full-test evaluation | PASS | 55.96% on 10,000 |
| Full INT8 conversion and metadata | PASS | INT8/INT32 only; actual graph inspected |
| INT8 full-test evaluation | PASS | 55.93% on 10,000 |
| Real parameter export and C compilation | PASS | Export validated, strict C compile |
| Original Python/C arithmetic tests | PASS | Five tests, unchanged fixture/oracle |
| UndefinedBehaviorSanitizer checks | PASS | Same five tests pass |
| Native vs TFLite, 100 images | PASS | Every layer exact, predictions 100% agreement |
| Native vs TFLite, 10,000 images | PASS | Every layer exact, predictions 100% agreement |
| Model/data payload accounting | PASS | 78,938 bytes including planned buffers |
| Complete 256 KiB firmware fit | PENDING | RV32 link map/stack/descriptors absent |
| Cross-build / optimized-delegate equivalence | PENDING | Not evaluated |
| RTL / DMA equivalence | PENDING | Outside Gen 2A; no implementation |
| Python syntax / warnings / whitespace | PASS | compileall, strict cc, diff --check |
| Ignore rules and scope | PASS | Model/cache/build ignored; only Gen 2 changes |

Recommended Gen 2B: bounded RGB Conv0 with three-channel OIHW accumulation,
input zero-point handling, INT32 sums, explicit CPU/accelerator ownership,
and the verified requantization contract. Use exported layer vectors and the
unchanged deterministic RGB fixture for arithmetic/reset/MMIO handshake
checks. Quantify firmware memory before making a complete-fit claim.
DMA remains a separate later design milestone. No RTL equivalence is claimed.
