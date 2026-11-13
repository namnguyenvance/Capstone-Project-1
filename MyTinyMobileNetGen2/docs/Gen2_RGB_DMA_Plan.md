# Gen 2A RGB software baseline and future DMA plan

## Active promoted reference

Gen 2B software golden model: **gen2b-cifar10-a59-int8-v1**, Experiment A
constant-rate 60-epoch run, validation-selected checkpoint epoch 59. Full-test
Float32 accuracy 61.72%, INT8/native 61.30%; native/reference TFLite exact on
all 10,000 predictions and 932,580,000 compared layer elements. Use
model/references/active.json and its manifest, not ignored experiment paths.
The bundle includes all models, weights, biases, per-channel metadata, source
contracts, full test inputs, calibration examples and golden vectors in ordinary
Git files. It is recoverable offline and verified in a clean Git-index checkout.
See [promotion report](Gen2B_Model_Reference_Promotion.md) for hashes/commands.

Topology remains the verified 7,322-parameter model, with 1,805,952 nominal
MACs/image. Model payload plus planned buffers remains 78,938 bytes; complete
firmware fit, RTL transaction behavior and timing are unverified. No Gen 2B
RTL or DMA was implemented by this promotion. New RTL verification must use
the versioned CHW/OIHW vectors and that version's quantization parameters.
The following historical 30-epoch metrics/exports remain archival evidence;
they are not the active model constants.

## Status and evidence

The existing independent software pipeline now runs in Python 3.11.18,
TensorFlow 2.18.1 and NumPy 2.0.2. Actual Keras topology, CIFAR-10 loading,
30-epoch CPU training, full-test float/INT8 evaluation, conversion and real
parameter export succeeded on 2026-11-10. GPU acceleration is unavailable:
TensorFlow exposes only CPU:0. The original environment blocker is resolved;
the first dataset attempt hit sandbox DNS restrictions, then the approved
retry downloaded and validated the original Keras CIFAR-10 archive.
See [Validation.md](Validation.md) for numerical evidence and the final matrix.

Gen 1 (`../MyTinyMobileNetSoC/`, frozen tag `gen1-final`) remains read-only.
See [the source audit](Gen1_Pipeline_Audit.md) for specific assumptions and reuse.
No Gen 2 RTL, firmware, DMA or board integration has been implemented.

## Topology and tensor layouts

The implemented Keras builder uses exactly the requested widths and strides.
All listed shapes were verified against the actual Keras graph and again
against the converted TFLite graph. `architecture.json` records the actual
shapes and 7,322 parameters. Training repeated these assertions.

| Layer | Kernel / stride | Verified H×W×C (batch omitted) | Parameters including bias |
|---|---|---|---:|
| RGB input | — | 32×32×3 | 0 |
| Conv0 + ReLU6 | 3×3 / 1 SAME | 32×32×16 | 448 |
| DW1 + ReLU6 | 3×3 / 1 SAME | 32×32×16 | 160 |
| PW1 + ReLU6 | 1×1 / 1 SAME | 32×32×32 | 544 |
| DW2 + ReLU6 | 3×3 / 2 SAME | 16×16×32 | 320 |
| PW2 + ReLU6 | 1×1 / 1 SAME | 16×16×48 | 1,584 |
| DW3 + ReLU6 | 3×3 / 2 SAME | 8×8×48 | 480 |
| PW3 + ReLU6 | 1×1 / 1 SAME | 8×8×64 | 3,136 |
| Spatial mean | axes H,W | 64 | 0 |
| Dense logits | 64→10 | 10 | 650 |
| Total | | | **7,322** |

Output is ten logits: softmax is deliberately omitted, matching Gen 1's
native scoring endpoint and preserving argmax while avoiding another native
kernel. Float and INT8 models both use this same endpoint. This is not a
claim of equivalence to Gen 1's softmax output values.

Keras inputs are NHWC with channel order R,G,B and no grayscale conversion.
Host C uses CHW: `x[(c*H+y)*W+x]`. Convert a batch with
`transpose(0,3,1,2)`, then flatten. Keras convolution weights are HWIO;
TFLite stores OHWI; export converts OHWI→OIHW using `(0,3,1,2)`.
Conv0 is [16,3,3,3], indexed `(((oc*Cin+ic)*Kh+ky)*Kw+kx)`.
Every output sums over all three input channels. DW weights are converted
1HWC→CHW for depth multiplier one. Dense weights remain OI.

SAME padding uses output `ceil(input/stride)` and leading pad
`max(0,(output-1)*stride+kernel-input)//2`. A stride-two 3×3 kernel on
even dimensions has leading pad zero and trailing pad one; symmetric
one-pixel padding would produce different results.

## Historical 30-epoch training and evaluation

Default seed 2026; TensorFlow/Keras seed plus NumPy seeded permutation;
deterministic TensorFlow operations requested. Dataset is original CIFAR-10,
uint8 RGB divided by 255. No augmentation, batch normalization, or test-set
selection. A seeded permutation of 50,000 training examples yields 45,000
training and 5,000 validation examples. The 10,000 test images are separate.
Training: Adam 0.001, batch 128, 30 epochs, sparse categorical crossentropy
from logits. Final epoch is saved as `float.keras` and evaluated; the separate
best-validation checkpoint is `best.keras`. Conversion uses the final model.

All data/cache, checkpoints, CSV history, version/device records, split hash,
accuracies, and model artifacts stay under ignored `model/generated/`.
The dataset's standard class order is airplane, automobile, bird, cat, deer,
dog, frog, horse, ship, truck. No GPU is assumed; requirements pin a CPU build.
Determinism across different platforms/library releases is not guaranteed.

Completed 30 epochs with seed 2026, batch 128 and Adam(0.001).
Training took 520.137 seconds (including per-epoch validation/checkpoints);
dataset loading/download took 1,389.558 seconds separately. Thread settings:
TF_NUM_INTRAOP_THREADS=4, TF_NUM_INTEROP_THREADS=2, OMP_NUM_THREADS=4.
Final training accuracy: 56.2867%; validation accuracy: 55.7400%; test accuracy:
55.9600% (5,596/10,000). Test loss: 1.220976. Final-epoch model, not best
checkpoint, is used throughout conversion and comparison. Float+INT8 test
evaluation took 24.284 seconds after loading.

INT8 test accuracy: 55.9300% (5,593/10,000), a 0.0300 percentage-point drop.
Float/INT8 prediction agreement is 96.5400% (9,654/10,000); agreement and
label accuracy are different metrics. This compact baseline has modest
accuracy. A separately named future experiment can evaluate longer training,
a learning-rate schedule and mild augmentation before changing the topology.
No architecture changes were made to improve these results.

## Full INT8 and parameter export

Conversion requires INT8 builtin operators, INT8 input and output and a
representative set of 500 seeded training images (never validation/test).
The calibration indices and float artifact hash are recorded. Evaluation
rounds normalized images to nearest ties-to-even and clamps before int8 cast.
Default TFLite evaluation covers all 10,000 test images using BUILTIN_REF,
with no optimized delegate; sample reductions are explicit in each report.

`export.json` records the actual FlatBuffer operators, shapes, tensor dtypes,
scales, zero points, quantized axes, layer order, strides, asymmetric padding,
fused activation clamps, constants and per-channel multipliers/shifts.
INT32 shape/reduction constants are allowed; floating activation/weight
operators are rejected. Current supported sequential plan is Conv, DW, Conv,
DW, Conv, DW, Conv, MEAN, FC. Unexpected operations fail export rather than
being silently ignored. Weight zero points must be zero; bias scales are
checked against input scale × weight scale. Export validates overflow bounds,
weight quantization axes, shape sequence and parameter count.

The exporter wrote real independent C arrays `model_data.c/.h` and full
quantization metadata in `export.json`. The generated C compiles with warnings
as errors. TFLite is 19,824 bytes. Actual graph: CONV_2D, DEPTHWISE_CONV_2D,
CONV_2D, DEPTHWISE_CONV_2D, CONV_2D, DEPTHWISE_CONV_2D, CONV_2D, MEAN,
FULLY_CONNECTED. Activations/weights are INT8, biases INT32; the reduction-axis
constant is INT32. No floating-point tensor occurs in this graph.

Input: scale 0.003921568859368563, zero point -128, INT8 [1,32,32,3].
Historical baseline output: scale 0.06969189643859863, zero point 43.
Promoted output: scale 0.07269071787595749, zero point 31, INT8 [1,10] logits.
Per-layer metadata and weight-scale/multiplier/shift ranges are recorded in
Validation.md; full channel arrays and bias scales are in export.json.
TFLite SHA-256: `d1544d1fad460bb0d0dda634a82fa963b4db3251ea7839b2543255f49d4c4729`.
Float SHA-256: `f452aab509ba5cd3bf06f207d3d6124b5db03824ac65ec0d01391852c9fadfb5`.

Effective convolution/dense multiplier is `input_scale * weight_scale /
output_scale`. Q31 representation uses frexp with a carry when rounded
significand reaches 2^31. Positive shifts mean right shift; negative shifts
mean saturating left shift before multiply. The native high-multiply uses
signed int64 products and division truncated toward zero, with nudges giving
nearest rounding and ties toward +infinity. The subsequent power-of-two
division rounds ties away from zero. Final offset addition is int64 and
clamps to the exported activation interval and INT8 range. GAP multiplies
the centered sum by `input_scale / (output_scale * H * W)` in one requantization.

This is an explicit reference arithmetic contract. Measured numerical
comparison scope is reported in Validation.md; it does not establish universal
TFLite equivalence across inputs, library builds or optimized delegates.
No optimization-equivalence assertion is made.

## Native verification

`software/reference/kernels.c` implements generic signed RGB Conv2D,
pointwise via Conv2D, depthwise multiplier one, spatial mean and dense.
All MAC accumulators are INT32; host-only requantization uses int64 division.
The exporter bounds worst-case accumulation; direct external callers must
validate dimensions and bounds. This code is not freestanding RV32 firmware
and may need division helpers unavailable on the eventual CPU.

Measured tests: five unittest cases pass. The 4×4×3→2-channel, 3×3 Conv2D
fixture covers stride 1 and stride 2: 40 outputs, four stages each, all exact
between independently ordered Python loops and C. Inputs and weights include
signed endpoints, nonzero input/output zero points and both saturation limits.
288 signed requantization edge combinations pass, including saturating left
shifts. Additional tests cover DW channel isolation, ReLU-style clamping,
RGB→CHW conversion, multiplier carry/range handling, GAP and FC.
No TensorFlow or NumPy is needed for these tests.

The full-model driver loads actual export constants, checks the TFLite hash,
runs all C kernels and compares every layer to retained reference TFLite
tensors. Reports distinguish native label accuracy, TFLite label accuracy,
prediction agreement, exact-logit image count, equal tensor elements and
maximum absolute tensor error. Default native run is 100 images; request
10,000 explicitly for the full set. Both report sizes are preserved separately
as native_verification_100.json and native_verification_10000.json. See the
completed numerical comparison in Validation.md: all 10,000 predictions and
932,580,000 layer output elements match exactly (max error 0), in 162.000 seconds.
Native label accuracy is 55.93%, with 100% TFLite prediction agreement.
This is observed equality for this dataset/build, not universal arithmetic
equivalence. There is no RTL equivalence result.

## Memory footprint

`scripts/memory_budget.py --export model/generated/export.json` uses actual
exported tensor sizes. Numeric payload measurements below agree with the
earlier analytical budget; fixed buffer allocation remains a deployment plan.
The TFLite container is 19,824 bytes and is an alternative storage format,
not an additional required copy alongside exported arrays. Generated C arrays
occupy 10,384 bytes of host object read-only sections including alignment
(excludes GAP metadata and descriptors), versus 10,248 raw array bytes.
Runtime floating scales/zero-point tables are unnecessary if using the
exported integer constants, but any retained descriptors need separate accounting.

| Item | Bytes |
|---|---:|
| INT8 weights | 7,056 |
| INT32 biases (266) | 1,064 |
| Per-output-channel INT32 multipliers and shifts | 2,128 |
| GAP multiplier and shift | 8 |
| RGB input | 3,072 |
| Two fixed 32,768-byte INT8 activation buffers | 65,536 |
| Separate GAP/logit buffers | 74 |
| Numeric payload plus fixed buffers | **78,938** |
| Remaining of 262,144 for code, descriptors and stack | **183,206** |

Intermediate tensor bytes in order: 16,384; 16,384; 32,768; 8,192;
12,288; 3,072; 4,096; 64; 10. Maximum adjacent-tensor total is 49,152
(DW1→PW1), so lifetime-aware allocation could reduce the conservative pair
of equal buffers. Kernels need no im2col buffer, tensor-sized int32 scratch
or heap. Optional stage traces are diagnostic host allocations, not required
for embedded inference. Do not embed the complete dataset: 10,000 RGB images
alone require 30,720,000 bytes, excluding labels.

A purely illustrative 32 KiB code reserve plus 8 KiB stack gives 119,898 bytes;
these reserves are **not measurements**. Measured x86 host shared library:
text 4,260, data 472, bss 8 bytes (`size`); GCC stack-usage reports local
frames of 232 bytes for Conv, 80 for mean/FC, 8 for requant. These exclude
host Python/TensorFlow memory, caller frames and ABI overhead, and do not
predict RV32 firmware size/stack. Actual firmware/link map and high-water
stack measurements are absent. Complete fit is projected, not proven.

Feasible strategy: keep weights/code in shared RAM, reuse two activation
buffers, stream one image at a time, and reserve stack explicitly. If measured
code/runtime exceeds the remaining budget, reduce activation allocation by
lifetimes or place immutable parameters in an explicitly designed ROM with
measured access cost. DDR/DMA is not a capacity justification.

## Next milestones

Gen 2B should define and verify a bounded RGB Conv0 MMIO operation accumulating all three channels
with OIHW weights, input zero-point handling, INT32 sums and the chosen
requantization contract. Use the deterministic RGB fixture and the promoted version
model/references/gen2b-cifar10-a59-int8-v1 golden layer/stage vectors; verify arithmetic, reset, registers and transaction
handshakes with an explicit simulation top. Preserve CPU bias/clamp
ownership unless a documented interface change is selected. No RTL timing
or synthesis success can be inferred from these software tests.

Future DMA requires separate design of memory capacity, transfer addresses,
length/stride semantics, ownership, bus arbitration, start/done/error behavior,
reset and coherence, followed by transfer correctness tests before performance
claims. Local buffers, double buffering, AXI masters and PE arrays are later
milestones. YOLO, camera, PetaLinux, INT4 and compiler/runtime frameworks remain
out of scope. No commits or pushes were made for Gen 2A.
