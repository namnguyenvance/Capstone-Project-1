# Gen 2A controlled 60-epoch experiments

Completed 2026-11-12 on `work/gen2-rgb-dma`. The verified 30-epoch hardware
correctness reference remains unchanged. No Gen 1, RTL, DMA, architecture or
existing validation-document changes. No commit or push.

## Experimental controls

Both experiments reuse `network.build` and the existing pipeline's `load`,
`split`, and `dataset` functions unchanged. Each starts independently with
seed 2026, not from a pretrained checkpoint. Both use RGB uint8/255, the same
45,000/5,000 training/validation split, batch 128, Adam defaults, ReLU6 and
logit output. No augmentation, normalization, dropout or new operators.
TensorFlow deterministic operations are enabled. Python 3.11.18, TensorFlow
2.18.1, NumPy 2.0.2, Keras 3.15.1; CPU only, no GPU available.

Threads: intra-op 4, inter-op 2, OMP 4. The experiments ran sequentially.
Runtime includes fit, validation and checkpoint selection/saving, excluding
initial loading and selected-model test evaluation. Host conditions differ
from the earlier baseline run, so runtime ratios are not controlled speed benchmarks.

- A: 60 epochs, constant Adam learning rate 0.001.
- B: 60 epochs, per-update Keras CosineDecay, initial rate 0.001,
  alpha 0.01, no warmup, 352 batches/epoch, decay_steps=21,120.
  For optimizer update t, LR = 0.001 × [0.01 + 0.99 ×
  (1 + cos(pi × min(t,21120)/21120))/2]. The floor is 0.00001.
  It is reached after the final update; the final update uses a value just above it.
  This is the schedule tested, not a conclusion about all cosine schedules.
  See the [Keras schedule definition](https://keras.io/api/optimizers/learning_rate_schedules/cosine_decay/).

Both initial-weight hashes match:
`aef84973f11e78c5484fa1edf3394fda45fdd3384c3ea09dc4299b69516c0a2c`.
Both split hashes match the baseline:
`89ced88f01aedaa9db166a576b2a4eb11fc6597293619e835b1ba4c6e469ccdb`.
A's first 30 epochs match baseline training/validation accuracy AND loss exactly.
This provides a direct numerical control for the longer-training comparison.

Checkpoint selection is lexicographic: highest validation accuracy, then lowest
validation loss, then earliest epoch on an exact tie. Only the selected model
is evaluated on all 10,000 test images. Test labels do not select the checkpoint.
For the baseline, epoch 30 is also the highest-validation checkpoint.

## Results

| Metric | Baseline 30 | A: constant 60 | B: cosine 60 |
|---|---:|---:|---:|
| Selected epoch | 30 | 59 | 59 |
| Selected validation accuracy | 55.74% | 61.34% | 57.92% |
| Selected validation loss | 1.236612 | 1.091395 | 1.194219 |
| Final validation accuracy | 55.74% | 60.68% | 57.68% |
| Final validation loss | 1.236612 | 1.105505 | 1.194835 |
| Final training accuracy | 56.2867% | 62.2333% | 58.8422% |
| Final training loss | 1.220778 | 1.067371 | 1.169253 |
| Selected Float32 test accuracy | 55.96% | **61.72%** | 57.25% |
| Selected test correct / 10,000 | 5,596 | 6,172 | 5,725 |
| Selected Float32 test loss | 1.220976 | 1.076588 | 1.191790 |
| Parameters | 7,322 | 7,322 | 7,322 |
| Nominal MACs / image | 1,805,952 | 1,805,952 | 1,805,952 |
| Training runtime, seconds | 520.137 | 1,280.634 | 1,201.851 |

MACs count convolution/depthwise/dense full padded kernels; bias, activation,
requantization and GAP arithmetic are excluded. This is not a cycle estimate.
Deployment topology, activation shapes and operator types are identical;
there is no added inference compute or buffer cost from these training changes.
Quantized numeric payload sizes are expected to follow the existing topology,
but new model quantization, saturation bounds and equivalence remain unverified.

A improves selected test accuracy by 5.76 percentage points versus baseline;
B improves it by 1.29 points. A exceeds B by 4.47 points for this seed.
These are observed differences, not multi-seed statistical guarantees.

## Learning curves and interpretation

[Accuracy/loss curves (PNG)](../model/experiments/comparison60/learning_curves.png)
are also available as SVG and PDF. The baseline curves overlap A exactly
through epoch 30. Each plot includes training and validation curves for
all completed epochs. Per-epoch CSV and JSON files preserve the full evidence.
Training metrics aggregate batches during weight updates; validation metrics
use end-of-epoch weights, so their gap is not a same-checkpoint train-set evaluation.

Observations:

- Longer training at constant 0.001 is beneficial: A continues the baseline's
  trajectory and obtains substantially better validation AND test accuracy.
- A's final accuracy gap is 1.55 percentage points. Its validation accuracy
  fluctuates and epoch 60 is below selected epoch 59; there is no sustained
  validation-loss deterioration establishing strong overfitting.
- From epoch 50 to 60, A validation accuracy gains 0.90 points and validation
  loss falls 0.032001. Its best validation epoch is 59. A has diminishing/noisy
  progress, but the record does not establish a firm plateau at 60 epochs.
- B's final accuracy gap is 1.16 points. From epoch 50 to 60, validation
  accuracy changes by -0.18 points and loss falls only 0.005373. Its late
  training/validation curves flatten as LR approaches its floor. There is
  no clear strong overfitting signal; validation performance is approaching
  a plateau under this schedule.
- Both B training and validation performance finish below A. This supports
  investigating insufficient optimization rather than adding regularization
  or changing architecture immediately.

Hypotheses, not established causes:

- Decaying from the start may reduce learning rate before this small network
  finishes learning useful features. B's late plateau may be schedule-limited,
  rather than a capacity limit. These runs do not isolate the decay start time.
- A might improve further with more training or delayed decay. The data do
  not establish the optimal epoch count, schedule, or gains across other seeds.

## Preservation and verification

Each experiment has before/after SHA-256 inventories of every pre-existing
file under `model/generated/`, including the CIFAR cache, models, exports,
training logs and native reports. Both integrity reports say unchanged=true,
changed_or_removed=[], added=[]. Existing Validation.md and native reference
sources/artifacts were not rewritten. The baseline float/TFLite files remain:

- Float: `f452aab509ba5cd3bf06f207d3d6124b5db03824ac65ec0d01391852c9fadfb5`
- TFLite: `d1544d1fad460bb0d0dda634a82fa963b4db3251ea7839b2543255f49d4c4729`

All experiment checkpoints, logs, configuration, histories, manifests and
figures are in ignored `model/experiments/`. Each run preserves best.keras
and final.keras separately. Existing output directories are rejected to
prevent accidental reruns from overwriting evidence. Failed training would
retain its process log and failure.json; neither training experiment failed.

The small plotting environment was installed under /tmp, leaving the baseline
venv unchanged. Its initial package fetch failed due to sandbox DNS restrictions;
the approved retry succeeded. This was not a training failure.

Verification: both independent initial hashes and split hashes match; actual
shapes/parameters/MACs match; A reproduces the baseline prefix exactly;
comparison recomputes each selected epoch using the tie-break rule; all
original five Python/C unit tests pass using the pre-existing native library
without rebuilding it; new Python scripts parse; git diff --check passes;
experiment paths are ignored. No new INT8 conversion or native inference
comparison was performed for either new model.

## Reproduction

From `MyTinyMobileNetGen2/`, using the existing ML environment:

```bash
export TF_NUM_INTRAOP_THREADS=4 TF_NUM_INTEROP_THREADS=2 OMP_NUM_THREADS=4
export PYTHONDONTWRITEBYTECODE=1
mkdir -p model/experiments
.venv/bin/python -B model/training/experiment.py --schedule constant --output model/experiments/constant60_seed2026 > model/experiments/constant60_seed2026.log 2>&1
.venv/bin/python -B model/training/experiment.py --schedule cosine --output model/experiments/cosine60_seed2026 > model/experiments/cosine60_seed2026.log 2>&1
```

These are the executed commands. To repeat them, use fresh output names and
fresh log names; the current run directories already exist. Do not redirect
a new process into an existing evidence log. The comparison script reads the
original named runs. Plot using an environment with Matplotlib 3.10.7:

```bash
python -B model/training/compare_experiments.py --output model/experiments/comparison60
```

The recorded invocation used `/tmp/gen2-plot-env/bin/python`; the destination
also refuses overwrite. Raw results live in each run's result.json,
epochs.json, training.csv, selection.json, configuration.json and integrity
manifests. Aggregate metrics are in comparison60/comparison.json.

## Recommendation

Keep the verified baseline as the hardware correctness reference. A's
validation-selected epoch-59 model is the stronger Float32 candidate, but
promotion requires isolated full INT8 conversion/calibration/export, test
accuracy evaluation and native-C tensor/prediction equivalence checks first.
Do not infer that its old INT8 metadata or rounding behavior transfers unchanged.

The next training ablation, if accuracy work continues, should keep the
60-epoch budget and start with constant 0.001 for 30 epochs before decaying
through the remaining 30. Compare against A with identical controls; this
isolates delayed versus early annealing without changing architecture or
adding epochs. Additional seeds should confirm robustness before treating
a schedule preference as general. No hardware architecture change is yet
justified by these experiments.
