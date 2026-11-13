#!/usr/bin/env python3
"""Validate A's selected checkpoint in a fresh directory; protect all old artifacts."""
import argparse
import ctypes
import hashlib
from importlib.metadata import distributions
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import traceback
import unittest
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / 'model'
BASE = MODEL / 'generated'
sys.path.insert(0, str(MODEL))
sys.path.insert(0, str(MODEL / 'quantization'))
sys.path.insert(0, str(ROOT / 'software/reference'))
from pipeline import load, split, dataset, interpreter, quant_input
from export import export


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()


def save(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n')


def inventory(output):
    return {str(p.relative_to(ROOT)): digest(p) for p in sorted(ROOT.rglob('*'))
            if p.is_file() and not p.is_relative_to(output)
            and '.venv' not in p.relative_to(ROOT).parts}


def exact(report):
    return (report['prediction_agreement'] == 1 and report['exact_logits_images'] == report['count']
            and all(s['equal_elements'] == s['elements'] and s['max_abs_difference'] == 0
                    for s in report['stages']))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    experiments = MODEL / 'experiments'
    if output.parent != experiments.resolve():
        parser.error('Use a fresh direct subdirectory of model/experiments')
    output.mkdir(exist_ok=False)
    before = inventory(output)
    save(output/'protected_manifest_before.json', before)
    start = time.perf_counter()
    metadata = {'command': [sys.executable, *sys.argv], 'output': str(output),
                'thread_settings': {k: os.environ.get(k) for k in
                                   ['TF_NUM_INTRAOP_THREADS','TF_NUM_INTEROP_THREADS','OMP_NUM_THREADS']}}
    save(output/'metadata.json', metadata)
    try:
        import tensorflow as tf
        import numpy as np
        tf.keras.utils.set_random_seed(2026)
        tf.config.experimental.enable_op_determinism()
        source = experiments/'constant60_seed2026'
        result = json.loads((source/'result.json').read_text())
        selection = json.loads((source/'selection.json').read_text())
        if selection['epoch'] != 59 or result['selected_epoch']['epoch'] != 59:
            raise ValueError('Expected validation-selected epoch 59')
        selected = source/'best.keras'
        if digest(selected) != result['selected_model_sha256']:
            raise ValueError('Selected checkpoint hash differs from training record')
        shutil.copy2(selected, output/'float.keras')
        metadata.update(selected_source=str(selected), selected_epoch=59,
                        selected_sha256=digest(selected), tensorflow=tf.__version__,
                        numpy=np.__version__, keras=tf.keras.__version__, python=sys.version,
                        git_branch=subprocess.check_output(['git','branch','--show-current'], text=True).strip(),
                        git_head=subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip(),
                        devices=[d.name for d in tf.config.list_physical_devices()])
        if metadata['git_branch'] != 'work/gen2-rgb-dma':
            raise ValueError('Wrong branch')
        save(output/'metadata.json', metadata)
        (output/'environment.txt').write_text('\n'.join(sorted(
            f"{d.metadata['Name']}=={d.version}" for d in distributions()))+'\n')
        x,y,xt,yt = load(tf,np)
        train,val = split(np,2026)
        calibration = json.loads((BASE/'calibration.json').read_text())
        ids = np.asarray(calibration['training_indices'],dtype=np.int64)
        if len(ids) != 500 or not np.array_equal(ids, train[:500]):
            raise ValueError('Calibration sample order differs from baseline')
        save(output/'calibration.json', {'seed':2026,'count':len(ids),'training_indices':ids.tolist(),
             'sample_uint8_sha256':hashlib.sha256(x[ids].tobytes()).hexdigest(),
             'source_record_sha256':digest(BASE/'calibration.json'),
             'float_sha256':digest(selected),'preprocessing':'RGB NHWC uint8 / 255'})
        model = tf.keras.models.load_model(selected)
        t0 = time.perf_counter()
        fl,fa = model.evaluate(dataset(tf,xt,yt,128,2026),verbose=0)
        if abs(float(fa)-result['selected_float_test_accuracy']) > 1e-6:
            raise ValueError('Float test accuracy differs from selected training record')
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        def representative():
            for index in ids:
                yield [x[index:index+1].astype(np.float32)/255.]
        converter.representative_dataset = representative
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8
        (output/'int8.tflite').write_bytes(converter.convert())
        lite = interpreter(tf,output/'int8.tflite')
        save(output/'actual_operators.json', [
            {'name':op['op_name'],'inputs':op['inputs'].tolist(),'outputs':op['outputs'].tolist()}
            for op in lite._get_ops_details()])
        export(tf,np,output/'int8.tflite',output)
        meta = json.loads((output/'export.json').read_text())
        if set(t['dtype'] for t in meta['tensors']) != {'int8','int32'}:
            raise ValueError('Unexpected tensor dtype')
        for op in meta['operators']:
            if 'weight' in op and len(op['weight']['scales']) != len(op['bias']['scales']):
                raise ValueError('Expected per-channel bias/weight scales')
            if 'weight' in op and len(op['weight']['scales']) != len(meta['arrays'][f"op{op['order']}_bias"]):
                raise ValueError('Expected per-channel quantization for every output channel')
        inp = lite.get_input_details()[0]; out = lite.get_output_details()[0]
        if inp['dtype'] != np.int8 or out['dtype'] != np.int8:
            raise ValueError('Expected INT8 IO')
        predicted=[]
        for image in xt:
            lite.set_tensor(inp['index'],quant_input(np,image[None],inp)); lite.invoke()
            predicted.append(int(np.argmax(lite.get_tensor(out['index']))))
        ia = float(np.mean(np.asarray(predicted)==yt))
        save(output/'evaluation.json', {'count':len(yt),'float_accuracy':float(fa),'float_loss':float(fl),
            'int8_accuracy':ia,'float_minus_int8_percentage_points':100*(float(fa)-ia),
            'elapsed_seconds':time.perf_counter()-t0,'float_sha256':digest(selected),
            'tflite_sha256':digest(output/'int8.tflite'),'resolver':'BUILTIN_REF',
            'input_rounding':'nearest ties to even, saturate int8'})
        flags = ['cc','-std=c11','-O2','-Wall','-Wextra','-Wconversion','-Werror']
        commands = [flags+['-fPIC','-shared',str(ROOT/'software/reference/kernels.c'),'-o',str(output/'libg2.so')],
                    flags+['-c',str(output/'model_data.c'),'-o',str(output/'model_data.o')]]
        save(output/'build_commands.json',commands)
        for command in commands:
            subprocess.run(command,check=True)
        import test_rgb
        lib = ctypes.CDLL(str(output/'libg2.so'))
        test_rgb.build = lambda: lib
        tests = unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromModule(test_rgb))
        save(output/'unit_tests.json', {'count':tests.testsRun,'passed':tests.wasSuccessful()})
        if not tests.wasSuccessful():
            raise RuntimeError('Existing unit tests failed')
        import verify_model
        # Reuse the unchanged reference driver, redirecting only its IO and build target.
        verify_model.OUT = output
        verify_model.build = lambda: lib
        for count in [100,10000]:
            sys.argv = ['verify_model.py','--limit',str(count)]
            verify_model.main()
            report = json.loads((output/f'native_verification_{count}.json').read_text())
            if not exact(report):
                raise RuntimeError(f'Native numerical gate failed on {count} images; see preserved report')
        m = meta['memory']
        total = sum(m[k] for k in ['weights_bytes','bias_bytes','multiplier_shift_bytes','input_bytes',
                                  'two_fixed_activation_buffers_bytes','gap_and_logits_bytes'])
        save(output/'memory.json', {**m,'model_payload_bytes':m['weights_bytes']+m['bias_bytes']+m['multiplier_shift_bytes'],
             'numeric_payload_plus_buffers_bytes':total,'remaining_of_256KiB_bytes':262144-total,
             'tflite_file_bytes':meta['tflite_bytes'],'complete_firmware_fit':'pending code/stack/descriptors'})
        save(output/'result.json', {'status':'PASS','selected_epoch':59,'unsupported_operators':[],
             'float_accuracy':float(fa),'int8_accuracy':ia,'elapsed_seconds':time.perf_counter()-start,
             'promotion':'recommendation only; original reference unchanged'})
    except BaseException:
        save(output/'failure.json', {'traceback':traceback.format_exc(),'elapsed_seconds':time.perf_counter()-start})
        raise
    finally:
        after = inventory(output)
        check = {'unchanged':before==after,'changed_or_removed':[k for k in before if before[k]!=after.get(k)],
                 'added':sorted(set(after)-set(before))}
        save(output/'protected_integrity.json', check)
        save(output/'output_hashes.json', {p.name:digest(p) for p in sorted(output.iterdir()) if p.is_file()})
        if not check['unchanged']:
            raise RuntimeError('Protected pre-existing files changed')

if __name__ == '__main__':
    main()
