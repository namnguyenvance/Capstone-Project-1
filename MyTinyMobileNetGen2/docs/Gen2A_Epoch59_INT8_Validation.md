# Experiment A epoch 59: isolated INT8 validation

Completed 2026-11-13, branch `work/gen2-rgb-dma`. **PASS** for software model
validation. Recommend epoch 59 as the next versioned Gen 2B software/hardware
correctness reference, subject to an explicit later promotion decision.
The active reference was not replaced; all original baseline, A and B artifacts
are preserved. No Gen 1, Gen 2B RTL, DMA, architecture, kernel arithmetic or
existing validation evidence was changed. No commit or push.

## Source and reproducibility

Source: `model/experiments/constant60_seed2026/best.keras`, selected epoch 59,
not final.keras from epoch 60. The validator checks selection.json, result.json
and the checkpoint SHA-256, then copies the identical checkpoint into its fresh
output directory. Its full-test float evaluation reproduces the training record.

Output: `model/experiments/constant60_epoch59_int8/` (ignored by Git).
Python 3.11.18, TensorFlow CPU 2.18.1, NumPy 2.0.2, Keras 3.15.1; CPU only,
GPU unavailable. Threads: intra-op 4, inter-op 2, OMP 4; seed 2026;
TensorFlow deterministic operations requested. Installed packages, source
inventory, command line, branch/HEAD, versions and device names are recorded.

Calibration uses exactly the original 500 training indices, in their original
order, from model/generated/calibration.json. The validator asserts equality
to the first 500 examples of the seed-2026 training split and records both
the source-record hash and actual calibration sample-byte hash. RGB NHWC
uint8 is divided by 255 as float32; validation/test data are not used for
calibration. Conversion uses Optimize.DEFAULT, TFLITE_BUILTINS_INT8 and INT8
inference input/output. Existing exporter and native driver are reused unchanged;
only the candidate driver redirects IO and C compilation into the new directory.

Hashes:

- Selected/copied Float32 checkpoint: `bf561ec4d030d898d62c7630ca1816eb34cab64217ed7953aa86c1dff776ab6e`
- TFLite: `8779ca06e9dbf5611ccef247bd6b55eca6127ff0fbeea7ec67b94ac72c20a6c1`

`output_hashes.json` records generated artifact hashes; final_output_hashes.json
also covers the copied process log and the first hash manifest. Both omit their
own self-hash. Full process output is in validation_run.log. Failures would
preserve failure.json and reports; no validation failure occurred.

## Accuracy comparison

Each test accuracy below uses all 10,000 original CIFAR-10 test images.
Native prediction agreement is against that model's own reference TFLite,
not against the original baseline model's predictions.

| Metric | Original baseline epoch 30 | A selected epoch 59 |
|---|---:|---:|
| Float32 accuracy | 55.96% (5596/10000) | **61.72% (6172/10000)** |
| Float32 test loss | 1.220976 | 1.076588 |
| INT8 TFLite accuracy | 55.93% (5593/10000) | **61.30% (6130/10000)** |
| Float minus INT8 | 0.03 percentage points | 0.42 percentage points |
| Native C label accuracy | 55.93% | 61.30% |
| Native/TFLite prediction agreement | 100% | 100% |
| Exact output logit vectors | 10000/10000 | 10000/10000 |
| Equal layer output elements | 932580000/932580000 | 932580000/932580000 |
| Maximum layer absolute difference | 0 | 0 |
| Parameters | 7322 | 7322 |
| Nominal MACs/image | 1805952 | 1805952 |
| TFLite file size | 19824 bytes | 19824 bytes |

Float improvement is 5.76 percentage points; INT8 improvement is 5.37 points.
Quantization causes a larger drop than in the old model, but preserves most
of the improved float accuracy. Results are for this checkpoint and test set;
no additional training or accuracy tuning took place.

## Actual graph and quantization

The graph has exactly nine supported integer operators:
CONV_2D → DEPTHWISE_CONV_2D → CONV_2D → DEPTHWISE_CONV_2D → CONV_2D →
DEPTHWISE_CONV_2D → CONV_2D → MEAN → FULLY_CONNECTED.
Unsupported operators: **none**. There are no floating-point tensors.
Activations and weights are INT8; biases and reduction-axis constants are INT32.
Input/output shapes and quantization:

- Input [1,32,32,3], scale 0.003921568859368563, zero point -128, INT8.
- Output [1,10] logits, scale 0.07269071787595749, zero point 31, INT8.

| Layer | Output shape, batch omitted | Output scale | Zero point | Weight scale channels | Right shift range |
|---|---|---:|---:|---:|---|
| Conv0 | 32×32×16 | 0.023529412224888802 | -128 | 16 | 9–12 |
| DW1 | 32×32×16 | 0.023529412224888802 | -128 | 16 | 5–9 |
| PW1 | 32×32×32 | 0.023529412224888802 | -128 | 32 | 5–8 |
| DW2 | 16×16×32 | 0.023529412224888802 | -128 | 32 | 6–10 |
| PW2 | 16×16×48 | 0.023529412224888802 | -128 | 48 | 5–9 |
| DW3 | 8×8×48 | 0.023529412224888802 | -128 | 48 | 6–10 |
| PW3 | 8×8×64 | 0.023529412224888802 | -128 | 64 | 5–8 |
| GAP | 64 | 0.020606612786650658 | -128 | — | 5 |
| FC | 10 | 0.072690717875957489 | 31 | 10 | 8–8 |

Convolution and dense weights have genuine per-output-channel quantization
(16,16,32,32,48,48,64,10 scales). Weight/bias zero points are zero. Bias scales,
quantized axes, fused ReLU6 bounds, stride, padding, tensor shapes, layer order,
INT32 accumulation bounds and supported shift/multiplier ranges passed export
checks. GAP uses multiplier 1226039149, right shift 5. Full channel scales,
zero points, weights, biases, multipliers and shifts are in export.json;
numeric C arrays are in model_data.c/.h. The exported graph is sequential.

Layouts remain NHWC for TFLite, CHW for native activations, OIHW for Conv,
CHW for DW, OI for dense weights. Conv0 sums over all three RGB channels.
Rounding is unchanged: Q31 double rounding, high multiply ties toward positive
infinity, power-of-two division ties away from zero, saturating left shifts
for negative shifts, exported output offset and activation clamps.

New quantization metadata must accompany the new weights. In particular,
output scale/zero point changed from 0.06969189643859863/43 to
0.07269071787595749/31; old exported constants must not be mixed with this model.

## Native comparison

The 100-image gate ran first: native and TFLite label accuracy 62%, all 100
predictions and all compared tensors exact, max absolute difference 0,
2.064 seconds. Only after this passed did the driver run all 10,000 images.
Full comparison: 159.644 seconds, all predictions and tensors exact.
Float evaluation, conversion, export and full INT8 accuracy together took
31.699 seconds; total candidate validation was 204.194 seconds, excluding
initial protected-file inventory. Five existing arithmetic/layout tests pass.

| Layer | Compared/equal elements on full test set | Max absolute difference |
|---|---:|---:|
| Conv0 | 163,840,000 / 163,840,000 | 0 |
| DW1 | 163,840,000 / 163,840,000 | 0 |
| PW1 | 327,680,000 / 327,680,000 | 0 |
| DW2 | 81,920,000 / 81,920,000 | 0 |
| PW2 | 122,880,000 / 122,880,000 | 0 |
| DW3 | 30,720,000 / 30,720,000 | 0 |
| PW3 | 40,960,000 / 40,960,000 | 0 |
| GAP | 640,000 / 640,000 | 0 |
| FC | 100,000 / 100,000 | 0 |

Native testing uses the unchanged C kernels, compiled locally with C11 -O2
-Wall -Wextra -Wconversion -Werror. Generated constants also compile with
warnings as errors. Existing five Python/C tests use that candidate-local
library; no old native library is rebuilt or overwritten. Golden test inputs
and expected arithmetic were not modified.

Observed numerical equality is specific to this model, test inputs and
TensorFlow 2.18.1 BUILTIN_REF without delegates. It does not establish universal
requantization equality, optimized-delegate equivalence, or RTL equivalence.
Native label accuracy and prediction agreement are separate quantities.

## Memory

| Item | Bytes, both old and new model |
|---|---:|
| INT8 weights | 7056 |
| INT32 biases | 1064 |
| INT32 channel multipliers and shifts, plus GAP pair | 2136 |
| Numeric model payload | **10256** |
| One RGB input | 3072 |
| Two planned fixed activation buffers | 65536 |
| Separate GAP/logit buffers | 74 |
| Numeric payload plus planned buffers | **78938** |
| Remaining of 262144 bytes | **183206** |

Peak adjacent activation tensors total 49,152 bytes. Kernels require no
im2col buffer. Optional host trace buffers are not part of embedded inference.
The 19,824-byte TFLite container is an alternative storage format, not another
required copy alongside C arrays. C array host object read-only size is
10,384 bytes including alignment (excludes GAP pair/descriptors); host native
library text/data/bss is 4260/472/8 bytes. These are host measurements only.

Complete 256 KiB firmware fit remains **PENDING**: code, stack, alignment,
runtime descriptors and actual memory placement must be measured with a Gen 2
RV32 link map/stack analysis. Host Python/TensorFlow allocations are not the
embedded payload. No DDR or DMA capacity assumption is made.

## Preservation, commands and verification matrix

All 106 pre-existing non-venv Gen 2 files were SHA-256 inventoried, including
baseline datasets, model outputs, native build artifacts, documentation and
all A/B artifacts. protected_integrity.json reports unchanged=true, no changes,
removals or additions during validation. The baseline environment was not changed.
Existing active-reference paths and validation documentation were not updated.

From repository root, the executed validation command was:

```bash
set -o noclobber
TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4 PYTHONDONTWRITEBYTECODE=1 MyTinyMobileNetGen2/.venv/bin/python -B MyTinyMobileNetGen2/model/quantization/validate_candidate.py --output MyTinyMobileNetGen2/model/experiments/constant60_epoch59_int8 > /tmp/gen2a_a59_validation_20261113.log 2>&1
```

The full pipeline is orchestrated by this command, reusing the existing export,
quantization, evaluation, C kernels and native comparison code. It checks the
selected source hash and the original calibration indices, writes isolated
metadata, compiles candidate-local native objects, gates 100 then 10,000 native
images, and verifies preservation in a finally block. Exact C compiler argument
lists are recorded in build_commands.json. The temporary process log was then
copied without overwrite into validation_run.log. For a repeat, choose a fresh
output directory and log path; existing directories are deliberately rejected.
No training command is involved.

Other checks executed: AST syntax parsing of the new validator; size on the
generated C object and native library; git diff --check; git status --short;
git check-ignore for candidate model, metadata and binary paths.

| Check | Status |
|---|---|
| Correct selected epoch/hash; full float metric reproduced | PASS |
| Original ordered calibration samples and conventions | PASS |
| Nine supported integer operators, shapes, IO, quantization | PASS |
| Full 10000-image INT8 evaluation | PASS |
| Parameter export and strict C compilation | PASS |
| Existing five Python/C arithmetic/layout tests | PASS |
| 100-image native exactness gate | PASS |
| 10000-image prediction/tensor exactness | PASS |
| Actual tensor/model payload accounting | PASS |
| Protected baseline/A/B artifact integrity | PASS |
| Syntax, whitespace and ignore checks | PASS |
| Complete 256 KiB firmware fit | PENDING |
| RTL and optimized-delegate equivalence | PENDING / not claimed |
| Automatic reference replacement | Not performed |

## Recommendation

Promote this checkpoint as a **versioned Gen 2B model/software correctness
reference** when a promotion decision is explicitly made: it gains 5.37 INT8
accuracy points without changing topology, nominal MAC count or planned buffer
sizes, and passes full native/reference-TFLite numerical verification.
Keep the original baseline available as a regression reference. Promotion
must use this candidate's complete export/quantization bundle and hashes,
not only its .keras file. Reference RTL still needs arithmetic/reset/MMIO
transaction verification against these vectors once implemented. No reference
pointer was changed and no Gen 2B implementation was started.
