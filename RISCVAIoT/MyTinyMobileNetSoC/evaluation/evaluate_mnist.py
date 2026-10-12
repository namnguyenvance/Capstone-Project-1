#!/usr/bin/env python3
"""Saved-model MNIST evaluation; native stage needs only stdlib and a C compiler.

Preprocessing deliberately matches extract_mnist_test.py: float32 pixel/255,
then float32 clip(x/scale+zero_point, -128,127), truncation to int8 (not round).
Native and TFLite consume identical bytes. Nothing trains or writes firmware.
"""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
COUNT = 10000
SOURCES = ("verify_native.c", "dl_ops.c", "quantize.c", "dl_ops.h",
           "quantize.h", "tinymobilenet_model_data.c", "tinymobilenet_model_data.h")
POLICY = "float32 pixels / 255; float32 clip(x/scale+zero_point,-128,127); truncate to int8; first-index argmax"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def metrics(truth, predictions):
    matrix = [[0] * 10 for _ in range(10)]
    for actual, predicted in zip(truth, predictions):
        matrix[actual][predicted] += 1
    correct = sum(matrix[i][i] for i in range(10))
    return {"correct": correct, "count": len(truth),
            "accuracy": correct / len(truth), "confusion_matrix": matrix,
            "confusion_matrix_axes": "rows=true label, columns=prediction"}


def agreement(left, right):
    indices = [i for i, (a, b) in enumerate(zip(left, right)) if a != b]
    return {"agree": len(left) - len(indices), "count": len(left),
            "agreement": (len(left) - len(indices)) / len(left),
            "disagreement_count": len(indices), "disagreement_indices": indices}


def save(out, result, rows):
    (out / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    with (out / "predictions.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    lines = ["MNIST: 10,000 canonical test images", "Preprocessing: " + POLICY]
    for name, value in result["model_accuracy"].items():
        lines.append(f"{name} model accuracy: {value['correct']}/{value['count']} ({value['accuracy']:.4%})")
    for name, value in result["prediction_agreement"].items():
        lines.append(f"{name} prediction agreement: {value['agree']}/{value['count']}; disagreements={value['disagreement_count']}; first indices={value['disagreement_indices'][:20]}")
    lines.append("Optimization equivalence and RTL equivalence are not evaluated by this host-only run.")
    text = "\n".join(lines) + "\n"
    (out / "summary.txt").write_text(text)
    print(text, flush=True)


def references(args, out):
    # Set before importing TensorFlow; record these choices in the result.
    os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
    os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
    os.environ["TF_DETERMINISTIC_OPS"] = "1"
    # Keras 3 load_data accepts a filename, not an absolute archive path.
    # Keep its writable cache in the external results directory.
    cache = out / "keras_cache"
    os.environ["KERAS_HOME"] = str(cache)
    if args.mnist_npz:
        (cache / "datasets").mkdir(parents=True, exist_ok=True)
        shutil.copyfile(args.mnist_npz, cache / "datasets" / "mnist.npz")
    import numpy as np
    import tensorflow as tf
    tf.config.threading.set_intra_op_parallelism_threads(1)
    tf.config.threading.set_inter_op_parallelism_threads(1)
    tf.keras.utils.set_random_seed(0)
    models = [ROOT / "tinymobilenet_mnist_float.keras", ROOT / "tinymobilenet_mnist_quant.tflite"]
    hashes = {p.name: sha(p) for p in models}
    (_, _), (pixels, labels) = tf.keras.datasets.mnist.load_data()
    if pixels.shape != (COUNT, 28, 28) or labels.shape != (COUNT,):
        raise ValueError("Expected exactly the canonical 10,000 MNIST test images")
    if not np.all((labels >= 0) & (labels < 10)):
        raise ValueError("Invalid MNIST labels")
    inputs = pixels.reshape(COUNT, 28, 28, 1).astype(np.float32) / np.float32(255)
    model = tf.keras.models.load_model(models[0], compile=False)
    if tuple(model.input_shape[1:]) != (28, 28, 1) or model.output_shape[-1] != 10:
        raise ValueError("Unexpected saved float model shape")
    float_pred = []
    for begin in range(0, COUNT, 128):
        scores = model(inputs[begin:begin + 128], training=False).numpy()
        float_pred.extend(np.argmax(scores, axis=1).astype(int).tolist())
    interpreter = tf.lite.Interpreter(model_path=str(models[1]), num_threads=1)
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    output = interpreter.get_output_details()[0]
    if inp["dtype"] != np.int8 or output["dtype"] != np.int8 or inp["shape"].tolist() != [1, 28, 28, 1] or output["shape"].tolist() != [1, 10]:
        raise ValueError("Expected int8 TinyMobileNet input/output")
    scale, zp = inp["quantization"]
    if scale <= 0:
        raise ValueError("Invalid input quantization scale")
    q = np.clip(inputs / np.float32(scale) + np.float32(zp), -128, 127).astype(np.int8)
    # One record = uint8 ground-truth label followed by 784 signed-int8 pixels.
    records = np.concatenate((labels.astype(np.uint8).reshape(COUNT, 1), q.reshape(COUNT, 784).view(np.uint8)), axis=1)
    dataset = out / "native_input.bin"
    dataset.write_bytes(records.tobytes())
    tflite_pred = []
    for i in range(COUNT):
        interpreter.set_tensor(inp["index"], q[i:i + 1])
        interpreter.invoke()
        tflite_pred.append(int(np.argmax(interpreter.get_tensor(output["index"])[0])))
        if (i + 1) % 1000 == 0:
            print(f"TFLite evaluated {i + 1}/{COUNT}", flush=True)
    truth = labels.astype(int).tolist()
    rows = [{"index": i, "true_label": truth[i], "float_prediction": float_pred[i],
             "tflite_prediction": tflite_pred[i]} for i in range(COUNT)]
    def quant_info(detail):
        qp = detail["quantization_parameters"]
        return {"name": detail["name"], "shape": detail["shape"].tolist(),
                "dtype": str(detail["dtype"]), "scale": detail["quantization"][0],
                "zero_point": detail["quantization"][1], "scales": qp["scales"].tolist(),
                "zero_points": qp["zero_points"].tolist(), "quantized_dimension": int(qp["quantized_dimension"])}
    # Check that regenerated canonical inputs reproduce the production subset.
    header = (ROOT / "mnist_test_images.h").read_text()
    embedded = re.findall(r"/\* Image (\d+): digit (\d+) \(index (\d+)\) \*/\s*\{([^}]+)\}", header)
    subset = {"count": len(embedded), "indices": [], "input_mismatch_indices": [], "label_mismatch_indices": []}
    for _, label, index, data in embedded:
        i = int(index)
        subset["indices"].append(i)
        values = np.array([int(v) for v in re.findall(r"-?\d+", data)], dtype=np.int8)
        if not np.array_equal(values, q[i].reshape(784)):
            subset["input_mismatch_indices"].append(i)
        if int(label) != truth[i]:
            subset["label_mismatch_indices"].append(i)
    subset["float_correct"] = sum(float_pred[i] == truth[i] for i in subset["indices"])
    subset["tflite_correct"] = sum(tflite_pred[i] == truth[i] for i in subset["indices"])
    result = {"preprocessing": POLICY, "model_sha256": hashes,
              "source_sha256": {name: sha(ROOT / name) for name in SOURCES},
              "production_dataset_sha256": sha(ROOT / "mnist_test_images.h"),
              "dataset": {"source": "tf.keras.datasets.mnist.load_data()", "test_count": COUNT,
                          "pixels_sha256": hashlib.sha256(pixels.tobytes()).hexdigest(),
                          "labels_sha256": hashlib.sha256(labels.tobytes()).hexdigest(),
                          "native_input_sha256": sha(dataset)},
              "environment": {"references": {"python": sys.version, "executable": sys.executable,
                              "platform": platform.platform(), "numpy": np.__version__,
                              "tensorflow": tf.__version__, "keras": tf.keras.__version__,
                              "oneDNN": False, "threads": 1, "seed": 0}},
              "quantization": {"input": quant_info(inp), "output": quant_info(output)},
              "production_subset": subset,
              "model_accuracy": {"float": metrics(truth, float_pred), "tflite": metrics(truth, tflite_pred)},
              "prediction_agreement": {"float-vs-TFLite": agreement(float_pred, tflite_pred)}}
    if args.mnist_npz:
        result["dataset"]["mnist_npz_sha256"] = sha(args.mnist_npz)
    if hashes != {p.name: sha(p) for p in models}:
        raise RuntimeError("Model artifacts changed during evaluation")
    save(out, result, rows)


def native(args, out):
    result = json.loads((out / "results.json").read_text())
    with (out / "predictions.csv").open(newline="") as f:
        rows = [{k: int(v) for k, v in row.items()} for row in csv.DictReader(f)]
    if len(rows) != COUNT or any(row["index"] != i for i, row in enumerate(rows)):
        raise ValueError("Invalid reference predictions")
    for name, expected in result["source_sha256"].items():
        if sha(ROOT / name) != expected:
            raise ValueError(f"Source changed since reference stage: {name}")
    for name, expected in result["model_sha256"].items():
        if sha(ROOT / name) != expected:
            raise ValueError(f"Model changed since reference stage: {name}")
    data = out / "native_input.bin"
    if data.stat().st_size != COUNT * 785 or sha(data) != result["dataset"]["native_input_sha256"]:
        raise ValueError("Generated native dataset hash/size mismatch")
    # Adapt only verifier I/O in an output-local copy, preserving every layer call.
    source = (ROOT / "verify_native.c").read_text()
    source = source.replace('#include "mnist_test_images.h"',
                            'static const int number_of_test = 10000;\nstatic int8_t test_images[1][784];\nstatic int8_t test_labels[10000];')
    source = source.replace('int main() {', 'int main(int argc, char **argv) {\n    if (argc != 2) return 2;\n    FILE *dataset = fopen(argv[1], "rb");\n    if (!dataset) return 2;')
    loop = 'for (int img_idx = 0; img_idx < number_of_test; img_idx++) {'
    source = source.replace(loop, loop + '\n        if (fread(&test_labels[img_idx], 1, 1, dataset) != 1 || fread(test_images[0], 1, 784, dataset) != 784 || test_labels[img_idx] < 0 || test_labels[img_idx] > 9) return 2;')
    source = source.replace('test_images[img_idx]', 'test_images[0]')
    source = source.replace('    return 0;', '    if (fgetc(dataset) != EOF) return 2;\n    fclose(dataset);\n    return 0;')
    driver = out / "verify_native_10k.c"
    driver.write_text(source)
    executable = out / ("verify_native_10k.exe" if os.name == "nt" else "verify_native_10k")
    command = [args.cc, "-O2", "-DNATIVE_RUN", "-I", str(ROOT), str(driver),
               str(ROOT / "dl_ops.c"), str(ROOT / "quantize.c"),
               str(ROOT / "tinymobilenet_model_data.c"), "-o", str(executable)]
    subprocess.run(command, check=True)
    log = out / "native.log"
    print("Running unchanged native layer implementation on 10,000 images...", flush=True)
    with log.open("w") as f:
        subprocess.run([str(executable), str(data)], stdout=f, check=True)
    text = log.read_text()
    blocks = re.findall(r"=== Image (\d+) \(Target: (\d+)\) ===.*?Scores: \[([^]]+)\].*?>> Predicted: (\d+)", text, re.S)
    if len(blocks) != COUNT:
        raise ValueError("Incomplete native output")
    native_pred = []
    mismatched_scores = []
    for i, (index, label, scores, predicted) in enumerate(blocks):
        if int(index) != i or int(label) != rows[i]["true_label"]:
            raise ValueError("Native sample ordering/labels mismatch")
        p = int(predicted)
        native_pred.append(p)
        rows[i]["native_prediction"] = p
        if p != rows[i]["tflite_prediction"] or p != rows[i]["float_prediction"]:
            mismatched_scores.append({**rows[i], "native_scores": [int(v) for v in scores.split(",")]})
    truth = [r["true_label"] for r in rows]
    result["model_accuracy"]["native"] = metrics(truth, native_pred)
    expected = f"FINAL RESULT: {result['model_accuracy']['native']['correct']}/{COUNT} passed"
    if expected not in text:
        raise ValueError("Native summary disagrees with parsed predictions")
    for reference, column in [("TFLite", "tflite_prediction"), ("float", "float_prediction")]:
        result["prediction_agreement"]["native-vs-" + reference] = agreement(native_pred, [r[column] for r in rows])
    subset = result["production_subset"]
    subset["native_correct"] = sum(native_pred[i] == truth[i] for i in subset["indices"])
    result["environment"]["native"] = {"python": sys.version, "executable": sys.executable,
                                      "platform": platform.platform(), "compiler": subprocess.check_output([args.cc, "--version"], text=True).splitlines()[0],
                                      "command": command, "driver_sha256": sha(driver)}
    (out / "native_prediction_disagreements.json").write_text(json.dumps(mismatched_scores, indent=2) + "\n")
    save(out, result, rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", choices=("references", "native", "all"), default="all")
    parser.add_argument("--output-dir", type=Path, required=True, help="Generated artifacts must be outside the repository")
    parser.add_argument("--mnist-npz", type=Path, help="Existing canonical MNIST archive; otherwise Keras uses/downloads its cache")
    parser.add_argument("--cc", default="cc")
    args = parser.parse_args()
    out = args.output_dir.resolve()
    repository = ROOT.parents[1]
    if out == repository or repository in out.parents:
        parser.error("Use an output directory outside the repository")
    out.mkdir(parents=True, exist_ok=True)
    if args.stage in ("references", "all"):
        if (out / "results.json").exists():
            parser.error("Reference results already exist; choose a fresh output directory")
        references(args, out)
    if args.stage in ("native", "all"):
        native(args, out)


if __name__ == "__main__":
    main()
