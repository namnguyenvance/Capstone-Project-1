"""Focused RV32IM instruction replay; no SoC simulation.
CPI model is approximate: ALU 5, memory 7, branch 5/6, jump 6, MUL 40.
Counts exclude caller, UART and instruction-fetch transactions. Stack counts
include locals/arguments/saved registers, not only register-allocation spills.
"""
import collections,hashlib,json,re
U=lambda x:x&0xffffffff
S=lambda x:(x&0x7fffffff)-(x&0x80000000)
SX=lambda x,n:(x&((1<<(n-1))-1))-(x&(1<<(n-1)))
class CPU:
 def __init__(self,root,t,name,layer):
  self.code={};self.layer=layer;self.t=t
  for line in (t/(name+'.dis')).read_text().splitlines():
   if '<DepthwiseConv2D_TFLM>:' in line:self.entry=int(line.split()[0],16)
   m=re.match(r'\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(.+)',line)
   if m:self.code[int(m[1],16)]=(int(m[2],16),m[3])
  self.r=[0]*32;self.r[2]=0x80000;self.r[1]=0;self.pc=self.entry;self.mem={};self.count=collections.Counter();self.cycle=0;self.stream=hashlib.sha256();self.pc_counts=collections.Counter()
  self.img=[0]*25;self.ker=[0]*9;self.results=[0]*9;self.quant=[0]*3;self.qresult=0
  self.W,self.O,self.C,self.stride,self.pad={'DW1':(28,28,16,1,1),'DW2':(28,14,32,2,0),'DW3':(14,7,48,2,0)}[layer]
  model=(root/'tinymobilenet_model_data.c').read_text();prefix='tmn_'+layer.lower()
  def arr(suffix):return list(map(int,re.findall(r'-?\d+',re.search(r'\b'+prefix+'_'+suffix+r'\[[^]]*\]\s*=\s*\{([^}]+)\}',model).group(1))))
  def scalar(suffix):return int(re.search(r'\b'+prefix+'_'+suffix+r'\s*=\s*(-?\d+)',model).group(1))
  self.put(0x10000,(t/(layer+'_input.bin')).read_bytes(),1);self.put(0x20000,arr('kernel_data'),1);self.put(0x30000,arr('bias_data'));self.put(0x31000,arr('output_multiplier'));self.put(0x32000,arr('output_shift'),1)
  self.put(0x33000,[self.W,self.W,self.C]);self.put(0x33020,[3,3,self.C]);self.put(0x33040,[self.O,self.O,self.C]);self.put(0x33060,[self.C])
  args=[0x10000,0x33000,scalar('input_offset'),0x20000,0x33020,0x30000,0x33060,self.stride,self.stride,self.pad,self.pad,1,0x40000,0x33040,scalar('output_offset'),0x31000,0x32000,-128,127]
  self.r[10:18]=list(map(U,args[:8]));self.put(self.r[2],args[8:])
 def put(self,a,vals,n=4):
  for j,v in enumerate(vals):
   for b in range(n):self.mem[a+j*n+b]=(v>>(8*b))&255
 def memory(self,a,v,n,write):
  if 0x02000200<=a<0x02000300:
   self.count['quant_writes' if write else 'quant_reads']+=1
   if write:
    if a in (0x02000200,0x02000204,0x02000208):self.quant[(a-0x02000200)//4]=S(v)
    elif a==0x02000210:
     raw,m,sh=self.quant;p=raw*m;hi=S(U((p+(1073741824 if p>=0 else -1073741823))>>31));mask=(1<<sh)-1;self.qresult=U((hi>>sh)+((hi&mask)>((mask>>1)+(hi<0))))
    else:raise RuntimeError(hex(a))
   else:assert a==0x0200020c;v=self.qresult
   return v
  if 0x02000300<=a<0x02000400:
   off=a-0x02000300;self.count['dw_writes' if write else 'dw_reads']+=1
   if write:
    if off<=96:self.img[off//4]=S(v);self.count['input_writes']+=1
    elif 112<=off<=144:self.ker[(off-112)//4]=S(v);self.count['kernel_writes']+=1
    elif off==240:
     self.count['triggers']+=1
     for y in range(3):
      for x in range(3):self.results[y*3+x]=U(sum(self.img[(y+ky)*5+x+kx]*self.ker[ky*3+kx] for ky in range(3) for kx in range(3)))
    else:raise RuntimeError(hex(a))
   else:assert 160<=off<=192;v=self.results[(off-160)//4]
   return v
  stack=0x7f000<=a<0x80100
  key='stack_stores' if write and stack else 'stack_loads' if stack else 'output_stores' if write and 0x40000<=a<0x50000 else 'other_stores' if write else 'data_loads';self.count[key]+=1
  if not write and not stack:
   group='input_loads' if 0x10000<=a<0x20000 else 'weight_loads' if 0x20000<=a<0x30000 else 'bias_loads' if 0x30000<=a<0x31000 else 'scale_loads' if 0x31000<=a<0x33000 else 'dimension_loads';self.count[group]+=1
  if write:self.put(a,[v],n)
  else:v=sum(self.mem.get(a+b,0)<<(8*b) for b in range(n))
  return v
 def run(self):
  while self.pc:
   inst,txt=self.code[self.pc];op=inst&127;rd=(inst>>7)&31;f=(inst>>12)&7;rs=(inst>>15)&31;rt=(inst>>20)&31;a=self.r[rs];b=self.r[rt];nextpc=self.pc+4;val=None;cost=5
   self.count['instructions']+=1;self.pc_counts[self.pc]+=1
   # Compare executed opcode/register/immediate sequences, ignoring relocated
   # branch/jump targets. Counts separately expose control-flow differences.
   signature=inst&0x01fff07f if op==0x63 else inst&0xfff if op==0x6f else inst
   self.stream.update(signature.to_bytes(4,'little'))
   if op==0x37:val=inst&0xfffff000
   elif op==0x17:val=self.pc+(inst&0xfffff000)
   elif op==0x13:
    imm=SX(inst>>20,12)
    if f==0:val=a+imm
    elif f==1:val=a<<(imm&31)
    elif f==2:val=int(S(a)<imm)
    elif f==3:val=int(a<U(imm))
    elif f==4:val=a^U(imm)
    elif f==5:val=(S(a) if inst>>30&1 else a)>>(imm&31)
    elif f==6:val=a|U(imm)
    elif f==7:val=a&U(imm)
   elif op==0x33:
    fn=inst>>25
    if fn==1:
     assert f<4,'unsupported DIV/REM';cost=40;val=[a*b,(S(a)*S(b))>>32,(S(a)*b)>>32,(a*b)>>32][f];self.count['multiply']+=1
    elif f==0:val=a-b if fn else a+b
    elif f==1:val=a<<(b&31)
    elif f==2:val=int(S(a)<S(b))
    elif f==3:val=int(a<b)
    elif f==4:val=a^b
    elif f==5:val=(S(a) if fn else a)>>(b&31)
    elif f==6:val=a|b
    elif f==7:val=a&b
   elif op in (3,0x23):
    write=op==0x23;imm=SX(((inst>>25)<<5)|((inst>>7)&31),12) if write else SX(inst>>20,12);addr=U(a+imm);n=1<<(f&3);cost=7;val=self.memory(addr,b,n,write)
    if not write and f<4:val=SX(val,n*8)
    if write:val=None
   elif op==0x63:
    imm=SX(((inst>>31)<<12)|(((inst>>7)&1)<<11)|(((inst>>25)&63)<<5)|(((inst>>8)&15)<<1),13)
    take={0:a==b,1:a!=b,4:S(a)<S(b),5:S(a)>=S(b),6:a<b,7:a>=b}[f];nextpc=self.pc+imm if take else nextpc;cost=6 if take else 5;self.count['branches']+=1;self.count['taken_branches']+=take
   elif op==0x6f:
    imm=SX(((inst>>31)<<20)|(((inst>>12)&255)<<12)|(((inst>>20)&1)<<11)|(((inst>>21)&1023)<<1),21);val=nextpc;nextpc=self.pc+imm;cost=6;self.count['jumps']+=1
   elif op==0x67:val=nextpc;nextpc=(a+SX(inst>>20,12))&~1;cost=6;self.count['jumps']+=1
   else:raise RuntimeError((hex(self.pc),txt))
   self.count['alu']+=op in (0x13,0x33,0x37,0x17)
   if val is not None and rd:self.r[rd]=U(val)
   self.r[0]=0;self.pc=U(nextpc);self.cycle+=cost
   assert self.count['instructions']<5000000,'nonterminating replay'
  return bytes(self.mem.get(0x40000+i,0) for i in range(self.C*self.O*self.O))
def profile(root,t):
 results={}
 for layer in ('DW1','DW2','DW3'):
  results[layer]={}
  for name in ('baseline','candidate'):
   cpu=CPU(root,t,name,layer);out=cpu.run();assert out==(t/(layer+'_output.bin')).read_bytes(),(layer,name)
   results[layer][name]={'counts':dict(cpu.count),'model_cycles':cpu.cycle,'opcode_stream':cpu.stream.hexdigest()}
   (t/(layer+'_'+name+'_executed.txt')).write_text('\n'.join(f'{pc:08x} {n:9d} {cpu.code[pc][1]}' for pc,n in sorted(cpu.pc_counts.items())))
   print(layer,name,json.dumps(results[layer][name]))
 measured={'DW1':6658976,'DW2':10869269,'DW3':3990023}
 projected={layer:round(results[layer]['candidate']['model_cycles']*cycles/results[layer]['baseline']['model_cycles']) for layer,cycles in measured.items()}
 savings={layer:measured[layer]-cycles for layer,cycles in projected.items()}
 results['forecast']={'projected_layer_cycles':projected,'layer_savings':savings,'total_saved_cycles':sum(savings.values()),'inference_reduction_percent':sum(savings.values())/44156359*100,'new_total_cycles':44156359-sum(savings.values())}
 print('FORECAST',json.dumps(results['forecast']));(t/'profile_results.json').write_text(json.dumps(results,indent=2))

def verify_rv_wrap(root,t,layer="DW2"):
 """Check compiled machine arithmetic, including signed-left-shift bit patterns."""
 W,O,C=(28,14,32) if layer=="DW2" else (14,7,48)
 for case in range(4):
  inputs=[[-128,-1,0,127][(i+case)%4] for i in range(W*W*C)]
  weights=[[-128,-1,0,127][(i+case//2)%4] for i in range(C*9)]
  biases=[S(U(0x7fffffff+c*1234567)) for c in range(C)]
  multipliers=[0x7fffffff if c%2 else -2147483648 for c in range(C)]
  shifts=[-3 if c%2 else 4 for c in range(C)];offset=2147483647 if case%2 else -2147483648
  expected=[]
  for c in range(C):
   for y in range(O):
    for x in range(O):
     acc=S(U(biases[c]+sum(S(U(inputs[c*W*W+(2*y+ky)*W+2*x+kx]+offset))*weights[c*9+ky*3+kx] for ky in range(3) for kx in range(3) if 2*y+ky<W and 2*x+kx<W)))
     raw=S(U(acc<<3)) if shifts[c]<0 else acc;sh=max(0,shifts[c]);p=raw*multipliers[c];hi=S(U((p+(1073741824 if p>=0 else -1073741823))>>31));mask=(1<<sh)-1
     q=S(U((hi>>sh)+((hi&mask)>((mask>>1)+(hi<0)))));expected.append(U(max(-128,min(127,S(U(q-128)))))&255)
  for name in ('baseline','candidate'):
   cpu=CPU(root,t,name,layer);cpu.put(0x10000,inputs,1);cpu.put(0x20000,weights,1);cpu.put(0x30000,biases);cpu.put(0x31000,multipliers);cpu.put(0x32000,shifts,1);cpu.r[12]=U(offset);cpu.put(0x80018,[-128]);assert cpu.run()==bytes(expected),(case,name)
  print('[PASS] compiled RV32IM',layer,'wraparound case',case,flush=True)
