/* Hardware-mode DW2 equivalence. Run through verify_dw2_firmware.py, which
 * intercepts MMIO in temporary source copies; production stays volatile MMIO.
 * Host -fwrapv and the independent unsigned reference model RV32 wraparound.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "dl_ops.h"
#include "tinymobilenet_model_data.h"
#include "mnist_test_images.h"
extern __typeof__(DepthwiseConv2D_TFLM) baseline_DepthwiseConv2D_TFLM, candidate_DepthwiseConv2D_TFLM;
extern __typeof__(Conv2D_TFLM) baseline_Conv2D_TFLM;
static const char *artifact_dir;
static int32_t img[2][25],ker[2][9],res[2][9],pi[64],pw[4][64],pr[4],depth;
static int32_t raw,mul,shift,quant;
static unsigned kw,iw,tr,rr,qw,qr,cases,wraps,clamps[2],edges[2];
static uint32_t seed=0x4d573250;
static const int8_t *in,*weight,*shifts;
static int offset,px,py,checking,expect_cpu_only;
static int32_t qraw[6272],qvalue[6272];
static FILE *vectors;
static int64_t ar(int64_t v,unsigned s){int64_t d=INT64_C(1)<<s;return v/d-(v<0&&v%d!=0);}
static int32_t bits(uint32_t x){int32_t v;memcpy(&v,&x,4);return v;}
static uint32_t random_word(void){seed^=seed<<13;seed^=seed>>17;seed^=seed<<5;return seed;}
static void fail(const char *s){fprintf(stderr,"FAIL: %s case %u\n",s,cases);exit(1);}
static int32_t requant(int32_t x,int32_t m,unsigned s){
 int64_t p=(int64_t)x*m;int32_t hi=bits((uint32_t)ar(p+(p>=0?INT64_C(1073741824):-INT64_C(1073741823)),31));
 uint32_t mask=(UINT32_C(1)<<s)-1;return bits((uint32_t)(ar(hi,s)+(((uint32_t)hi&mask)>((mask>>1)+(hi<0)))));
}
static int32_t dot(int c,int y,int x){
 uint32_t sum=0;int64_t wide=0;
 for(int ky=0;ky<3;ky++)for(int kx=0;kx<3;kx++){
  int iy=y*2-py+ky,ix=x*2-px+kx;
  if(iy>=0&&iy<28&&ix>=0&&ix<28){int32_t v=bits((uint32_t)(int32_t)in[c*784+iy*28+ix]+(uint32_t)offset);int64_t p=(int64_t)v*weight[c*9+ky*3+kx];sum+=(uint32_t)p;wide+=p;}
 }
 wraps+=wide>INT32_MAX||wide<INT32_MIN;return bits(sum);
}
void pw_mmio_write(volatile int32_t *reg,int32_t v){
 uintptr_t a=(uintptr_t)reg;
 if((a>=0x02000100&&a<0x02000200)||(a>=0x02000300&&a<0x02000400)){
  int d=a>=0x02000300;if(d&&expect_cpu_only)fail("CPU fallback issued DW write");unsigned off=(unsigned)(a-(d?0x02000300:0x02000100));
  if(off<=96){img[d][off/4]=v;if(d&&checking){iw++;unsigned c=tr/49,ty=(tr%49)/7,tx=tr%7,n=off/4;int sy=ty*4+(int)n/5-py,sx=tx*4+(int)n%5-px;int32_t expected=0;if(sy>=0&&sy<28&&sx>=0&&sx<28)expected=bits((uint32_t)(int32_t)in[c*784+sy*28+sx]+(uint32_t)offset);if(v!=expected)fail("patch bounds/padding/value");}}
  else if(off>=112&&off<=144){ker[d][(off-112)/4]=v;if(d&&checking){kw++;if(v!=weight[(tr/49)*9+(off-112)/4])fail("kernel channel/sign");}}
  else if(off==240){
   for(int y=0;y<3;y++)for(int x=0;x<3;x++){uint32_t s=0;for(int ky=0;ky<3;ky++)for(int kx=0;kx<3;kx++)s+=(uint32_t)((int64_t)img[d][(y+ky)*5+x+kx]*ker[d][ky*3+kx]);res[d][y*3+x]=bits(s);}
   if(d&&checking){tr++;if(vectors){for(int j=0;j<9;j++)fprintf(vectors,"%08x\n",(uint32_t)ker[d][j]);for(int j=0;j<25;j++)fprintf(vectors,"%08x\n",(uint32_t)img[d][j]);for(int j=0;j<4;j++)fprintf(vectors,"%08x\n",(uint32_t)res[d][(j/2)*6+(j%2)*2]);}}
  }else fail("conv write");return;
 }
 if(a>=0x02000700&&a<=0x020007fc){unsigned b=(a-0x02000700)/64,l=(a-0x02000700)%64;for(int j=0;j<4;j++)pw[b][l+j]=(int8_t)((uint32_t)v>>(j*8));return;}
 if(a>=0x02000400&&a<0x02000500){pi[(a-0x02000400)/4]=v;return;}
 if(a>=0x02000500&&a<0x02000600){pw[0][(a-0x02000500)/4]=v;return;}
 if(a==0x02000600){depth=v;return;}
 if(a==0x02000604||a==0x0200060c){for(int b=0;b<(a==0x02000604?1:4);b++){uint32_t s=0;for(int j=0;j<depth;j++)s+=(uint32_t)((int64_t)pi[j]*pw[b][j]);pr[b]=bits(s);}return;}
 if(a>=0x02000200&&a<=0x02000210){if(checking)qw++;if(a==0x02000200)raw=v;else if(a==0x02000204)mul=v;else if(a==0x02000208)shift=v;else if(a==0x02000210){if(shift<0||shift>30)fail("quant shift");quant=requant(raw,mul,shift);if(checking){if(qr>=6272)fail("quant count");qraw[qr]=raw;qvalue[qr]=quant;}}else fail("quant write");return;}
 fail("MMIO write");
}
int32_t pw_mmio_read(volatile int32_t *reg){
 uintptr_t a=(uintptr_t)reg;
 if((a>=0x020001a0&&a<=0x020001c0)||(a>=0x020003a0&&a<=0x020003c0)){
  int d=a>=0x02000300;if(d&&expect_cpu_only)fail("CPU fallback issued DW read");unsigned n=(unsigned)(a-(d?0x020003a0:0x020001a0))/4;
  if(d&&checking){if(n!=0&&n!=2&&n!=6&&n!=8)fail("corner index");unsigned t=tr-1,c=t/49;int y=((t%49)/7)*2+(n/3)/2,x=(t%7)*2+(n%3)/2;if(res[d][n]!=dot(c,y,x))fail("raw result");edges[0]+=y==13;edges[1]+=x==13;rr++;}return res[d][n];
 }
 if(a==0x0200020c){if(checking)qr++;return quant;}
 if(a==0x02000608)return pr[0];
 if(a>=0x02000610&&a<=0x0200061c)return pr[(a-0x02000610)/4];
 fail("MMIO read");return 0;
}
static FILE *open_artifact(const char *name){char path[1024];snprintf(path,sizeof(path),"%s/%s",artifact_dir,name);FILE *f=fopen(path,"wb");if(!f)fail("artifact open");return f;}
static void save(const char *name,const int8_t *p,size_t n){FILE *f=open_artifact(name);if(fwrite(p,1,n,f)!=n)fail("artifact write");fclose(f);}
static void run_case(const int8_t *a,const int8_t *w,const int32_t *b,const int32_t *m,const int8_t *sh,int io,int oo,int padx,int pady,int lo,int hi,int actual){
 int id[]={28,28,32},fd[]={3,3,32},od[]={14,14,32},bd[]={32};int8_t *old=malloc(6272),*now=malloc(6272);if(!old||!now)abort();
 cases++;in=a;weight=w;shifts=sh;offset=io;px=padx;py=pady;checking=1;kw=iw=tr=rr=qw=qr=0;
 baseline_DepthwiseConv2D_TFLM(a,id,io,w,fd,b,bd,2,2,px,py,1,old,od,oo,m,sh,lo,hi);
 if(kw||iw||tr||rr||qw!=25088||qr!=6272)fail("baseline counts");kw=iw=tr=rr=qw=qr=0;
 if(actual)vectors=open_artifact("dw_vectors.hex");
 candidate_DepthwiseConv2D_TFLM(a,id,io,w,fd,b,bd,2,2,px,py,1,now,od,oo,m,sh,lo,hi);
 if(vectors){fclose(vectors);vectors=NULL;}
 if(kw!=288||iw!=39200||tr!=1568||rr!=6272||qw!=25088||qr!=6272)fail("candidate counts");
 if(memcmp(old,now,6272))fail("output bytes");
 for(int c=0;c<32;c++)for(int y=0;y<14;y++)for(int x=0;x<14;x++){
  int i=c*196+y*14+x;int32_t acc=bits((uint32_t)dot(c,y,x)+(b?(uint32_t)b[c]:0));int32_t r=sh[c]<0?bits((uint32_t)acc<<-sh[c]):acc,q=requant(r,m[c],sh[c]<0?0:sh[c]),v=bits((uint32_t)q+(uint32_t)oo);
  if(v<lo){v=lo;clamps[0]++;}if(v>hi){v=hi;clamps[1]++;}if(now[i]!=(int8_t)v)fail("reference bytes");int qi=c*196+(y/2)*28+(x/2)*4+(y%2)*2+x%2;if(qraw[qi]!=r||qvalue[qi]!=q)fail("quantization values/order");
 }
 checking=0;if(actual){save("DW2_input.bin",a,25088);save("DW2_output.bin",now,6272);}free(old);free(now);
}
/* The extracted fallback must retain CPU-only behavior for DW3 and other
 * unsupported shapes. This reference defines accumulation modulo 2^32. */
static void verify_cpu_fallback(void){
 for(int t=0;t<24;t++){
  int W=t<12?14:t<18?13:28,H=t<12?14:t<18?11:28,C=t<12?48:t<18?7:31;
  int O=(W+1)/2,P=(H+1)/2,id[]={W,H,C},fd[]={3,3,C},od[]={O,P,C},bd[]={C};
  size_t ni=(size_t)W*H*C,no=(size_t)O*P*C;
  int8_t *a=malloc(ni),*w=malloc(C*9),*old=malloc(no),*now=malloc(no),*sh=malloc(C);
  int32_t *bias=malloc(C*4),*m=malloc(C*4);
  if(!a||!w||!old||!now||!sh||!bias||!m)abort();
  for(size_t i=0;i<ni;i++)a[i]=(int8_t)random_word();
  for(int i=0;i<C*9;i++)w[i]=(int8_t)random_word();
  for(int c=0;c<C;c++){bias[c]=bits(random_word());m[c]=bits(random_word());sh[c]=(c+t)%12-3;}
  int io=t>=20?(t%2?INT32_MAX:INT32_MIN):(int[]){128,-128,0,17}[t%4];
  int padx=t%3,pady=(t/3)%3,oo=-128;const int32_t *bp=t%2?bias:NULL;
  expect_cpu_only=1;
  baseline_DepthwiseConv2D_TFLM(a,id,io,w,fd,bp,bd,2,2,padx,pady,1,old,od,oo,m,sh,-128,127);
  candidate_DepthwiseConv2D_TFLM(a,id,io,w,fd,bp,bd,2,2,padx,pady,1,now,od,oo,m,sh,-128,127);
  expect_cpu_only=0;
  if(memcmp(old,now,no))fail("CPU fallback byte equivalence");
  for(int c=0;c<C;c++)for(int y=0;y<P;y++)for(int x=0;x<O;x++){
   uint32_t sum=bp?(uint32_t)bp[c]:0;
   for(int ky=0;ky<3;ky++)for(int kx=0;kx<3;kx++){
    int iy=y*2-pady+ky,ix=x*2-padx+kx;
    if(iy>=0&&iy<H&&ix>=0&&ix<W){int32_t v=bits((uint32_t)(int32_t)a[c*H*W+iy*W+ix]+(uint32_t)io);sum+=(uint32_t)((int64_t)v*w[c*9+ky*3+kx]);}
   }
   int32_t r=sh[c]<0?bits(sum<<-sh[c]):bits(sum),q=requant(r,m[c],sh[c]<0?0:sh[c]),v=bits((uint32_t)q+(uint32_t)oo);
   v=v<-128?-128:v>127?127:v;
   if(now[c*O*P+y*O+x]!=(int8_t)v)fail("CPU fallback unsigned reference");
  }
  free(a);free(w);free(old);free(now);free(sh);free(bias);free(m);
 }
 puts("[PASS] 24 CPU fallback cases: DW3/unsupported shapes, padding, signed/random/wrap, no DW MMIO");
}
int main(int argc,char **argv){
 if(argc!=2)return 2;artifact_dir=argv[1];int8_t *a=malloc(25088),*b=malloc(25088);if(!a||!b)abort();int id[]={28,28,1},d16[]={28,28,16},d32[]={28,28,32},d48[]={14,14,48},d2[]={14,14,32},d3[]={7,7,48};
 baseline_Conv2D_TFLM(test_images[0],id,tmn_conv0_input_offset,tmn_conv0_kernel_data,tmn_conv0_kernel_dims,tmn_conv0_bias_data,tmn_conv0_bias_dims,1,1,1,1,a,d16,tmn_conv0_output_offset,tmn_conv0_output_multiplier,tmn_conv0_output_shift,-128,127);
 save("DW1_input.bin",a,12544);
 baseline_DepthwiseConv2D_TFLM(a,d16,tmn_dw1_input_offset,tmn_dw1_kernel_data,tmn_dw1_kernel_dims,tmn_dw1_bias_data,tmn_dw1_bias_dims,1,1,1,1,1,b,d16,tmn_dw1_output_offset,tmn_dw1_output_multiplier,tmn_dw1_output_shift,-128,127);save("DW1_output.bin",b,12544);
 baseline_Conv2D_TFLM(b,d16,tmn_pw1_input_offset,tmn_pw1_kernel_data,tmn_pw1_kernel_dims,tmn_pw1_bias_data,tmn_pw1_bias_dims,1,1,0,0,a,d32,tmn_pw1_output_offset,tmn_pw1_output_multiplier,tmn_pw1_output_shift,-128,127);
 run_case(a,tmn_dw2_kernel_data,tmn_dw2_bias_data,tmn_dw2_output_multiplier,tmn_dw2_output_shift,tmn_dw2_input_offset,tmn_dw2_output_offset,0,0,-128,127,1);
 baseline_DepthwiseConv2D_TFLM(a,d32,tmn_dw2_input_offset,tmn_dw2_kernel_data,tmn_dw2_kernel_dims,tmn_dw2_bias_data,tmn_dw2_bias_dims,2,2,0,0,1,b,d2,tmn_dw2_output_offset,tmn_dw2_output_multiplier,tmn_dw2_output_shift,-128,127);
 baseline_Conv2D_TFLM(b,d2,tmn_pw2_input_offset,tmn_pw2_kernel_data,tmn_pw2_kernel_dims,tmn_pw2_bias_data,tmn_pw2_bias_dims,1,1,0,0,a,d48,tmn_pw2_output_offset,tmn_pw2_output_multiplier,tmn_pw2_output_shift,-128,127);save("DW3_input.bin",a,9408);
 baseline_DepthwiseConv2D_TFLM(a,d48,tmn_dw3_input_offset,tmn_dw3_kernel_data,tmn_dw3_kernel_dims,tmn_dw3_bias_data,tmn_dw3_bias_dims,2,2,0,0,1,b,d3,tmn_dw3_output_offset,tmn_dw3_output_multiplier,tmn_dw3_output_shift,-128,127);save("DW3_output.bin",b,2352);
 int8_t *w=malloc(288),sh[32];int32_t bias[32],m[32];if(!w)abort();
 for(int t=0;t<120;t++){
  for(int i=0;i<25088;i++)a[i]=t<8?(int8_t[]){-128,-1,0,127}[(i+t)%4]:(int8_t)random_word();
  for(int i=0;i<288;i++)w[i]=t<8?(int8_t[]){-128,-1,0,127}[(i+t/2)%4]:(int8_t)random_word();
  for(int c=0;c<32;c++){bias[c]=t>=112?bits(random_word()):(int32_t)(random_word()%200001)-100000;m[c]=t>=112?bits(random_word()):(int32_t)(random_word()%INT32_MAX);sh[c]=(c+t)%12-3;}
  int io=t>=112?(t%2?INT32_MAX:INT32_MIN):(int[]){0,128,-128,17,-17}[t%5],oo=t>=112?bits(random_word()):(int)(random_word()%257)-128;
  run_case(a,w,t%2?bias:NULL,m,sh,io,oo,t%3,(t/3)%3,t%4?-128:-17,t%4?127:23,0);
 }
 printf("[PASS] %u full DW2 cases / %u bytes; actual tensor bit-exact\n",cases,cases*6272);
 printf("[PASS] boundary checks %u/%u; wrap checks %u; clamps %u/%u\n",edges[0],edges[1],wraps,clamps[0],clamps[1]);
 puts("[PASS] kernel=288 INPUT=39200 trigger=1568 RESULT=6272 quantizer=31360");verify_cpu_fallback();free(a);free(b);free(w);return 0;
}
