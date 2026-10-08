#!/usr/bin/env python3
"""Focused production PW1 cache verification; no SoC inference.
Run: python3 verify_pw_cache.py --artifacts /tmp/pw_cache_verification
Builds identical RV32IM firmware, host traces, native verifier and instruction replay.
Cycle estimates use the established approximate CPI model; counts exclude caller/UART.
All generated artifacts remain outside the repository.
"""
import argparse,collections,hashlib,json,re,subprocess,sys,tempfile
from pathlib import Path
sys.dont_write_bytecode=True
from verify_dw2_profile import CPU,U,S,SX
R=Path(__file__).resolve().parent
BASELINE="df9af0313a868e9511985a4490ede4bea6bee171"
FLAGS=["-mabi=ilp32","-march=rv32im","-ffreestanding","-nostdlib","-O2","-I",str(R)]
T=None
class PWCPU(CPU):
 def __init__(self,name):
  self.code={}
  for line in (T/(name+'.dis')).read_text().splitlines():
   m=re.match(r'\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(.+)',line)
   if m:self.code[int(m[1],16)]=(int(m[2],16),m[3])
  self.r=[0]*32;self.r[2]=0x80000;self.r[1]=0;self.mem={};self.count=collections.Counter();self.cycle=0;self.stream=hashlib.sha256();self.pc_counts=collections.Counter()
  self.quant=[0]*3;self.qresult=0;self.img=[0]*25;self.ker=[0]*9;self.results=[0]*9
  self.pc=int(re.search(r'^([0-9a-f]+) <Conv2D_TFLM>:',(T/(name+'.dis')).read_text(),re.M)[1],16)
  model=(R/'tinymobilenet_model_data.c').read_text()
  def arr(k):return list(map(int,re.findall(r'-?\d+',re.search(r'\btmn_pw1_'+k+r'\[[^]]*\]\s*=\s*\{([^}]+)\}',model)[1])))
  def scalar(k):return int(re.search(r'\btmn_pw1_'+k+r'\s*=\s*(-?\d+)',model)[1])
  self.put(0x10000,(T/'PW1_input.bin').read_bytes(),1);self.put(0x20000,arr('kernel_data'),1);self.put(0x30000,arr('bias_data'));self.put(0x31000,arr('output_multiplier'));self.put(0x32000,arr('output_shift'),1)
  self.put(0x33000,[28,28,16]);self.put(0x33020,[1,1,16]);self.put(0x33040,[28,28,32]);self.put(0x33060,[32]);args=[0x10000,0x33000,scalar('input_offset'),0x20000,0x33020,0x30000,0x33060,1,1,0,0,0x40000,0x33040,scalar('output_offset'),0x31000,0x32000,-128,127]
  self.r[10:18]=list(map(U,args[:8]));self.put(0x80000,args[8:]);self.C=32;self.O=28
  self.inp=[0]*64;self.weights=[[0]*64 for _ in range(4)];self.cache=[0]*512;self.res=[0]*4;self.depth=0;self.ci=0;self.preload_start=None;self.first_input=None;self.last_preload=None
 def memory(self,a,v,n,write):
  if 0x02000400<=a<0x02000800:
   self.count['pw_writes' if write else 'pw_reads']+=1;i=(a-0x02000400)//4
   if write:
    if i<64:
     if self.first_input is None:self.first_input={'cycles':self.cycle,'instructions':self.count['instructions']}
     self.inp[i]=S(v);self.count['input_writes']+=1
    elif i==128:self.depth=v
    elif i==137:
     self.preload_start={'cycles':self.cycle,'instructions':self.count['instructions']-1};self.ci=v;self.count['preload_setup_writes']+=1
    elif i==138:
     for j in range(4):self.cache[self.ci*4+j]=SX((v>>(j*8))&255,8)
     self.ci+=1;self.count['preload_writes']+=1;self.last_preload={'cycles':self.cycle+7,'instructions':self.count['instructions'],'pc':self.pc}
    elif i>=192:
     bank=(i-192)//16;lane=(i-192)%16*4
     for j in range(4):self.weights[bank][lane+j]=SX((v>>(j*8))&255,8)
     self.count['weight_writes']+=1
    elif i in (131,139):
     self.count['triggers']+=1
     for b in range(4):self.res[b]=U(sum(self.inp[j]*(self.cache[(v*4+b)*16+j] if i==139 else self.weights[b][j]) for j in range(16)))
    else:raise ValueError(i)
   else:assert 132<=i<=135;v=self.res[i-132]
   return v
  return super().memory(a,v,n,write)
class ConvCPU(PWCPU):
 def __init__(self,name):
  super().__init__(name)
  self.C=16;self.O=28
  model=(R/'tinymobilenet_model_data.c').read_text()
  def arr(k):return list(map(int,re.findall(r'-?\d+',re.search(r'\btmn_conv0_'+k+r'\[[^]]*\]\s*=\s*\{([^}]+)\}',model)[1])))
  def scalar(k):return int(re.search(r'\btmn_conv0_'+k+r'\s*=\s*(-?\d+)',model)[1])
  images=(R/'mnist_test_images.h').read_text();images=re.sub(r'/\*.*?\*/','',images,flags=re.S);vals=list(map(int,re.findall(r'-?\d+',images.split('const int8_t test_images')[1].split('=')[1])))[:784]
  self.put(0x10000,vals,1);self.put(0x20000,arr('kernel_data'),1);self.put(0x30000,arr('bias_data'));self.put(0x31000,arr('output_multiplier'));self.put(0x32000,arr('output_shift'),1)
  self.put(0x33000,[28,28,1]);self.put(0x33020,[3,3,1]);self.put(0x33040,[28,28,16]);self.put(0x33060,[16]);args=[0x10000,0x33000,scalar('input_offset'),0x20000,0x33020,0x30000,0x33060,1,1,1,1,0x40000,0x33040,scalar('output_offset'),0x31000,0x32000,-128,127]
  self.r[10:18]=list(map(U,args[:8]));self.put(0x80000,args[8:]);self.patch=[0]*25;self.kernel=[0]*9;self.convresults=[0]*9
 def memory(self,a,v,n,w):
  if 0x02000100<=a<0x02000200:
   self.count['conv_writes' if w else 'conv_reads']+=1;i=(a-0x02000100)//4
   if w:
    if i<=24:self.patch[i]=S(v)
    elif 28<=i<=36:self.kernel[i-28]=S(v)
    elif i==60:
     self.count['conv_triggers']+=1
     self.convresults=[U(sum(self.patch[(y+ky)*5+x+kx]*self.kernel[ky*3+kx] for ky in range(3) for kx in range(3))) for y in range(3) for x in range(3)]
    else:raise ValueError(i)
   else:assert 40<=i<=48;v=self.convresults[i-40]
   return v
  return super().memory(a,v,n,w)

def command(args,**kw):
 return subprocess.run(list(map(str,args)),check=True,**kw)
def function(asm,name):
 m=re.search(r'^'+name+r'(?:\.(?:isra|constprop)\.\d+)?:\n(.*?)\n\s*\.size\s+'+name,asm,re.M|re.S)
 assert m,name
 return m[1]
def canonical(body):
 labels={};return re.sub(r'\.L\d+',lambda m:labels.setdefault(m[0],'.L'+str(len(labels))),body)
def frame(body):
 m=re.search(r'addi\s+sp,sp,-(\d+)',body);return int(m[1]) if m else 0
def main():
 global T
 parser=argparse.ArgumentParser();parser.add_argument('--artifacts',type=Path);parser.add_argument('--baseline',default=BASELINE);a=parser.parse_args()
 T=(a.artifacts or Path(tempfile.mkdtemp(prefix='pw_cache_verify_',dir='/tmp'))).resolve();T.mkdir(parents=True,exist_ok=True)
 assert not T.is_relative_to(R.parents[1]),'generated artifacts must stay outside repository'
 source=subprocess.check_output(['git','show',a.baseline+':RISCVAIoT/MyTinyMobileNetSoC/dl_ops.c'],cwd=R,text=True)
 for name,text in [('baseline',source),('candidate',(R/'dl_ops.c').read_text())]:
  p=T/(name+'.c');p.write_text(text)
  command(['riscv32-unknown-elf-gcc',*FLAGS,'-S',p,'-o',T/(name+'.s')])
  command(['riscv32-unknown-elf-gcc',*FLAGS,'-T',R/'sections.lds','-o',T/(name+'.elf'),R/'start.s',R/'main_tinymobilenet.c',p,R/'quantize.c',R/'tinymobilenet_model_data.c'])
  (T/(name+'.dis')).write_bytes(subprocess.check_output(['riscv32-unknown-elf-objdump','-d',str(T/(name+'.elf'))]))
  command(['riscv32-unknown-elf-gcc',*FLAGS,'-DNATIVE_RUN','-S',p,'-o',T/(name+'_native.s')])
  command(['cc','-O2','-DNATIVE_RUN','-I',R,R/'verify_native.c',p,R/'quantize.c',R/'tinymobilenet_model_data.c','-o',T/(name+'_native')])
  (T/(name+'_native.log')).write_bytes(subprocess.check_output([str(T/(name+'_native'))]))
 command(['cc','-O2','-fwrapv','-I',R,R/'verify_pw_firmware.c',R/'quantize.c',R/'tinymobilenet_model_data.c','-o',T/'host_verify'])
 command([T/'host_verify',T])
 old=(T/'baseline.s').read_text();new=(T/'candidate.s').read_text();normalize=lambda p:re.sub(r'\s*\.file.*\n','',p.read_text())
 assert normalize(T/'baseline_native.s')==normalize(T/'candidate_native.s')
 assert (T/'baseline_native.log').read_bytes()==(T/'candidate_native.log').read_bytes()
 assert canonical(function(old,'Conv2D_TFLM'))==canonical(function(new,'Conv2DLevel4'))
 for f in ('DWStride2CPU','DepthwiseConv2D_TFLM','MultiplyByQuantizedMultiplier','MultiplyByQuantizedMultiplierSmallerThanOne','GlobalAveragePool_TFLM','FullyConnected2D_TFLM'):
  assert canonical(function(old,f))==canonical(function(new,f)),f
 native_result=re.search(r'FINAL RESULT: (\d+/\d+)',(T/'candidate_native.log').read_text())[1]
 print('[PASS] Level 4 Conv/PW2/PW3 core, DW, quantizer, GAP/FC and native assembly unchanged; native verifier unchanged ('+native_result+')',flush=True)
 result={}
 for name in ('baseline','candidate'):
  result[name]={}
  for layer,cls,expected in [('PW1',PWCPU,T/'PW1_output.bin'),('Conv0',ConvCPU,T/'Conv0_output.bin')]:
   cpu=cls(name);assert cpu.run()==expected.read_bytes(),(name,layer)
   result[name][layer]={'counts':dict(cpu.count),'model_cycles':cpu.cycle,'preload_start':cpu.preload_start,'last_preload':cpu.last_preload,'first_input':cpu.first_input}
   (T/(name+'_'+layer+'_executed.txt')).write_text('\n'.join(f'{pc:08x} {n:9d} {cpu.code[pc][1]}' for pc,n in sorted(cpu.pc_counts.items())))
   if cpu.last_preload is not None:
    start=cpu.preload_start;end=cpu.last_preload
    assert (cpu.code[end['pc']+4][0]&127)==0x63,'preload loop exit must follow final data store'
    result[name][layer]['preload']={'instructions':end['instructions']-start['instructions']+1,'model_cycles':end['cycles']-start['cycles']+6,'ram_word_loads':128,'data_writes':128,'index_writes':1}
   print(name,layer,json.dumps(result[name][layer]),flush=True)
 row_block=next(b for b in re.split(r'\.L\d+:\n',function(new,'Conv2DLevel4')) if '\tnot\t' in b)
 row_setup=len([line for line in row_block.splitlines() if line.startswith('\t') and not line.strip().startswith('.')])
 result['assembly']={'dispatcher_frame':frame(function(new,'Conv2D_TFLM')),'core_frame':frame(function(new,'Conv2DLevel4')),'cached_helper_frame':frame(function(new,'CachedPW1Hardware')),'row_setup':row_setup,'text_bytes':int(re.search(r'^\.text\s+(\d+)',subprocess.check_output(['riscv32-unknown-elf-size','-A',str(T/'candidate.elf')],text=True),re.M)[1])}
 pw=round(result['candidate']['PW1']['model_cycles']*8393456/result['baseline']['PW1']['model_cycles'])
 dispatch=result['candidate']['Conv0']['model_cycles']-result['baseline']['Conv0']['model_cycles'];assert dispatch==264
 overheads={'Conv0':round(dispatch*7775776/result['baseline']['Conv0']['model_cycles']),'PW2':round(dispatch*4286581/4678937),'PW3':round(dispatch*1810193/1977218)}
 result['forecast']={'PW1':pw,'PW1_savings':8393456-pw,'dispatch_overheads':overheads,'total':36208913-8393456+pw+sum(overheads.values())}
 (T/'results.json').write_text(json.dumps(result,indent=2));print('ASSEMBLY',json.dumps(result['assembly']),flush=True);print('FORECAST',json.dumps(result['forecast']),flush=True)
 verify_wrap()
 print('[PASS] production PW1 cache focused firmware verification; artifacts',T)
def verify_wrap():
 for case in range(2):
  inp=[[-128,-1,0,127][(i+case)%4] for i in range(16*784)]
  weights=[[-128,-1,0,127][(i+case//2)%4] for i in range(512)]
  bias=[S(U(0x7fffffff+c*1234567)) for c in range(32)]
  mul=[-2147483648 if c%3==0 else 2147483647 for c in range(32)]
  shifts=[-3 if c%2 else 4 for c in range(32)]
  offset=2147483647 if case else -2147483648
  expected=bytearray(32*784)
  for c in range(32):
   for p in range(784):
    acc=S(U(bias[c]+sum(S(U(inp[j*784+p]+offset))*weights[c*16+j] for j in range(16))))
    raw=S(U(acc<<3)) if shifts[c]<0 else acc;sh=max(0,shifts[c]);product=raw*mul[c];hi=S(U((product+(1073741824 if product>=0 else -1073741823))>>31));mask=(1<<sh)-1
    q=S(U((hi>>sh)+((hi&mask)>((mask>>1)+(hi<0)))));expected[c*784+p]=U(max(-128,min(127,S(U(q-128)))))&255
  for name in ('baseline','candidate'):
   cpu=PWCPU(name);cpu.put(0x10000,inp,1);cpu.put(0x20000,weights,1);cpu.put(0x30000,bias);cpu.put(0x31000,mul);cpu.put(0x32000,shifts,1);cpu.r[12]=U(offset);cpu.put(0x80014,[-128]);assert cpu.run()==expected,(case,name)
   print('[PASS] compiled RV32IM signed/wraparound full PW1',case,name,flush=True)

if __name__=='__main__':main()
