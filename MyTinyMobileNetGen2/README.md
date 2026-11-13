# TinyMobileNet Gen 2

Independent CIFAR-10 RGB software baseline. Gen 1 in `../MyTinyMobileNetSoC/`
is read-only (`gen1-final`). Work stays on `work/gen2-rgb-dma`; no RTL or DMA
is implemented. See [plan and measured status](docs/Gen2_RGB_DMA_Plan.md) and
[Gen 1 audit](docs/Gen1_Pipeline_Audit.md).

## Promoted Gen 2B hardware model reference

**Active version: `gen2b-cifar10-a59-int8-v1`**, Experiment A selected epoch 59.
Float32 test accuracy **61.72%**, INT8/native **61.30%**, over all 10,000 test
images. Native C/reference TFLite match all predictions and 932,580,000
compared layer elements exactly. This is a software golden model, not verified RTL.

[Active pointer](model/references/active.json) pins manifest SHA-256
`7378a63f5d7b1f16d4e8060ea843605bbf27db498729c2631075fa3ee99f8b93`.
[Reference/recovery guide](model/references/README.md) and
[promotion checks](docs/Gen2B_Model_Reference_Promotion.md) describe the full
Git-deliverable bundle: models, JSON/C export, metadata, frozen sources,
calibration samples, full test inputs and golden vectors. About 33.3 MiB,
no external artifact service or ignored-cache dependency.

```bash
python3 -B scripts/hardware_reference.py verify
python3 -B scripts/hardware_reference.py verify --mode native --limit 10000 --output /tmp/gen2b-native
.venv/bin/python -B scripts/hardware_reference.py verify --mode both --limit 10000 --reexport --output /tmp/gen2b-both
python3 -B scripts/hardware_reference.py recover --destination /tmp/gen2b-recovered
```

Run from this directory; choose fresh outputs. Native verification needs only
Python and cc. Use the version's requirements.txt for TFLite/re-export checks.
Original baseline/A/B artifacts remain unchanged; historical pipeline commands
below still target model/generated and do not select the promoted version.
Perform historical training reproduction in a fresh workspace to preserve old runs.

## Historical 30-epoch Gen 2A baseline

**Measured baseline:** actual Keras/TFLite shapes and 7,322 parameters verified.
30 CPU epochs took 520.14 seconds: training 56.2867%, validation 55.7400%,
full-test float 55.96%, INT8 55.93% (10,000 test images). Float/INT8 prediction
agreement is 96.54%. Native/TFLite agreement is 100% over all 10,000 images,
with every compared layer tensor exact (max error 0). See Validation.md for scope.
The original dependency blocker is resolved with the existing Python 3.11.18,
TensorFlow 2.18.1, NumPy 2.0.2 environment. No GPU is available.

## Reproduce

Run from `MyTinyMobileNetGen2/`. ML commands require a working CPython 3.11 or
3.12 installation with venv/pip. These commands install a CPU baseline; GPU
support is not required. CIFAR-10 is downloaded by Keras on first ML use.
All generated artifacts, checkpoints, logs and dataset caches stay in Gen 2.

```bash
# Reuse the existing .venv. For a fresh setup only:
# python3.11 -m venv .venv
# .venv/bin/python -m pip install -r requirements.txt
export TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4

# Build the actual Keras graph and assert shapes/parameter count (no dataset).
.venv/bin/python model/pipeline.py topology
# Fixed split/seed, 30 epochs, evaluate the separate full test set.
.venv/bin/python model/pipeline.py train --seed 2026 --epochs 30 --batch-size 128
# Calibrate from training data; convert and inspect/export the actual graph.
.venv/bin/python model/pipeline.py quantize --seed 2026 --calibration 500
# Evaluate float and INT8 on all test images, recording sample count.
.venv/bin/python model/pipeline.py evaluate --limit 10000
# Re-export explicitly (quantize already calls this).
.venv/bin/python model/pipeline.py export

# Strict native build + independent staged RGB, DW, GAP, FC, quantization tests.
python3 software/reference/test_rgb.py
# Compile exported constants too, once export has completed.
cc -std=c11 -O2 -Wall -Wextra -Wconversion -Werror -c model/generated/model_data.c -o build/model_data.o
# C inference driven by actual exported constants, versus TFLite reference.
.venv/bin/python software/reference/verify_model.py --limit 100
# Full test set when practical (report runtime/sample limit honestly).
.venv/bin/python software/reference/verify_model.py --limit 10000

python3 scripts/memory_budget.py --export model/generated/export.json
python3 -m compileall -q model software/reference scripts
git diff --check
git status --short
```

Standalone native build (create the build directory first):

```bash
mkdir -p build
cc -std=c11 -O2 -Wall -Wextra -Wconversion -Werror -fPIC -shared software/reference/kernels.c -o build/libg2.so
cc -std=c11 -O2 -Wall -Wextra -Wconversion -Werror -fstack-usage -c software/reference/kernels.c -o build/kernels.o
size build/libg2.so
cat build/kernels.su
```

The native sources are host references, not firmware: int64 division may
require unavailable RV32 runtime helpers. Do not link them directly into Gen 1.
The unit test needs only system Python and a C compiler. It also builds
`build/libg2.so` with warnings treated as errors.

## Artifacts and interpretation

`model/generated/` contains `architecture.json`, `training.json`,
`training.csv`, `float.keras`, `best.keras`, `int8.tflite`, `calibration.json`,
`export.json`, `model_data.c/.h`, `evaluation.json`,
`native_verification_100.json`, `native_verification_10000.json`,
`memory_actual.json`, `environment.txt`, and `keras_cache/` after the relevant commands run.
Missing measurements stay absent; the scripts do not create placeholder accuracy.
All these paths and `build/` are ignored. Preserve a run's complete directory
externally before retraining; filenames are deliberately fixed and overwritten.

`export.json` is the layout/quantization contract: actual tensor IDs and shapes,
INT8 OIHW/CHW/OI weights, INT32 biases, scales/zero points, multiplier/shift
arrays and activation bounds. Unsupported FlatBuffer operations fail export.
Full-model reports bind to the TFLite SHA-256. This export/interpreter code
uses TensorFlow internal schema APIs; it was exercised successfully in the
recorded environment. `environment.txt` records the installed dependency versions.

Model label accuracy, prediction agreement, tensor numerical equality and
optimization equivalence are separate metrics. Validation.md records measured
numerical scope; no universal arithmetic, optimized-delegate or RTL equivalence
is claimed. The model is 19,824 bytes as TFLite. Actual exported payload plus
planned buffers is 78,938 bytes, leaving 183,206 of 262,144 bytes for code,
descriptors and stack. Complete RV32 firmware memory remains pending.

Accuracy is modest. Future accuracy experiments should first consider a
learning-rate schedule, longer training or mild augmentation with separately
recorded results. Gen 2B should validate three-channel Conv0 MMIO accumulation
against this model's software vectors; DMA remains a later milestone.
