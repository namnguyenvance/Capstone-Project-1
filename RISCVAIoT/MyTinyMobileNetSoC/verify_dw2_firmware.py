#!/usr/bin/env python3
"""Reproduce DW2 equivalence against verified Level 3 without editing sources.
Run: python3 verify_dw2_firmware.py --artifacts /tmp/dw2_level4_integration
Host builds intercept MMIO only in temporary copies. RV32 builds are unmodified.
"""
import argparse, os, re, subprocess, random, sys
sys.dont_write_bytecode=True
from pathlib import Path
ROOT=Path(__file__).resolve().parent
BASELINE='9bdd523e0ab142a78a211f17a500512d7e5ec8ca'
FLAGS=['-mabi=ilp32','-march=rv32im','-ffreestanding','-nostdlib','-O2','-I',str(ROOT)]
def command(args,**kw): return subprocess.run(list(map(str,args)),check=True,**kw)
def function(asm,name):
    return asm.split(name+':\n',1)[1].split('.size\t'+name,1)[0]
def canonical(body):
    labels={}
    return re.sub(r'\.L\d+',lambda m:labels.setdefault(m[0],'.L'+str(len(labels))),body)
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--artifacts',type=Path,required=True);a=parser.parse_args();t=a.artifacts.resolve();t.mkdir(parents=True,exist_ok=True)
    baseline=subprocess.check_output(['git','show',f'{BASELINE}:RISCVAIoT/MyTinyMobileNetSoC/dl_ops.c'],cwd=ROOT,text=True)
    for name,source in [('baseline',baseline),('candidate',(ROOT/'dl_ops.c').read_text())]:
        p=t/(name+'.c');p.write_text(source)
        names=[n for n in re.findall(r'^(?:void|int32_t)\s+(\w+)\(',source,re.M) if not n.startswith('pw_mmio_')]
        host=re.sub(r'((?:DW_CONV|CONV)_ACCEL_(?:KER|IMG|CTRL)\[[^\]]+\])\s*=\s*([^;]+);',r'PW_WRITE(&\1, \2);',source)
        host=re.sub(r'((?:DW_CONV|CONV)_ACCEL_OUT\[[^\]]+\])',r'PW_READ(&\1)',host)
        (t/(name+'_host.c')).write_text('#define PW_MMIO_TEST\n'+''.join(f'#define {n} {name}_{n}\n' for n in names)+host)
        command(['riscv32-unknown-elf-gcc',*FLAGS,'-S',p,'-o',t/(name+'.s')])
        command(['riscv32-unknown-elf-gcc',*FLAGS,'-T',ROOT/'sections.lds','-o',t/(name+'.elf'),ROOT/'start.s',ROOT/'main_tinymobilenet.c',p,ROOT/'quantize.c',ROOT/'tinymobilenet_model_data.c'])
        (t/(name+'.dis')).write_text(subprocess.check_output(['riscv32-unknown-elf-objdump','-d',str(t/(name+'.elf'))],text=True))
        command(['riscv32-unknown-elf-gcc',*FLAGS,'-DNATIVE_RUN','-S',p,'-o',t/(name+'_native.s')])
        command(['cc','-O2','-DNATIVE_RUN','-I',ROOT,ROOT/'verify_native.c',p,ROOT/'quantize.c',ROOT/'tinymobilenet_model_data.c','-o',t/(name+'_native')])
        (t/(name+'_native.log')).write_text(subprocess.check_output([str(t/(name+'_native'))],text=True))
    sources=[ROOT/'verify_dw2_firmware.c',t/'baseline_host.c',t/'candidate_host.c',ROOT/'quantize.c',ROOT/'tinymobilenet_model_data.c']
    command(['cc','-O2','-fwrapv','-I',ROOT,*sources,'-o',t/'verify']);command([t/'verify',t])
    command(['cc','-O1','-g','-fwrapv','-fsanitize=address,undefined','-fno-sanitize=shift','-fno-omit-frame-pointer','-I',ROOT,*sources,'-o',t/'verify_sanitized'])
    command([t/'verify_sanitized',t],env={**os.environ,'ASAN_OPTIONS':'detect_leaks=0'})
    rng=random.Random(0x4d573250)
    with (t/'dw_vectors.hex').open('a') as f:
        for n in range(256):
            patch=[rng.choice([-2147483648,2147483647,-128,-1,0,127,255]) if n<32 else rng.randrange(-2147483648,2147483648) for _ in range(25)]
            kernel=[rng.choice([-128,-1,0,127]) if n<32 else rng.randrange(-128,128) for _ in range(9)]
            results=[sum(patch[(y+ky)*5+x+kx]*kernel[ky*3+kx] for ky in range(3) for kx in range(3)) for y,x in [(0,0),(0,2),(2,0),(2,2)]]
            f.write(''.join(f'{v&0xffffffff:08x}\n' for v in kernel+patch+results))
    signed=lambda x:(x&0x7fffffff)-(x&0x80000000)
    with (t/'quant_vectors.hex').open('w') as f:
        for n in range(256):
            raw=rng.choice([-2147483648,2147483647,-1,0,1]) if n<32 else rng.randrange(-2147483648,2147483648)
            m=rng.choice([-2147483648,2147483647,-1,0,1]) if n<32 else rng.randrange(-2147483648,2147483648);shift=rng.randrange(31)
            product=raw*m;hi=signed((product+(1073741824 if product>=0 else -1073741823))>>31);mask=(1<<shift)-1
            out=(hi>>shift)+((hi&mask)>((mask>>1)+(hi<0)))
            f.write(''.join(f'{v&0xffffffff:08x}\n' for v in (raw,m,shift,out)))
    command(['iverilog','-g2012','-Wall','-s','tb_dw2_mapping','-o',t/'tb_dw2_mapping.vvp',ROOT/'tb_dw2_mapping.v',ROOT/'my_dw_conv_accel.v',ROOT/'my_quant_accel.v'])
    command(['vvp',t/'tb_dw2_mapping.vvp','+DW_VECTORS='+str(t/'dw_vectors.hex'),'+QUANT_VECTORS='+str(t/'quant_vectors.hex')])
    old=(t/'baseline.s').read_text();new=(t/'candidate.s').read_text()
    for name in re.findall(r'^([A-Za-z_]\w*):$',old,re.M):
        if name not in new or '.size\t'+name not in old:continue
        b=function(old,name);c=function(new,name);frame=lambda x:re.search(r'addi\s+sp,sp,-(\d+)',x)
        print(f'ASSEMBLY {name}: '+('identical' if canonical(b)==canonical(c) else 'changed')+f'; frame {frame(b)[1] if frame(b) else 0} -> {frame(c)[1] if frame(c) else 0}')
    normalize=lambda p:re.sub(r'\t.file[^\n]+','',p.read_text())
    assert normalize(t/'baseline_native.s')==normalize(t/'candidate_native.s')
    assert (t/'baseline_native.log').read_bytes()==(t/'candidate_native.log').read_bytes()
    print('[PASS] native fallback assembly and verifier output unchanged (95/100)')
    from verify_dw2_profile import profile, verify_rv_wrap
    profile(ROOT,t)
    verify_rv_wrap(ROOT,t)
    verify_rv_wrap(ROOT,t,"DW3")
if __name__=='__main__':main()
