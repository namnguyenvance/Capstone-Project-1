#!/usr/bin/env python3
"""Analytical topology budget; use export.json for measured tensor payloads."""
import json
weights=[3*3*3*16,3*3*16,16*32,3*3*32,32*48,3*3*48,48*64,64*10]
channels=[16,16,32,32,48,48,64,10]
shapes=[(32,32,3),(32,32,16),(32,32,16),(32,32,32),(16,16,32),
        (16,16,48),(8,8,48),(8,8,64),(64,),(10,)]
from math import prod
activations=[prod(s) for s in shapes]
base=sum(weights)+sum(channels)*4+sum(channels)*8+8+activations[0]+2*max(activations[1:])+74
report={'basis':'Analytical requested topology; NOT a trained/exported model measurement',
    'parameters':sum(weights)+sum(channels),'weights_int8_bytes':sum(weights),
    'bias_int32_bytes':sum(channels)*4,'per_channel_multiplier_shift_int32_bytes':sum(channels)*8,
    'gap_multiplier_shift_bytes':8,'activation_shapes_CHW':[(s[-1],*s[:-1]) if len(s)==3 else s for s in shapes],
    'activation_bytes':activations,'input_bytes':activations[0],
    'two_fixed_buffers_bytes':2*max(activations[1:]),'gap_logits_bytes':74,
    'max_adjacent_tensor_bytes':max(a+b for a,b in zip(activations,activations[1:])),
    'numeric_payload_plus_buffers_bytes':base,'ram_limit_bytes':256*1024,
    'remaining_for_code_stack_descriptors_bytes':256*1024-base,
    'illustrative_code_reserve_bytes':32768,'illustrative_stack_reserve_bytes':8192,
    'illustrative_total_bytes':base+32768+8192,
    'feasibility':'Projected to fit; requires actual export, RV32 link map, stack measurement and descriptor sizing.'}
if __name__=='__main__':
    import argparse
    from pathlib import Path
    p=argparse.ArgumentParser()
    p.add_argument('--export',type=Path,help='Use measured export.json tensor payloads')
    a=p.parse_args()
    if a.export:
        exported=json.loads(a.export.read_text())
        m=exported['memory']
        total=sum(m[k] for k in ['weights_bytes','bias_bytes','multiplier_shift_bytes',
            'input_bytes','two_fixed_activation_buffers_bytes','gap_and_logits_bytes'])
        report={'basis':'Actual exported tensor payloads and conservative fixed buffer plan',
            'model_sha256':exported['sha256'],'tflite_file_bytes':exported['tflite_bytes'],
            **m,'numeric_payload_plus_buffers_bytes':total,'ram_limit_bytes':262144,
            'remaining_for_code_stack_descriptors_bytes':262144-total,
            'note':'Do not add TFLite file to numeric payload unless retaining both formats. C array alignment and descriptors are additional. Complete firmware footprint is pending.'}
    print(json.dumps(report,indent=2))
