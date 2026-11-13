#!/usr/bin/env python3
"""Self-contained frozen-reference verifier. Native mode needs only Python + cc."""
import argparse
import ctypes as C
import gzip
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import struct
import subprocess
import sys
import time
import unittest
sys.dont_write_bytecode=True

def sha(data):return hashlib.sha256(data).hexdigest()
def load(path):return json.loads(path.read_text())
def integrity(bundle,pin):
    raw=(bundle/'manifest.json').read_bytes()
    if sha(raw)!=pin:raise ValueError('Manifest does not match pinned SHA-256')
    manifest=json.loads(raw)
    for name,entry in manifest['artifacts'].items():
        rel=Path(name)
        if rel.is_absolute() or '..' in rel.parts:raise ValueError('Unsafe artifact path')
        data=(bundle/rel).read_bytes()
        if len(data)!=entry['bytes'] or sha(data)!=entry['sha256']:raise ValueError(f'Artifact integrity failure: {name}')
    actual={str(p.relative_to(bundle)) for p in bundle.rglob('*') if p.is_file()}
    if actual!=set(manifest['artifacts'])|{'manifest.json'}:raise ValueError('Unexpected version files')
    return manifest

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--bundle',type=Path,required=True);p.add_argument('--manifest-sha',required=True)
    p.add_argument('--mode',choices=['integrity','native','both'],default='integrity')
    p.add_argument('--limit',type=int,choices=[100,10000],default=100)
    p.add_argument('--output',type=Path);p.add_argument('--reexport',action='store_true')
    a=p.parse_args();bundle=a.bundle.resolve();manifest=integrity(bundle,a.manifest_sha)
    if a.mode=='integrity':print(json.dumps({'status':'PASS','version':manifest['version_id'],'files':len(manifest['artifacts'])}));return
    if not a.output:p.error('--output (fresh directory) required for native verification')
    output=a.output.resolve()
    if output==bundle or output.is_relative_to(bundle):p.error('Outputs must be outside the immutable bundle')
    output.mkdir(parents=True,exist_ok=False)
    flags=['cc','-std=c11','-O2','-Wall','-Wextra','-Wconversion','-Werror']
    subprocess.run(flags+['-fPIC','-shared',str(bundle/'tools/kernels.c'),'-o',str(output/'libg2.so')],check=True)
    subprocess.run(flags+['-c',str(bundle/'model/model_data.c'),'-o',str(output/'model_data.o')],check=True)
    lib=C.CDLL(str(output/'libg2.so'))
    sys.path.insert(0,str(bundle/'tools'))
    spec=importlib.util.spec_from_file_location('frozen_unit_tests',bundle/'tools/test_rgb.py')
    tests=importlib.util.module_from_spec(spec);spec.loader.exec_module(tests)
    tests.build=lambda:lib
    unit=unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromModule(tests))
    if not unit.wasSuccessful():raise AssertionError('Frozen arithmetic tests failed')
    meta=load(bundle/'model/export.json');fmt=load(bundle/'dataset/FORMAT.json');gold=load(bundle/'vectors/FORMAT.json')
    def arr(t,v):return (t*len(v))(*v)
    const={k:arr(C.c_int8 if k.endswith('_weights') else C.c_int32,v) for k,v in meta['arrays'].items()}
    first=[gzip.decompress((bundle/s['path']).read_bytes()) for s in gold['layers']]
    expected_logits=gzip.decompress((bundle/gold['full_logits_path']).read_bytes())
    labels=(bundle/fmt['labels']).read_bytes()
    hs=[hashlib.sha256() for _ in first]
    tfhs=[hashlib.sha256() for _ in first]
    tensor_equal=[0]*9;max_error=[0]*9;native_correct=agreement=logit_exact=0
    started=time.perf_counter();versions={}
    lite=None
    if a.mode=='both':
        import tensorflow as tf
        import numpy as np
        versions={'tensorflow':tf.__version__,'numpy':np.__version__}
        lite=tf.lite.Interpreter(model_path=str(bundle/'model/int8.tflite'),num_threads=1,
            experimental_preserve_all_tensors=True,
            experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF)
        lite.allocate_tensors();inp=lite.get_input_details()[0]['index']
        if a.reexport:
            import export
            target=output/'reexport';target.mkdir()
            export.export(tf,np,bundle/'model/int8.tflite',target)
            for name in ['export.json','model_data.c','model_data.h']:
                if (target/name).read_bytes()!=(bundle/'model'/name).read_bytes():raise AssertionError(f'Re-export mismatch: {name}')
    stage_bytes=0
    for shard in fmt['shards']:
        if shard['first_index']>=a.limit:break
        data=gzip.decompress((bundle/shard['path']).read_bytes())
        if len(data)!=shard['decoded_bytes'] or sha(data)!=shard['decoded_sha256']:raise ValueError('Decoded dataset hash failure')
        for local in range(min(shard['count'],a.limit-shard['first_index'])):
            index=shard['first_index']+local;raw=data[local*3072:(local+1)*3072]
            x=(C.c_int8*3072).from_buffer_copy(raw)
            if lite:
                lite.set_tensor(inp,np.frombuffer(raw,dtype=np.int8).reshape(1,3,32,32).transpose(0,2,3,1));lite.invoke()
            for j,op in enumerate(meta['operators']):
                n=math.prod(op['output']['shape']);result=(C.c_int8*n)()
                iz=op['input']['zero_points'][0];oz=op['output']['zero_points'][0]
                traces=[(C.c_int32*n)() for _ in range(3)] if index==0 and j==0 else [None]*3
                if op['op'] in ['CONV_2D','DEPTHWISE_CONV_2D']:
                    _,h,w,ci=op['input']['shape'];_,oh,ow,co=op['output']['shape'];kh,kw=op['weight_shape'][-2:]
                    lib.g2_conv(x,const[f'op{j}_weights'],const[f'op{j}_bias'],h,w,ci,co,kh,kw,
                        op['stride'],op['pad_top'],op['pad_left'],oh,ow,iz,oz,const[f'op{j}_mult'],
                        const[f'op{j}_shift'],op['activation_min'],op['activation_max'],
                        int(op['op']=='DEPTHWISE_CONV_2D'),result,*traces)
                elif op['op']=='MEAN':
                    _,h,w,c=op['input']['shape'];lib.g2_mean(x,h*w,c,iz,oz,*op['multiplier'],result)
                elif op['op']=='FULLY_CONNECTED':
                    co,ci=op['weight_shape'];lib.g2_fc(x,const[f'op{j}_weights'],const[f'op{j}_bias'],ci,co,iz,oz,const[f'op{j}_mult'],const[f'op{j}_shift'],result)
                else:raise ValueError('Unsupported operator')
                got=bytes(result);hs[j].update(got);stage_bytes+=n
                if index<100 and got!=first[j][index*n:(index+1)*n]:raise AssertionError(f'Golden tensor mismatch image {index} layer {j}')
                if index==0 and j==0:
                    for name,trace in zip(['raw','biased','requant'],traces):
                        if struct.pack('<'+str(n)+'i',*trace)!=gzip.decompress((bundle/f'vectors/conv0_image0.{name}.le_i32.gz').read_bytes()):
                            raise AssertionError(f'Conv0 {name} stage mismatch')
                if lite:
                    ref=lite.get_tensor(op['output']['index'])
                    if ref.ndim==4:ref=ref.transpose(0,3,1,2)
                    ref=ref.tobytes();tfhs[j].update(ref)
                    if got==ref:tensor_equal[j]+=n
                    else:
                        delta=[abs((u if u<128 else u-256)-(v if v<128 else v-256)) for u,v in zip(got,ref)]
                        tensor_equal[j]+=sum(d==0 for d in delta);max_error[j]=max(max_error[j],max(delta))
                x=result
            if bytes(x)!=expected_logits[index*10:(index+1)*10]:raise AssertionError(f'Golden logits mismatch image {index}')
            native_pred=max(range(10),key=lambda c:x[c]);native_correct+=int(native_pred==labels[index]);logit_exact+=1
            if lite:agreement+=int(native_pred==int(np.argmax(lite.get_tensor(meta['operators'][-1]['output']['index']))))
            if (index+1)%1000==0:print(f'Promoted reference images {index+1}/{a.limit}',flush=True)
    if a.limit==10000:
        for j,entry in enumerate(gold['layers']):
            if hs[j].hexdigest()!=entry['full_sha256']:raise AssertionError(f'Full native layer digest mismatch {j}')
            if lite and tfhs[j].hexdigest()!=entry['full_sha256']:raise AssertionError(f'Full TFLite layer digest mismatch {j}')
        if native_correct!=6130:raise AssertionError('Accuracy count mismatch')
    if lite and (any(max_error) or agreement!=a.limit):raise AssertionError('Native/TFLite exactness failure')
    integrity(bundle,a.manifest_sha)
    report={'status':'PASS','version_id':manifest['version_id'],'manifest_sha256':a.manifest_sha,
        'mode':a.mode,'count':a.limit,'native_correct':native_correct,'native_accuracy':native_correct/a.limit,
        'golden_logits_exact':logit_exact,'golden_first100_all_layers_exact':True,'conv0_arithmetic_stages_exact':True,
        'full_layer_stream_digests_exact':a.limit==10000,'native_tflite_prediction_agreement':agreement/a.limit if lite else None,
        'native_tflite_equal_elements':tensor_equal if lite else None,'maximum_absolute_differences':max_error if lite else None,
        'layer_elements_processed':stage_bytes,'unit_tests':unit.testsRun,'reexport_exact':bool(a.reexport and lite),
        'elapsed_seconds':time.perf_counter()-started,'versions':versions,'rtl_equivalence':'not claimed'}
    (output/'verification.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
