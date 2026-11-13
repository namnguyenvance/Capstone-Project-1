# Frozen Gen 2B reference contract

Version gen2b-cifar10-a59-int8-v1 is an immutable software golden model.
No RTL, synthesis, timing, or complete RV32 firmware fit is implied.
Never edit artifacts under a released version ID. Any correction, model,
quantization, vector or verifier change requires a new version. The active.json
pointer pins the manifest SHA-256; the manifest pins every artifact, including
the verifier source. Hashes establish consistency, not a digital signature or
filesystem write protection. Review the pointer and manifest together.

Model: Experiment A, 60 epochs constant Adam 0.001, validation-selected epoch
59, seed 2026, batch 128, disjoint 45000/5000 train/validation split. Endpoint:
10 logits, no softmax. Float accuracy 61.72%, INT8/native accuracy 61.30% on
10000 CIFAR-10 test images. 7322 parameters, 1805952 nominal MACs/image.

The complete JSON/C export, exact TFLite and selected Keras checkpoint are
in model/. Evidence records original quantization and full native equality.
The original 30-epoch baseline remains historical and is not overwritten.

## Numeric/layout interface

Input int8 is [3,32,32] CHW, channel order R,G,B. Offset padding represents
real zero: outside samples contribute zero after centering, not raw INT8 zero.
Index = (channel*H+y)*W+x. Conv weights OIHW, index
((oc*Cin+ic)*Kh+ky)*Kw+kx. Conv0 sums all 3 RGB channels (27 products/output).
Depthwise weights CHW, multiplier 1; dense OI. TensorFlow metadata is NHWC;
transpose (0,3,1,2) before byte comparison. Vectors store sample-major CHW.

Graph: Conv0 32x32x16; DW1 32x32x16; PW1 32x32x32; DW2 16x16x32;
PW2 16x16x48; DW3 8x8x48; PW3 8x8x64; GAP64; dense10.
Every convolution fuses ReLU6. SAME 3x3 stride 2 on even dimensions has
leading pad 0, trailing pad 1. Use exact exported strides/padding/activation
bounds and new per-channel multipliers; do not mix with old model constants.

Weights int8, biases/accumulators int32. Positive shift means right shift;
negative shift means saturating left shift before Q31 high multiply.
High-multiply rounding ties toward positive infinity; power-of-two divide
ties away from zero. Output offset addition and exported activation clamping
follow requantization. The frozen C source defines the exact host arithmetic.
No assumption of universal TFLite or Gen 1 RTL arithmetic equivalence is made.
This model passed comparison to TensorFlow 2.18.1 BUILTIN_REF without delegates.

## Golden vectors and offline recovery

All inputs needed for full 10000-image testing are included as ten gzip
shards of signed-int8 CHW samples. Each contains 1000 images. FORMAT.json
specifies order, decoded sizes and hashes; labels.u8 holds class IDs 0..9.
Calibration includes the exact original 500 uint8 NHWC training examples;
normalize /255 for conversion. No dataset download, old experiments or local
cache is required. Source dataset: https://www.cs.toronto.edu/~kriz/cifar.html
(CIFAR-10, Krizhevsky/Hinton). Test samples preserve original dataset order.

Golden layer outputs for the first 100 images are stored in full, gzip int8
CHW streams. All 10000 logit vectors are stored; SHA-256 streams cover every
layer output across all 10000 images. Full-stream hashes supplement, not
replace, the direct native/TFLite per-element comparison in --mode both.
Conv0 image-0 raw accumulation, bias-added and requantized int32 traces are
little-endian CHW; these were independently generated with Python/NumPy
integer arithmetic and checked against TFLite final output. The five frozen
unit tests include the deterministic 4x4 RGB convolution and signed edges.

Git stores the complete package, roughly 30 MiB, split into files below 3 MiB.
There is no LFS pointer, external release URL or ignored-artifact dependency.
A fresh checkout after reviewing/committing the pending additions recovers
these bytes directly. Requirements for offline native verification: Python
3.11+ and C11 cc. Builds/reports must go outside this immutable directory.
Full reference TFLite verification and re-export additionally require
requirements.txt; evidence/environment.txt records the full original environment.

From MyTinyMobileNetGen2/:

    python3 -B scripts/hardware_reference.py verify
    python3 -B scripts/hardware_reference.py verify --mode native --limit 100 --output /tmp/ref-native100
    python3 -B scripts/hardware_reference.py verify --mode native --limit 10000 --output /tmp/ref-native10000
    .venv/bin/python -B scripts/hardware_reference.py verify --mode both --limit 10000 --reexport --output /tmp/ref-both10000
    python3 -B scripts/hardware_reference.py recover --destination /tmp/recovered-reference

Use fresh output/destination names. After recovery the copied
VERSION/tools/reference_engine.py is standalone: pass --bundle VERSION,
--manifest-sha from recovered active.json, --mode native and --output to it.
It does not import repository pipeline sources. The exact frozen TFLite is
preserved, so recovery does not depend on binary-identical converter output.
--reexport checks byte-identical JSON/C arrays from the frozen TFLite.
The selected float checkpoint and calibration samples also permit future
conversion experiments, which must use a new output/version and verify their
own hashes and numerics rather than assuming converter byte identity.
