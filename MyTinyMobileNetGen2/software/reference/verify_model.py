#!/usr/bin/env python3
"""Host orchestration of C kernels using actual exported INT8 parameters.
Reports label accuracy, prediction agreement and numerical differences separately.
"""
import argparse
import ctypes as C
import hashlib
import json
from pathlib import Path
import sys
import time
from test_rgb import ROOT, arr, build
sys.path.insert(0,str(ROOT/'model'))
from pipeline import interpreter, load, quant_input, OUT

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--limit',type=int,default=100)
    a=p.parse_args()
    if not 1<=a.limit<=10000: p.error('limit must be 1..10000')
    try:
        import numpy as np
        import tensorflow as tf
    except ImportError as e:
        p.exit(2,f'ML dependency unavailable: {e}. See requirements.txt.\n')
    meta=json.loads((OUT/'export.json').read_text())
    path=OUT/'int8.tflite'
    if hashlib.sha256(path.read_bytes()).hexdigest()!=meta['sha256']:
        p.error('Export belongs to a different TFLite model; export again')
    lib=build(); _,_,images,labels=load(tf,np)
    lite=interpreter(tf,path)
    inp=lite.get_input_details()[0]; output=lite.get_output_details()[0]
    constants={k:arr(C.c_int8 if k.endswith('_weights') else C.c_int32,v)
               for k,v in meta['arrays'].items()}
    stages=[{'operator':o['op'],'tensor':o['output']['index'],'equal_elements':0,
             'elements':0,'max_abs_difference':0} for o in meta['operators']]
    agreement=native_correct=lite_correct=exact_logits=0
    started=time.perf_counter()
    for index,image in enumerate(images[:a.limit]):
        q=quant_input(np,image[None],inp)
        lite.set_tensor(inp['index'],q); lite.invoke()
        x=arr(C.c_int8,q.transpose(0,3,1,2).ravel().tolist())
        for j,op in enumerate(meta['operators']):
            shape=op['output']['shape']; n=int(np.prod(shape))
            result=(C.c_int8*n)()
            iz=op['input']['zero_points'][0]; oz=op['output']['zero_points'][0]
            if op['op'] in ['CONV_2D','DEPTHWISE_CONV_2D']:
                _,h,w,ci=op['input']['shape']; _,oh,ow,co=shape
                kh,kw=op['weight_shape'][-2:]
                lib.g2_conv(x,constants[f'op{j}_weights'],constants[f'op{j}_bias'],
                    h,w,ci,co,kh,kw,op['stride'],op['pad_top'],op['pad_left'],oh,ow,iz,oz,
                    constants[f'op{j}_mult'],constants[f'op{j}_shift'],
                    op['activation_min'],op['activation_max'],int(op['op']=='DEPTHWISE_CONV_2D'),
                    result,None,None,None)
            elif op['op']=='MEAN':
                _,h,w,c=op['input']['shape']
                lib.g2_mean(x,h*w,c,iz,oz,*op['multiplier'],result)
            elif op['op']=='FULLY_CONNECTED':
                co,ci=op['weight_shape']
                lib.g2_fc(x,constants[f'op{j}_weights'],constants[f'op{j}_bias'],ci,co,iz,oz,
                    constants[f'op{j}_mult'],constants[f'op{j}_shift'],result)
            else: raise ValueError('Unsupported operator')
            ref=lite.get_tensor(op['output']['index'])
            if ref.ndim==4: ref=ref.transpose(0,3,1,2)
            delta=np.abs(np.asarray(list(result),dtype=np.int32)-ref.ravel().astype(np.int32))
            stages[j]['equal_elements']+=int(np.count_nonzero(delta==0))
            stages[j]['elements']+=n
            stages[j]['max_abs_difference']=max(stages[j]['max_abs_difference'],int(delta.max()))
            x=result
        native=np.array(list(x)); ref=lite.get_tensor(output['index']).ravel()
        nc=int(native.argmax()); lc=int(ref.argmax())
        agreement+=int(nc==lc); exact_logits+=int(np.array_equal(native,ref))
        native_correct+=int(nc==labels[index]); lite_correct+=int(lc==labels[index])
        if (index+1)%1000==0: print(f'Compared {index+1}/{a.limit}',flush=True)
    report={'elapsed_seconds':time.perf_counter()-started,'sample_selection':'first N CIFAR-10 test images in dataset order','count':a.limit,'native_accuracy':native_correct/a.limit,
        'tflite_accuracy':lite_correct/a.limit,'prediction_agreement':agreement/a.limit,
        'exact_logits_images':exact_logits,'stages':stages,'model_sha256':meta['sha256'],
        'reference_resolver':'BUILTIN_REF','rtl_equivalence':'not tested; Gen 2 RTL absent',
        'optimization_equivalence':'not tested; no optimized Gen 2 implementation'}
    (OUT/f'native_verification_{a.limit}.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
if __name__=='__main__': main()
