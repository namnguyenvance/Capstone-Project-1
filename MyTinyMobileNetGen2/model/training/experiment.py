#!/usr/bin/env python3
"""Isolated Gen 2A training experiment; never writes baseline outputs."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import time
import traceback
sys.dont_write_bytecode = True
MODEL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODEL))
# Reuse the baseline dataset/preprocessing/topology implementations unchanged.
from pipeline import ROOT, OUT as BASELINE, load, split, dataset
from network import build


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--schedule', choices=['constant', 'cosine'], required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    allowed = (ROOT / 'model/experiments').resolve()
    if not output.is_relative_to(allowed) or output == allowed:
        parser.error('Output must be a new subdirectory of model/experiments')
    output.mkdir(parents=True, exist_ok=False)
    # Every pre-existing baseline artifact, including cache files, is protected.
    baseline_manifest = {str(p.relative_to(BASELINE)): digest(p)
                         for p in sorted(BASELINE.rglob('*')) if p.is_file()}
    save(output / 'baseline_manifest_before.json', baseline_manifest)
    config = {'seed': 2026, 'epochs': 60, 'batch_size': 128,
              'optimizer': 'Adam', 'schedule': args.schedule,
              'initial_learning_rate': 0.001, 'cosine_alpha': 0.01 if args.schedule == 'cosine' else None,
              'selection': 'maximum validation accuracy, then minimum validation loss; earliest exact tie',
              'thread_settings': {k: os.environ.get(k) for k in
                                  ['TF_NUM_INTRAOP_THREADS', 'TF_NUM_INTEROP_THREADS', 'OMP_NUM_THREADS']}}
    save(output / 'configuration.json', config)
    started = time.perf_counter()
    try:
        import numpy as np
        import tensorflow as tf
        tf.keras.utils.set_random_seed(config['seed'])
        tf.config.experimental.enable_op_determinism()
        x, y, xt, yt = load(tf, np)
        train, val = split(np, config['seed'])
        split_hash = hashlib.sha256(train.tobytes() + val.tobytes()).hexdigest()
        baseline_record = json.loads((BASELINE / 'training.json').read_text())
        if split_hash != baseline_record['split_sha256']:
            raise ValueError('Split differs from verified baseline')
        model, shapes = build(tf)
        initial_hash = hashlib.sha256(b''.join(w.tobytes() for w in model.get_weights())).hexdigest()
        steps = math.ceil(len(train) / config['batch_size'])
        rate = 0.001 if args.schedule == 'constant' else tf.keras.optimizers.schedules.CosineDecay(
            initial_learning_rate=0.001, decay_steps=60*steps, alpha=0.01)
        model.compile(optimizer=tf.keras.optimizers.Adam(rate),
                      loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True), metrics=['accuracy'])
        config.update(initial_weights_sha256=initial_hash, split_sha256=split_hash,
                      steps_per_epoch=steps, decay_steps=60*steps if args.schedule == 'cosine' else None,
                      tensorflow=tf.__version__, numpy=np.__version__, keras=tf.keras.__version__,
                      parameter_count=model.count_params(), shapes=shapes,
                      sources_sha256={str(p.relative_to(ROOT)): digest(p) for p in
                                      [MODEL/'pipeline.py', MODEL/'training/network.py', Path(__file__)]})
        save(output / 'configuration.json', config)
        class SelectBest(tf.keras.callbacks.Callback):
            def __init__(self):
                super().__init__()
                self.key = (-math.inf, -math.inf)
                self.selected = None
                self.rows = []
            def on_epoch_begin(self, epoch, logs=None):
                self.lr_start = float(tf.keras.backend.get_value(self.model.optimizer.learning_rate))
                self.epoch_start = time.perf_counter()
            def on_epoch_end(self, epoch, logs=None):
                row = {'epoch': epoch+1, **{k: float(v) for k,v in logs.items()},
                       'lr_start': self.lr_start,
                       'lr_end': float(tf.keras.backend.get_value(self.model.optimizer.learning_rate)),
                       'elapsed_seconds': time.perf_counter()-self.epoch_start}
                self.rows.append(row)
                key = (row['val_accuracy'], -row['val_loss'])
                if key > self.key:
                    self.key = key
                    self.selected = row.copy()
                    self.model.save(output / 'best.keras')
                    save(output / 'selection.json', self.selected)
                save(output / 'epochs.json', self.rows)
        selection = SelectBest()
        callbacks = [tf.keras.callbacks.CSVLogger(str(output/'training.csv')), selection]
        fit_start = time.perf_counter()
        history = model.fit(dataset(tf,x[train],y[train],128,2026,True),
                            validation_data=dataset(tf,x[val],y[val],128,2026),
                            epochs=60, callbacks=callbacks, verbose=2)
        fit_seconds = time.perf_counter()-fit_start
        model.save(output / 'final.keras')
        selected = tf.keras.models.load_model(output / 'best.keras')
        test_loss, test_accuracy = selected.evaluate(dataset(tf,xt,yt,128,2026), verbose=0)
        # Nominal convolution/DW/dense MAC count, including padded kernel positions.
        macs = 0
        for layer in selected.layers:
            if isinstance(layer, tf.keras.layers.DepthwiseConv2D):
                macs += math.prod(layer.output.shape[1:])*math.prod(layer.kernel_size)
            elif isinstance(layer, tf.keras.layers.Conv2D):
                macs += math.prod(layer.output.shape[1:])*math.prod(layer.kernel_size)*layer.input.shape[-1]
            elif isinstance(layer, tf.keras.layers.Dense):
                macs += layer.input.shape[-1]*layer.units
        first30_match = all(history.history[k][:30] == baseline_record['history'][k]
                            for k in ['accuracy','loss','val_accuracy','val_loss'])
        save(output / 'result.json', {'status': 'complete', **config, 'history': history.history,
             'training_seconds': fit_seconds, 'total_seconds': time.perf_counter()-started,
             'selected_epoch': selection.selected, 'final_epoch': selection.rows[-1],
             'selected_float_test_accuracy': float(test_accuracy), 'selected_float_test_loss': float(test_loss),
             'test_count': len(yt), 'macs_per_image': int(macs),
             'first30_exactly_match_baseline': first30_match,
             'selected_model_sha256': digest(output/'best.keras'),
             'devices': [d.name for d in tf.config.list_physical_devices()]})
        print((output/'result.json').read_text(), flush=True)
    except BaseException:
        save(output / 'failure.json', {'traceback': traceback.format_exc(),
                                      'elapsed_seconds': time.perf_counter()-started})
        raise
    finally:
        after = {str(p.relative_to(BASELINE)): digest(p)
                 for p in sorted(BASELINE.rglob('*')) if p.is_file()}
        save(output / 'baseline_integrity.json', {'unchanged': baseline_manifest == after,
             'changed_or_removed': [k for k in baseline_manifest if baseline_manifest[k] != after.get(k)],
             'added': sorted(set(after)-set(baseline_manifest))})
        if baseline_manifest != after:
            raise RuntimeError('Baseline artifact integrity check failed')

if __name__ == '__main__':
    main()
