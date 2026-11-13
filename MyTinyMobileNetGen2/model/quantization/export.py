"""Inspect the actual FlatBuffer; export only a validated supported graph.
No dependence on Gen 1 names, generated headers, or MMIO conventions.
"""
import hashlib
import json
import math

def multiplier(real):
    if real<=0 or not math.isfinite(real): raise ValueError('Invalid multiplier')
    mantissa,exp=math.frexp(real)
    q=math.floor(mantissa*2**31+0.5)
    if q==2**31: q//=2; exp+=1
    shift=-exp
    if not -30<=shift<=31: raise ValueError('Multiplier outside native shift range')
    return q,shift

def export(tf,np,path,out):
    from tensorflow.lite.python import schema_py_generated as schema
    blob=path.read_bytes()
    model=schema.Model.GetRootAsModel(blob,0)
    if model.SubgraphsLength()!=1: raise ValueError('One subgraph required')
    graph=model.Subgraphs(0)
    i=tf.lite.Interpreter(model_content=blob,experimental_preserve_all_tensors=True,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF)
    i.allocate_tensors()
    details={d['index']:d for d in i.get_tensor_details()}
    def desc(index):
        d=details[index]; q=d['quantization_parameters']
        return {'index':index,'name':d['name'],'shape':d['shape'].tolist(),
            'dtype':np.dtype(d['dtype']).name,'scales':q['scales'].tolist(),
            'zero_points':q['zero_points'].tolist(),'quantized_dimension':int(q['quantized_dimension'])}
    names={v:k for k,v in vars(schema.BuiltinOperator).items() if isinstance(v,int)}
    operations=[]; arrays={}; params=0; weights_bytes=0; bias_bytes=0; quant_bytes=0
    expected=['CONV_2D','DEPTHWISE_CONV_2D','CONV_2D','DEPTHWISE_CONV_2D',
              'CONV_2D','DEPTHWISE_CONV_2D','CONV_2D','MEAN','FULLY_CONNECTED']
    for j in range(graph.OperatorsLength()):
        op=graph.Operators(j)
        code=model.OperatorCodes(op.OpcodeIndex()).BuiltinCode()
        name=names.get(code,str(code))
        if name not in set(expected): raise ValueError(f'Unsupported actual operator {name}')
        ins=op.InputsAsNumpy().tolist(); outs=op.OutputsAsNumpy().tolist()
        if len(outs)!=1: raise ValueError('One output required')
        src,dst=desc(ins[0]),desc(outs[0])
        if src['dtype']!='int8' or dst['dtype']!='int8': raise ValueError('INT8 activations required')
        if len(src['scales'])!=1 or len(dst['scales'])!=1: raise ValueError('Per-tensor activations required')
        rec={'order':j,'op':name,'inputs':ins,'outputs':outs,'input':src,'output':dst}
        table=op.BuiltinOptions()
        if name=='MEAN':
            opts=schema.ReducerOptions(); opts.Init(table.Bytes,table.Pos)
            axes=i.get_tensor(ins[1]).tolist()
            if axes!=[1,2] or opts.KeepDims(): raise ValueError('Expected spatial mean without keepdims')
            spatial=math.prod(src['shape'][1:3])
            rec.update(multiplier=list(multiplier(src['scales'][0]/dst['scales'][0]/spatial)),axes=axes)
            quant_bytes+=8
        else:
            if len(ins)!=3 or ins[2]<0: raise ValueError('Explicit bias required')
            wd,bd=desc(ins[1]),desc(ins[2]); w=i.get_tensor(ins[1]); b=i.get_tensor(ins[2])
            if wd['dtype']!='int8' or bd['dtype']!='int32': raise ValueError('INT8 weights / INT32 biases required')
            if any(wd['zero_points']) or any(bd['zero_points']): raise ValueError('Symmetric weights / biases required')
            if name=='CONV_2D':
                opts=schema.Conv2DOptions(); opts.Init(table.Bytes,table.Pos)
                if opts.DilationHFactor()!=1 or opts.DilationWFactor()!=1: raise ValueError('Dilation unsupported')
                w=w.transpose(0,3,1,2).copy(); layout='OIHW'
            elif name=='DEPTHWISE_CONV_2D':
                opts=schema.DepthwiseConv2DOptions(); opts.Init(table.Bytes,table.Pos)
                if opts.DepthMultiplier()!=1 or opts.DilationHFactor()!=1 or opts.DilationWFactor()!=1:
                    raise ValueError('Only depth multiplier 1 without dilation')
                w=w[0].transpose(2,0,1).copy(); layout='CHW'
            else:
                opts=schema.FullyConnectedOptions(); opts.Init(table.Bytes,table.Pos)
                if opts.WeightsFormat()!=schema.FullyConnectedOptionsWeightsFormat.DEFAULT:
                    raise ValueError('Non-default FC weights')
                layout='OI'
            activation=opts.FusedActivationFunction()
            if activation not in [schema.ActivationFunctionType.NONE,schema.ActivationFunctionType.RELU6]:
                raise ValueError('Unsupported fused activation')
            lo,hi=-128,127
            if activation==schema.ActivationFunctionType.RELU6:
                oz=dst['zero_points'][0]; scale=dst['scales'][0]
                lo=max(-128,oz); hi=min(127,math.floor(6/scale+0.5)+oz)
            co=int(b.size)
            ws=np.asarray(wd['scales'],dtype=np.float64)
            expected_axis=3 if name=='DEPTHWISE_CONV_2D' else 0
            if ws.size not in [1,co] or (ws.size>1 and wd['quantized_dimension']!=expected_axis):
                raise ValueError('Unexpected per-channel quantization axis')
            effective=src['scales'][0]*ws/dst['scales'][0]
            scales=src['scales'][0]*ws
            if not np.allclose(bd['scales'],scales,rtol=1e-5,atol=1e-12):
                raise ValueError('Bias scales must equal input scale * weight scale')
            if ws.size==1: effective=np.repeat(effective,co)
            pairs=[multiplier(float(v)) for v in effective]
            m=[v[0] for v in pairs]; s=[v[1] for v in pairs]
            terms=int(w.size)//co
            if int(np.max(np.abs(b.astype(np.int64))))+terms*255*128>2**31-1:
                raise ValueError('Potential int32 accumulation overflow')
            arrays[f'op{j}_weights']=w.ravel().tolist(); arrays[f'op{j}_bias']=b.tolist()
            arrays[f'op{j}_mult']=m; arrays[f'op{j}_shift']=s
            rec.update(weight=wd,bias=bd,weight_shape=list(w.shape),weight_layout=layout,
                multiplier=m,shift=s,activation_min=lo,activation_max=hi,
                fused_activation='RELU6' if activation else 'NONE')
            if name!='FULLY_CONNECTED':
                sh,sw=opts.StrideH(),opts.StrideW()
                if sh!=sw or sh not in [1,2]: raise ValueError('Unsupported stride')
                if opts.Padding()!=schema.Padding.SAME: raise ValueError('Expected SAME padding')
                kh,kw=w.shape[-2:]; ih,iw=src['shape'][1:3]; oh,ow=dst['shape'][1:3]
                rec.update(stride=sh,pad_top=max(0,(oh-1)*sh+kh-ih)//2,
                           pad_left=max(0,(ow-1)*sw+kw-iw)//2)
            params+=int(w.size+b.size); weights_bytes+=int(w.nbytes); bias_bytes+=int(b.nbytes)
            quant_bytes+=8*co
        if operations and src['index']!=operations[-1]['output']['index']:
            raise ValueError('Only a sequential graph is supported')
        operations.append(rec)
    if [o['op'] for o in operations]!=expected: raise ValueError('Actual topology differs')
    from network import EXPECTED
    shapes=[tuple(operations[0]['input']['shape'][1:])]+[tuple(o['output']['shape'][1:]) for o in operations]
    if shapes!=EXPECTED or params!=7322: raise ValueError(f'Unexpected shapes/parameters: {shapes}, {params}')
    activations=[math.prod(t) for t in shapes]
    report={'schema_version':1,'sha256':hashlib.sha256(blob).hexdigest(),'tflite_bytes':len(blob),
        'parameter_count':params,'shift_convention':'positive right, negative saturating left',
        'rounding':'Q31 double rounding; highmul ties toward +infinity; divide ties away from zero',
        'activation_layout':'CHW; TFLite NHWC must transpose (0,3,1,2)',
        'operators':operations,'tensors':[desc(k) for k in sorted(details)],'arrays':arrays,
        'memory':{'weights_bytes':weights_bytes,'bias_bytes':bias_bytes,'multiplier_shift_bytes':quant_bytes,
            'input_bytes':activations[0],'two_fixed_activation_buffers_bytes':2*max(activations[1:]),
            'gap_and_logits_bytes':74,'max_adjacent_activation_bytes':max(a+b for a,b in zip(activations,activations[1:])),
            'firmware_code_bytes':None,'stack_bytes':None,'note':'Payload counts only; descriptors, code and stack must be measured in later firmware.'}}
    (out/'export.json').write_text(json.dumps(report,indent=2)+'\n')
    header=['/* Generated Gen 2 numeric payload; no MMIO assumptions. */','#include <stdint.h>']
    source=['#include "model_data.h"']
    for name,values in arrays.items():
        typ='int8_t' if name.endswith('_weights') else 'int32_t'
        header.append(f'extern const {typ} {name}[{len(values)}];')
        source.append(f'const {typ} {name}[{len(values)}] = {{'+','.join(map(str,values))+'};')
    (out/'model_data.h').write_text('\n'.join(header)+'\n')
    (out/'model_data.c').write_text('\n'.join(source)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k in ['parameter_count','tflite_bytes','memory']},indent=2))
