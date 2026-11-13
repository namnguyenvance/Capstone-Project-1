#!/usr/bin/env python3
"""Create a new immutable release once; refuses to overwrite any version."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[1]
VERSION='gen2b-cifar10-a59-int8-v1'
CANDIDATE=ROOT/'model/experiments/constant60_epoch59_int8'
RELEASE=ROOT/'model/references'/VERSION

def sha(data): return hashlib.sha256(data).hexdigest()
def dump(path,data): path.write_text(json.dumps(data,indent=2)+'\n')
def compressed(path,data): path.write_bytes(gzip.compress(data,compresslevel=9,mtime=0))

def main():
    if RELEASE.exists(): raise FileExistsError(RELEASE)
    checks=json.loads((CANDIDATE/'final_output_hashes.json').read_text())
    for name,wanted in checks.items():
        assert sha((CANDIDATE/name).read_bytes())==wanted,name
    assert json.loads((CANDIDATE/'result.json').read_text())['status']=='PASS'
    assert json.loads((CANDIDATE/'metadata.json').read_text())['selected_epoch']==59
    preserve={str(p.relative_to(ROOT)):sha(p.read_bytes()) for base in ['model/generated','model/experiments','build']
              for p in (ROOT/base).rglob('*') if p.is_file()}
    RELEASE.mkdir()
    for sub in ['model','evidence','tools','vectors','dataset']: (RELEASE/sub).mkdir()
    for name in ['float.keras','int8.tflite','export.json','model_data.c','model_data.h']:
        shutil.copyfile(CANDIDATE/name,RELEASE/'model'/name)
    for name in ['metadata.json','calibration.json','evaluation.json','memory.json','environment.txt',
                 'native_verification_100.json','native_verification_10000.json','unit_tests.json','result.json',
                 'protected_integrity.json','final_output_hashes.json']:
        shutil.copyfile(CANDIDATE/name,RELEASE/'evidence'/name)
    for source,name in [('software/reference/kernels.c','kernels.c'),('software/reference/test_rgb.py','test_rgb.py'),
                        ('model/quantization/export.py','export.py'),('model/training/network.py','network.py')]:
        shutil.copyfile(ROOT/source,RELEASE/'tools'/name)
    shutil.copyfile(ROOT/'scripts/reference_engine.py',RELEASE/'tools/reference_engine.py')
    shutil.copyfile(ROOT/'scripts/REFERENCE_CONTRACT.md',RELEASE/'CONTRACT.md')
    (RELEASE/'requirements.txt').write_text('tensorflow-cpu==2.18.1\nnumpy==2.0.2\nkeras==3.15.1\nh5py==3.16.0\n')
    sys.path.insert(0,str(ROOT/'model'))
    from pipeline import load,split,interpreter,quant_input
    import tensorflow as tf
    import numpy as np
    tf.keras.utils.set_random_seed(2026)
    x,y,xt,yt=load(tf,np)
    meta=json.loads((RELEASE/'model/export.json').read_text())
    lite=interpreter(tf,RELEASE/'model/int8.tflite')
    inp=lite.get_input_details()[0]
    records=[]
    for start in range(0,10000,1000):
        q=quant_input(np,xt[start:start+1000],inp).transpose(0,3,1,2).copy()
        assert np.array_equal(q.view(np.uint8),xt[start:start+1000].transpose(0,3,1,2)^128)
        data=q.tobytes();name=f'test_{start:05d}_{start+999:05d}.chw.i8.gz'
        compressed(RELEASE/'dataset'/name,data)
        records.append({'path':'dataset/'+name,'first_index':start,'count':1000,'decoded_bytes':len(data),'decoded_sha256':sha(data)})
    (RELEASE/'dataset/labels.u8').write_bytes(yt.astype(np.uint8).tobytes())
    ids=json.loads((CANDIDATE/'calibration.json').read_text())['training_indices']
    compressed(RELEASE/'dataset/calibration.nhwc.u8.gz',x[ids].tobytes())
    assert sha(x[ids].tobytes())==json.loads((CANDIDATE/'calibration.json').read_text())['sample_uint8_sha256']
    dump(RELEASE/'dataset/FORMAT.json',{'test_count':10000,'test_input_shape':[3,32,32],
        'test_dtype':'int8','test_order':'CIFAR-10 original test order','shards':records,
        'labels':'dataset/labels.u8','calibration_shape':[500,32,32,3],'calibration_dtype':'uint8',
        'source':'https://www.cs.toronto.edu/~kriz/cifar.html','class_names':['airplane','automobile','bird','cat','deer','dog','frog','horse','ship','truck'],
        'preprocessing':'RGB uint8 / 255; nearest ties-to-even quantization with INT8 saturation',
        'test_recovery':'NHWC uint8 recovered by CHW->HWC then xor 128 for this input scale/zero point'})
    hashes=[hashlib.sha256() for _ in meta['operators']];first=[bytearray() for _ in hashes]
    logits=bytearray();correct=0
    for index,image in enumerate(xt):
        lite.set_tensor(inp['index'],quant_input(np,image[None],inp));lite.invoke()
        for j,op in enumerate(meta['operators']):
            a=lite.get_tensor(op['output']['index'])
            if a.ndim==4:a=a.transpose(0,3,1,2)
            data=a.tobytes();hashes[j].update(data)
            if index<100:first[j].extend(data)
        score=lite.get_tensor(lite.get_output_details()[0]['index']).ravel()
        logits.extend(score.tobytes());correct+=int(np.argmax(score)==yt[index])
        if (index+1)%1000==0:print('Golden TFLite images',index+1,flush=True)
    assert correct==6130
    vectors=[]
    for j,(op,data,h) in enumerate(zip(meta['operators'],first,hashes)):
        name=f'layer{j:02d}.first100.chw.i8.gz';compressed(RELEASE/'vectors'/name,bytes(data))
        vectors.append({'operator':op['op'],'order':j,'shape':op['output']['shape'][1:],
                        'path':'vectors/'+name,'count':100,'full_count':10000,
                        'full_bytes':len(data)*100,'full_sha256':h.hexdigest()})
    compressed(RELEASE/'vectors/logits10000.i8.gz',bytes(logits))
    dump(RELEASE/'vectors/FORMAT.json',{'source':'TensorFlow 2.18.1 BUILTIN_REF, no delegates',
        'layout':'CHW for 3D activations; natural vector order for GAP/FC; sample-major',
        'layers':vectors,'full_logits_path':'vectors/logits10000.i8.gz','test_correct':correct,
        'meaning':'First 100 layer tensors are stored in full; every full-test layer stream has a SHA-256 digest.'})
    # Independent Python raw/bias/requant stages for a real RGB Conv0 image.
    sys.path.insert(0,str(RELEASE/'tools'))
    from test_rgb import requant
    op=meta['operators'][0];arrays=meta['arrays'];q=quant_input(np,xt[:1],inp)[0].transpose(2,0,1).astype(np.int32)
    w=np.array(arrays['op0_weights'],dtype=np.int32).reshape(16,3,3,3)
    raw=np.zeros((16,32,32),dtype='<i4')
    # Offset padded planes followed by an independently vectorized integer oracle.
    centered=np.pad(q-op['input']['zero_points'][0],((0,0),(1,1),(1,1)))
    for ky in range(3):
        for kx in range(3):raw+=np.einsum('oc,cyx->oyx',w[:,:,ky,kx],centered[:,ky:ky+32,kx:kx+32],dtype=np.int32)
    biased=raw+np.array(arrays['op0_bias'],dtype=np.int32)[:,None,None]
    scaled=np.array([requant(int(biased[c,y,z]),op['multiplier'][c],op['shift'][c])
                     for c in range(16) for y in range(32) for z in range(32)],dtype='<i4').reshape(16,32,32)
    final=np.clip(scaled+op['output']['zero_points'][0],op['activation_min'],op['activation_max']).astype(np.int8)
    assert final.tobytes()==bytes(first[0][:16*32*32])
    for name,a in [('raw',raw),('biased',biased),('requant',scaled)]:compressed(RELEASE/'vectors'/f'conv0_image0.{name}.le_i32.gz',a.astype('<i4').tobytes())
    manifest={'schema_version':1,'version_id':VERSION,'selected_epoch':59,'source_model_sha256':sha((CANDIDATE/'float.keras').read_bytes()),
        'tflite_sha256':meta['sha256'],'float_accuracy':0.6172,'int8_accuracy':0.613,'parameter_count':7322,'macs_per_image':1805952,
        'immutable_policy':'Never edit this directory after promotion; create a new version and update active.json for any change.',
        'scope':'Software golden reference; RTL/timing/complete firmware memory not verified',
        'artifacts':{str(p.relative_to(RELEASE)):{'bytes':p.stat().st_size,'sha256':sha(p.read_bytes())}
                     for p in sorted(RELEASE.rglob('*')) if p.is_file()}}
    dump(RELEASE/'manifest.json',manifest)
    dump(ROOT/'model/references/active.json',{'version_id':VERSION,'manifest_sha256':sha((RELEASE/'manifest.json').read_bytes())})
    assert all(sha((ROOT/name).read_bytes())==wanted for name,wanted in preserve.items())
    (ROOT/'build/reference_promotion_integrity.json').write_text(json.dumps({'preserved_file_count':len(preserve),'unchanged':True},indent=2)+'\n')
    print('Release bytes',sum(a['bytes'] for a in manifest['artifacts'].values()),flush=True)
    print('Manifest SHA256',sha((RELEASE/'manifest.json').read_bytes()),flush=True)
if __name__=='__main__':main()
