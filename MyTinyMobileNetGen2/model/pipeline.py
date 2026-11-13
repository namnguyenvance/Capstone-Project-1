#!/usr/bin/env python3
"""Train, calibrate, evaluate and export the independent Gen 2 baseline."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'model/generated'
os.environ.setdefault('KERAS_HOME',str(OUT/'keras_cache'))
os.environ.setdefault('TF_DETERMINISTIC_OPS','1')
sys.path.insert(0,str(Path(__file__).parent/'training'))

def write(name,data):
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/name).write_text(json.dumps(data,indent=2)+'\n')

def load(tf,np):
    (x,y),(xt,yt)=tf.keras.datasets.cifar10.load_data()
    assert x.shape==(50000,32,32,3) and xt.shape==(10000,32,32,3)
    return x,y.ravel(),xt,yt.ravel()

def split(np,seed):
    order=np.random.default_rng(seed).permutation(50000)
    return order[:45000],order[45000:]

def dataset(tf,x,y,batch,seed,shuffle=False):
    d=tf.data.Dataset.from_tensor_slices((x,y))
    if shuffle: d=d.shuffle(len(x),seed=seed,reshuffle_each_iteration=True)
    return d.map(lambda a,b:(tf.cast(a,tf.float32)/255.,b),
                 num_parallel_calls=1,deterministic=True).batch(batch).prefetch(1)

def quant_input(np,x,detail):
    scale,zp=detail['quantization']
    if scale<=0: raise ValueError('Invalid activation quantization')
    return np.clip(np.rint(x.astype(np.float32)/255./scale+zp),-128,127).astype(np.int8)

def interpreter(tf,path):
    # Reference kernels, no XNNPACK delegate: reproducible comparison target.
    i=tf.lite.Interpreter(model_path=str(path),num_threads=1,
        experimental_preserve_all_tensors=True,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF)
    i.allocate_tensors()
    return i

def main():
    p=argparse.ArgumentParser()
    p.add_argument('command',choices=['topology','train','quantize','evaluate','export'])
    p.add_argument('--seed',type=int,default=2026)
    p.add_argument('--epochs',type=int,default=30)
    p.add_argument('--batch-size',type=int,default=128)
    p.add_argument('--calibration',type=int,default=500)
    p.add_argument('--limit',type=int,default=10000)
    a=p.parse_args()
    if a.epochs<1 or not 1<=a.calibration<=45000 or not 1<=a.limit<=10000:
        p.error('epochs >=1, calibration 1..45000, limit 1..10000 required')
    try:
        import tensorflow as tf
        import numpy as np
    except ImportError as e:
        p.exit(2,f'ML dependency unavailable: {e}. Use Python 3.11/3.12 and requirements.txt.\n')
    from network import build
    tf.keras.utils.set_random_seed(a.seed)
    tf.config.experimental.enable_op_determinism()
    OUT.mkdir(parents=True,exist_ok=True)
    keras_path=OUT/'float.keras'; lite_path=OUT/'int8.tflite'
    if a.command=='topology':
        model,shapes=build(tf)
        model.summary()
        write('architecture.json',{'shapes':shapes,'parameters':model.count_params()})
        return
    if a.command=='export':
        sys.path.insert(0,str(Path(__file__).parent/'quantization'))
        from export import export
        export(tf,np,lite_path,OUT)
        return
    load_start=time.perf_counter()
    x,y,xt,yt=load(tf,np)
    load_seconds=time.perf_counter()-load_start
    train,val=split(np,a.seed)
    if a.command=='train':
        model,shapes=build(tf)
        model.compile(optimizer=tf.keras.optimizers.Adam(0.001),
            loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),metrics=['accuracy'])
        callbacks=[tf.keras.callbacks.CSVLogger(str(OUT/'training.csv')),
            tf.keras.callbacks.ModelCheckpoint(str(OUT/'best.keras'),monitor='val_accuracy',save_best_only=True)]
        fit_start=time.perf_counter()
        history=model.fit(dataset(tf,x[train],y[train],a.batch_size,a.seed,True),
            validation_data=dataset(tf,x[val],y[val],a.batch_size,a.seed),epochs=a.epochs,callbacks=callbacks,verbose=2)
        fit_seconds=time.perf_counter()-fit_start
        # Final epoch model is the measured/conversion artifact; best checkpoint is separate.
        model.save(keras_path)
        loss,acc=model.evaluate(dataset(tf,xt,yt,a.batch_size,a.seed),verbose=0)
        write('training.json',{'seed':a.seed,'epochs':a.epochs,'batch_size':a.batch_size,
            'training_seconds':fit_seconds,'dataset_load_seconds':load_seconds,
            'thread_settings':{k:os.environ.get(k) for k in ['TF_NUM_INTRAOP_THREADS','TF_NUM_INTEROP_THREADS','OMP_NUM_THREADS']},
            'optimizer':'Adam(0.001)','preprocessing':'RGB uint8 / 255, NHWC',
            'split':'seeded permutation: 45000 train / 5000 validation',
            'parameter_count':model.count_params(),'shapes':shapes,'history':history.history,
            'training_accuracy':history.history['accuracy'][-1],
            'validation_accuracy':history.history['val_accuracy'][-1],
            'test_accuracy':float(acc),'test_loss':float(loss),'test_count':len(yt),
            'float_sha256':hashlib.sha256(keras_path.read_bytes()).hexdigest(),
            'tensorflow':tf.__version__,'numpy':np.__version__,
            'devices':[d.name for d in tf.config.list_physical_devices()],
            'split_sha256':hashlib.sha256(train.tobytes()+val.tobytes()).hexdigest()})
    elif a.command=='quantize':
        record=json.loads((OUT/'training.json').read_text())
        if record['seed']!=a.seed: p.error('Seed must match training.json')
        model=tf.keras.models.load_model(keras_path)
        conv=tf.lite.TFLiteConverter.from_keras_model(model)
        conv.optimizations=[tf.lite.Optimize.DEFAULT]
        ids=train[:a.calibration]
        def representative():
            for j in ids: yield [x[j:j+1].astype(np.float32)/255.]
        conv.representative_dataset=representative
        conv.target_spec.supported_ops=[tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        conv.inference_input_type=tf.int8; conv.inference_output_type=tf.int8
        lite_path.write_bytes(conv.convert())
        write('calibration.json',{'seed':a.seed,'count':len(ids),'training_indices':ids.tolist(),
            'float_sha256':hashlib.sha256(keras_path.read_bytes()).hexdigest()})
        i=interpreter(tf,lite_path)
        assert i.get_input_details()[0]['dtype']==np.int8
        assert i.get_output_details()[0]['dtype']==np.int8
        sys.path.insert(0,str(Path(__file__).parent/'quantization'))
        from export import export
        export(tf,np,lite_path,OUT)
    else:
        calibration=json.loads((OUT/'calibration.json').read_text())
        exported=json.loads((OUT/'export.json').read_text())
        if calibration['float_sha256']!=hashlib.sha256(keras_path.read_bytes()).hexdigest():
            p.error('Float model changed since calibration; quantize again')
        if exported['sha256']!=hashlib.sha256(lite_path.read_bytes()).hexdigest():
            p.error('TFLite changed since export; quantize/export again')
        model=tf.keras.models.load_model(keras_path)
        i=interpreter(tf,lite_path)
        inp=i.get_input_details()[0]; out=i.get_output_details()[0]
        evaluation_start=time.perf_counter()
        pred=[]
        for image in xt[:a.limit]:
            i.set_tensor(inp['index'],quant_input(np,image[None],inp)); i.invoke()
            pred.append(int(np.argmax(i.get_tensor(out['index']))))
        fp=np.argmax(model.predict(xt[:a.limit].astype(np.float32)/255.,batch_size=a.batch_size,verbose=0),axis=1)
        fa=float(np.mean(fp==yt[:a.limit])); qa=float(np.mean(np.array(pred)==yt[:a.limit]))
        write('evaluation.json',{'elapsed_seconds':time.perf_counter()-evaluation_start,'count':a.limit,'float_accuracy':fa,'int8_accuracy':qa,
            'float_minus_int8_percentage_points':100*(fa-qa),
            'float_int8_prediction_agreement':float(np.mean(fp==pred)),
            'tflite_sha256':hashlib.sha256(lite_path.read_bytes()).hexdigest(),
            'float_sha256':hashlib.sha256(keras_path.read_bytes()).hexdigest(),
            'resolver':'BUILTIN_REF','input_rounding':'nearest ties to even, saturate int8'})
        print((OUT/'evaluation.json').read_text())
if __name__=='__main__': main()
