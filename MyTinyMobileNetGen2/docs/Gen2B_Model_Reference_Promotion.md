# Gen 2B model reference promotion

Promoted on 2026-11-13 on work/gen2-rgb-dma at the user's explicit request.
Active ID: **gen2b-cifar10-a59-int8-v1**. This promotes the software model,
export/numerical contract and golden vectors; it does not implement or verify RTL.
The original baseline and both training experiments remain unchanged.
No commit or push was made. New Git-eligible additions remain pending review;
a checkout of the current old HEAD alone cannot contain uncommitted additions.
The delivered file set was tested through a clean Git-index checkout without
making a commit in either the real repository or the temporary test repository.

## Identity and immutable manifest

`model/references/active.json` selects the version directory and pins:

- Manifest SHA-256: `7378a63f5d7b1f16d4e8060ea843605bbf27db498729c2631075fa3ee99f8b93`
- Selected epoch-59 Keras SHA-256: `bf561ec4d030d898d62c7630ca1816eb34cab64217ed7953aa86c1dff776ab6e`
- TFLite SHA-256: `8779ca06e9dbf5611ccef247bd6b55eca6127ff0fbeea7ec67b94ac72c20a6c1`

The manifest lists SHA-256 and byte size for every one of the 50 release
artifacts, including its verifier and kernel sources. Its own hash is pinned
outside the directory to avoid a circular self-hash. Version contents are
immutable by policy: never edit them; issue a new version ID/manifest for any
model, metadata, vector or verifier change. active.json may explicitly select
a later version. Hashes are consistency checks, not signatures or filesystem
write protection. Git attributes disable text conversion and filters on the
version and active pointer to preserve exact bytes across checkouts.

Selected source is Experiment A's best.keras at epoch 59, not final.keras at
60. Every candidate output was checked against its final checksum manifest
before packaging. Provenance metadata may mention historical absolute paths;
recovery never opens those paths. The manifest's model identity and the copied
Keras/TFLite/export bytes match the validated candidate.

## Complete, self-contained Git bundle

The release contains 34,954,960 artifact bytes plus its manifest (about
33.3 MiB). Largest file: 2,829,245 bytes. Ordinary Git is sufficient; no
LFS pointer, external storage account, untracked experiment file, download,
retraining, or ignored cache is required for verification after the pending
additions are included in a reviewed commit.

Included:

- Exact selected Float32 checkpoint, INT8 TFLite, JSON export and C arrays.
- Full weights, INT32 biases, all channel scales/zero points, multipliers,
  shifts, activation clamps, operator order/shapes/strides/padding and layouts.
- Frozen host kernels, arithmetic unit tests, exporter, topology source and
  standalone verifier. Native verification needs only Python 3.11+ and cc.
- Ten gzip shards containing all 10000 quantized RGB CHW test inputs and all
  labels, in original CIFAR-10 order. Decoded sizes/hashes are recorded.
- Exact 500 representative uint8 NHWC training/calibration samples plus their
  original indices/hash and /255 normalization contract.
- Full golden layer tensors for the first 100 images, all 10000 logit vectors,
  and every layer's SHA-256 stream over all 10000 test images. Full intermediate
  tensors for 10000 images are deliberately represented by stream hashes;
  --mode both regenerates them and compares native/TFLite elements directly.
- Independently generated real-RGB Conv0 image-0 raw accumulation, bias-added
  and requantized INT32 stages, serialized little-endian CHW. These passed
  native checks and agree with the final reference TFLite tensor.
- Original full validation records, exact dependency versions and memory report.

CONTRACT.md and dataset/vectors FORMAT.json specify encoding and indexing.
CIFAR-10 source attribution is included. No compiled host binary is committed;
all binaries are rebuilt into fresh output directories. The full test-input
shards account for most of the package size and remove the download dependency.

Frozen optional ML requirements: TensorFlow CPU 2.18.1, NumPy 2.0.2,
Keras 3.15.1 and h5py 3.16.0; original full package list is retained in
model reference evidence/environment.txt. Offline native replay does not
need any of them. GPU is unavailable and unnecessary for these checks.
Artifact recovery preserves the original bytes; no assumption of identical
TFLite converter output across environments is made. The float model and
calibration data permit later conversion experiments in separate versions.

## Numeric and memory baseline

| Property | Promoted value |
|---|---:|
| Float32 accuracy, 10000 test images | 61.72% |
| INT8/native accuracy, 10000 images | 61.30% |
| Original 30-epoch INT8 accuracy | 55.93% |
| INT8 accuracy gain | 5.37 percentage points |
| Parameters | 7322 |
| Nominal MACs/image | 1805952 |
| TFLite bytes | 19824 |
| Numeric weights/biases/multiplier/shift payload | 10256 bytes |
| Payload + input + planned activation/GAP/logit buffers | 78938 bytes |
| Remaining of 256 KiB, before code/stack/descriptors/alignment | 183206 bytes |

Expected nine integer operators and all shapes remain unchanged. Input scale
0.003921568859368563 / zero point -128; output scale
0.07269071787595749 / zero point 31. All convolution/dense weights use
per-channel scaling, with INT32 biases. Activations are CHW in vectors/native,
NHWC in TFLite; weights are OIHW/CHW/OI for Conv/DW/FC. Gen 2B must use the
new model's metadata, not the old baseline's scales or offsets.

## Executed verification

Reports below are checked in under docs/validation/gen2b_reference_v1/ with
a SHA256.json index. Outputs in build/ and /tmp are disposable test builds,
not required model dependencies.

| Check | Status / measured result |
|---|---|
| Candidate original checksum manifest | PASS, every recorded artifact matched |
| Regenerated reference TFLite goldens | PASS, all 10000 images, 6130 correct |
| Release manifest + every artifact | PASS, 50 artifacts |
| Native first-100 golden tensors/logits | PASS, exact, 62/100 correct |
| Conv0 accumulation/bias/requant stages | PASS, all stages exact |
| Frozen existing arithmetic/layout unit tests | PASS, five tests |
| Native/reference TFLite direct full comparison | PASS, 10000 predictions equal; all 932580000 layer elements equal; max error 0 |
| Full-test native/TFLite label accuracy | 61.30%, distinct from 100% prediction agreement |
| Re-export from frozen TFLite | PASS, export.json/model_data.c/model_data.h byte-identical |
| Offline recovered bundle, full native replay | PASS, all 10000 logits and full layer hashes exact |
| Clean Git-index checkout, autocrlf=true | PASS, entire artifact set hashes preserved |
| Native first-100 replay from clean Git checkout | PASS, exact tensors/logits, five unit tests |
| Negative integrity tests | PASS, bad pin, corrupted export, missing vector and unlisted file rejected |
| Preservation of generated/baseline/A/B/native artifacts | PASS, 84 pre-existing artifact files unchanged |
| Python syntax / git diff --check | PASS |
| Release files eligible for ordinary Git | PASS, no required ignored artifacts |
| Full RV32 firmware memory | PENDING, no link map/stack measurement |
| RTL reset/MMIO/arithmetic equivalence and timing | PENDING, no RTL work in this task |

Direct full native/TFLite run took 82.131 seconds (overlapped with the
independent offline native run); offline full native replay took 54.216 seconds.
Timing is not an FPGA performance estimate or a controlled CPU benchmark.
Compiler/system Python details are in build_environment.json. Equality scope
is this reference model/input set and TensorFlow BUILTIN_REF, not all possible
inputs, optimized delegates or future RTL implementations.

## Exact verification/recovery commands

From repository root (fresh output paths are required):

```bash
python3 -B MyTinyMobileNetGen2/scripts/hardware_reference.py verify --mode native --limit 100 --output MyTinyMobileNetGen2/build/reference_v1_native100
python3 -B MyTinyMobileNetGen2/scripts/hardware_reference.py recover --destination /tmp/gen2b-reference-fresh-v1
TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4 PYTHONDONTWRITEBYTECODE=1 MyTinyMobileNetGen2/.venv/bin/python -B MyTinyMobileNetGen2/scripts/hardware_reference.py verify --mode both --limit 10000 --reexport --output MyTinyMobileNetGen2/build/reference_v1_both10000
python3 -B MyTinyMobileNetGen2/scripts/test_reference_integrity.py
git diff --check
git status --short
```

Standalone recovered verification was run from /tmp, without importing any
repository source, ignored cache, NumPy or TensorFlow:

```bash
python3 -B /tmp/gen2b-reference-fresh-v1/gen2b-cifar10-a59-int8-v1/tools/reference_engine.py --bundle /tmp/gen2b-reference-fresh-v1/gen2b-cifar10-a59-int8-v1 --manifest-sha 7378a63f5d7b1f16d4e8060ea843605bbf27db498729c2631075fa3ee99f8b93 --mode native --limit 10000 --output /tmp/gen2b-fresh-native10000
```

The Git recovery test created a temporary repository containing only
model/references/ and scripts/hardware_reference.py under the normal Gen 2
paths, then ran:

```bash
git init -q /tmp/gen2b-git-checkout-v1/source
git -C /tmp/gen2b-git-checkout-v1/source config core.autocrlf true
git -C /tmp/gen2b-git-checkout-v1/source add MyTinyMobileNetGen2
git -C /tmp/gen2b-git-checkout-v1/source checkout-index --all --prefix=/tmp/gen2b-git-checkout-v1/checkout/
python3 -B /tmp/gen2b-git-checkout-v1/checkout/MyTinyMobileNetGen2/scripts/hardware_reference.py verify --mode native --limit 100 --output /tmp/gen2b-git-native100
```

No commit was used to create this clean checkout. This tests the exact proposed
Git-deliverable files and line-ending policy, rather than claiming that the
old committed HEAD already includes the uncommitted promotion.

One-time bundle creation was performed with:

```bash
TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4 PYTHONDONTWRITEBYTECODE=1 MyTinyMobileNetGen2/.venv/bin/python -B MyTinyMobileNetGen2/scripts/promote_reference.py
```

That helper refuses to overwrite the version directory. It depends on the
validated local candidate only to create a new release; recovery/verification
never calls it. Do not rerun it over this immutable ID or retrain to recover
model artifacts. Full compiler commands are fixed in the frozen verifier:
C11 -O2 -Wall -Wextra -Wconversion -Werror, shared native library plus C array
object. Builds and reports are always outside the release directory.

## Added/modified files for this promotion

Modified existing documentation: README.md, docs/Validation.md and
docs/Gen2_RGB_DMA_Plan.md. Original numerical records remain labelled historical.
The prior working tree already contained uncommitted Gen 2A work; it was not
reset, committed or rewritten. No Gen 1/thesis/RTL source was changed.

Added helpers:

- scripts/promote_reference.py (one-time guarded release builder)
- scripts/reference_engine.py (source copied into frozen release)
- scripts/hardware_reference.py (pinned active-version check/recovery entry)
- scripts/test_reference_integrity.py (positive/negative integrity tests)
- scripts/REFERENCE_CONTRACT.md (source of frozen contract)

Added reference root: model/references/README.md, active.json and .gitattributes.
Added immutable version manifest plus the following 50 hashed artifacts under
model/references/gen2b-cifar10-a59-int8-v1/:

- CONTRACT.md
- dataset/FORMAT.json
- dataset/calibration.nhwc.u8.gz
- dataset/labels.u8
- dataset/test_00000_00999.chw.i8.gz
- dataset/test_01000_01999.chw.i8.gz
- dataset/test_02000_02999.chw.i8.gz
- dataset/test_03000_03999.chw.i8.gz
- dataset/test_04000_04999.chw.i8.gz
- dataset/test_05000_05999.chw.i8.gz
- dataset/test_06000_06999.chw.i8.gz
- dataset/test_07000_07999.chw.i8.gz
- dataset/test_08000_08999.chw.i8.gz
- dataset/test_09000_09999.chw.i8.gz
- evidence/calibration.json
- evidence/environment.txt
- evidence/evaluation.json
- evidence/final_output_hashes.json
- evidence/memory.json
- evidence/metadata.json
- evidence/native_verification_100.json
- evidence/native_verification_10000.json
- evidence/protected_integrity.json
- evidence/result.json
- evidence/unit_tests.json
- model/export.json
- model/float.keras
- model/int8.tflite
- model/model_data.c
- model/model_data.h
- requirements.txt
- tools/export.py
- tools/kernels.c
- tools/network.py
- tools/reference_engine.py
- tools/test_rgb.py
- vectors/FORMAT.json
- vectors/conv0_image0.biased.le_i32.gz
- vectors/conv0_image0.raw.le_i32.gz
- vectors/conv0_image0.requant.le_i32.gz
- vectors/layer00.first100.chw.i8.gz
- vectors/layer01.first100.chw.i8.gz
- vectors/layer02.first100.chw.i8.gz
- vectors/layer03.first100.chw.i8.gz
- vectors/layer04.first100.chw.i8.gz
- vectors/layer05.first100.chw.i8.gz
- vectors/layer06.first100.chw.i8.gz
- vectors/layer07.first100.chw.i8.gz
- vectors/layer08.first100.chw.i8.gz
- vectors/logits10000.i8.gz

Each artifact's exact bytes/hash is in that manifest, rather than duplicated here.

Added promotion evidence files under docs/validation/gen2b_reference_v1/:

- SHA256.json
- build_environment.json
- git_checkout_native100.json
- integrity_tests.json
- native100.json
- native_tflite10000.json
- preservation.json
- recovered_native10000.json

This report, docs/Gen2B_Model_Reference_Promotion.md, is also new. No generated
experiment output was force-added from ignored paths: the release is a separate,
complete, Git-eligible copy with a tested offline recovery mechanism.

## Next milestone

Use the promoted version's CHW/OIHW tensors and stage vectors for Gen 2B RGB
Conv0 arithmetic and MMIO/reset/transaction verification. Keep CPU bias/clamp
ownership and quantization behavior explicit. Measure full RV32 memory before
claiming complete 256 KiB fit. No RTL, DMA, AXI master or accelerator optimization
was implemented as part of this promotion.
