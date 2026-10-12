# MNIST host accuracy evaluation

This evaluates the existing saved models and current native C inference on all
10,000 canonical MNIST test images. It never trains, changes model artifacts,
replaces `mnist_test_images.h`, builds firmware, or runs RTL/Vivado.

Use an output directory outside the repository. A TensorFlow/Keras environment
with NumPy is required for `references`; `native` needs only Python's standard
library and a host C compiler. The two stages can run on different operating
systems using the same output directory.

In a suitable Python environment, from the active target directory:

```sh
python -B evaluation/evaluate_mnist.py --stage references \
  --mnist-npz /path/to/canonical/mnist.npz --output-dir /tmp/tmn_accuracy_10k
python3 -B evaluation/evaluate_mnist.py --stage native \
  --output-dir /tmp/tmn_accuracy_10k
```

Without `--mnist-npz`, Keras downloads the canonical archive into the output
directory's isolated cache. With it, the existing archive is copied there and
loaded through `tf.keras.datasets.mnist.load_data()`, including Keras's hash
validation. Use a fresh output directory for a new reference run. `--stage all`
runs both stages when one environment supplies all dependencies.

The verified existing environments for this checkout are:

- Windows standalone Python 3.10.8 at
  `C:\Users\nvnha\AppData\Local\Programs\Python\Python310\python.exe`,
  TensorFlow 2.18.0, Keras 3.7.0, NumPy 2.0.2.
- WSL Python 3.14.4 and GCC 15.2.0 for the native stage.
- Existing canonical archive: `C:\Users\nvnha\.keras\datasets\mnist.npz`.

The reference stage was run from WSL using Windows Python, with script and
output paths expressed as `\\wsl.localhost\Ubuntu\...` UNC paths; the native
stage then used `/tmp/tmn_accuracy_10k` directly. No packages were installed.

## Preprocessing and interpretation

Use float32 pixels divided by float32 255. For both TFLite and native C, quantize
using float32 `clip(x / input_scale + zero_point, -128, 127).astype(int8)`.
This clips then truncates toward zero; it does not round to nearest. It matches
`extract_mnist_test.py`. The evaluator checks every embedded subset image and
label against regenerated canonical data and reports any differences.

The training script's short TFLite evaluation uses casting without clipping;
the extractor uses clipping. This evaluation uses the extractor policy for
both integer paths. Float uses the same normalized source pixels. Argmax chooses
the first index on ties. The float model includes softmax, TFLite executes its
saved graph, and native C produces its existing pre-softmax score vector.
Those vectors are not directly numerically comparable.

Reference execution uses CPU, one thread, seed zero, deterministic TensorFlow
operations, and oneDNN disabled. TFLite uses its default CPU interpreter/delegate.
Versions and platform are recorded; results are conditional on that environment.

Native builds use `-O2 -DNATIVE_RUN`, matching the existing verifier command.
Only an output-local copy of `verify_native.c` is adapted to stream one label
and 784 quantized bytes per sample. All layer calls and production inference
sources are retained. Existing C signed-overflow/shift limitations are not repaired
by this evaluator, so native results are compiler-specific evidence.

## Outputs

- `results.json`: model/source/dataset hashes, versions, quantization metadata,
  correct counts, model accuracy, confusion matrices, prediction agreement,
  all disagreement indices, and production-subset comparison.
- `predictions.csv`: canonical index, true label, float/TFLite/native predictions.
- `summary.txt`: concise human-readable metrics.
- `native_input.bin`: 10,000 records, each one uint8 label plus 784 int8 pixels.
- `verify_native_10k.c`, executable, and `native.log`: native reproduction artifacts.
- `native_prediction_disagreements.json`: prediction mismatch records and native
  scores, without requiring all reference score vectors.

Report **model accuracy**, **float-vs-TFLite prediction agreement**, and
**native-vs-TFLite prediction agreement** separately. This run does not establish
**optimization equivalence** or **RTL equivalence**, and makes no claim of
RTL/TFLite bit-exactness. It does not build a hardware-semantic reference.
