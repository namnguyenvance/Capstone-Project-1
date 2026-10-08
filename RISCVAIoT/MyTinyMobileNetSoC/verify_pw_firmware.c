/* Host verification of the actual hardware PW path and its dispatch.
 * No NATIVE_RUN: MMIO is intercepted, while production arithmetic is retained.
 * Build: make verify_pw_firmware (artifacts remain in /tmp)
 */
#define PW_MMIO_TEST
#include "dl_ops.c"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tinymobilenet_model_data.h"
#include "mnist_test_images.h"

struct transaction { uintptr_t address; int32_t value; int write; };
static struct transaction trace[600000], baseline[600000];
static size_t trace_count, physical_count, packed_count, scalar_weight_count;
static size_t total_physical, total_packed, batch_count, single_count;
static size_t total_batches, total_singles, total_level2_physical;
static int32_t extra_weights[3][64], captured[4][64], batch_results[4];
static int batch_busy, batch_valid;
static int8_t resident[512];
static unsigned preload_index, preload_writes, cached_triggers;
static int32_t in[64], weight[64], depth, result, raw, multiplier, shift, quant;
static uint32_t random_state = 0x51a7c0de;
static unsigned cases, comparisons, clamp_hits[2], shift_hits[2], boundary_hits[2];

static void record(uintptr_t address, int32_t value, int write) {
    if (trace_count == sizeof(trace)/sizeof(trace[0])) abort();
    trace[trace_count++] = (struct transaction){address, value, write};
}
static int64_t arithmetic_right(int64_t value, unsigned amount) {
    int64_t divisor = INT64_C(1) << amount;
    return value / divisor - (value < 0 && value % divisor != 0);
}
void pw_mmio_write(volatile int32_t *reg, int32_t value) {
    uintptr_t address = (uintptr_t)reg;
    ++physical_count;
    if (address >= 0x02000400 && address < 0x02000800 && batch_busy) abort();
    if (address == 0x02000624) {
        preload_index=(unsigned)value; preload_writes=0; batch_valid=0; return;
    }
    if (address == 0x02000628) {
        if (preload_index>=128) abort();
        for (unsigned byte=0;byte<4;++byte)
            resident[4*preload_index+byte]=(int8_t)((uint32_t)value>>(8*byte));
        ++preload_index; ++preload_writes; batch_valid=0; return;
    }
    if (address == 0x0200062c) {
        if ((unsigned)value>=8 || preload_writes!=128 || depth!=16) abort();
        ++cached_triggers; ++batch_count; batch_busy=1; batch_valid=0;
        for (unsigned bank=0;bank<4;++bank) {
            int64_t sum=0;
            for (unsigned i=0;i<16;++i) {
                int32_t w=resident[((unsigned)value*4+bank)*16+i];
                captured[bank][i]=w; sum+=(int64_t)in[i]*w;
            }
            batch_results[bank]=(int32_t)(uint32_t)sum;
        }
        return;
    }
    if (address >= 0x02000700 && address <= 0x020007fc) {
        unsigned bank = (unsigned)((address - 0x02000700) / 64);
        unsigned lane = (unsigned)((address - 0x02000700) % 64) / 4 * 4;
        ++packed_count;
        for (unsigned byte = 0; byte < 4; ++byte) {
            unsigned bits = ((uint32_t)value >> (8 * byte)) & 255;
            int32_t signed_byte = bits < 128 ? (int32_t)bits : (int32_t)bits - 256;
            if (bank == 0) weight[lane + byte] = signed_byte;
            else extra_weights[bank-1][lane + byte] = signed_byte;
        }
        return;
    }
    if (address >= 0x02000500 && address < 0x02000600) {
        ++scalar_weight_count;
        weight[(address-0x02000500)/4] = value;
        return;
    }
    if (address >= 0x02000400 && address < 0x02000500) {
        record(address, value, 1);
        in[(address-0x02000400)/4] = value;
    } else if (address == 0x02000600) {
        record(address, value, 1); depth = value;
    } else if (address == 0x02000604 || address == 0x0200060c) {
        int banks = address == 0x0200060c ? 4 : 1;
        if (banks == 4) { ++batch_count; batch_busy=1; batch_valid=0; }
        else ++single_count;
        for (int bank=0; bank<banks; ++bank) {
            int64_t sum=0;
            for (int i=0; i<depth; ++i) {
                int32_t w=bank ? extra_weights[bank-1][i] : weight[i];
                captured[bank][i]=w;
                sum+=(int64_t)in[i]*w;
            }
            batch_results[bank]=(int32_t)(uint32_t)sum;
        }
        if (banks == 1) result=batch_results[0];
    } else if (address == 0x02000200) { record(address,value,1); raw = value; }
    else if (address == 0x02000204) { record(address,value,1); multiplier = value; }
    else if (address == 0x02000208) { record(address,value,1); shift = value; }
    else if (address == 0x02000210) {
        record(address,value,1);
        if (shift < 0 || shift > 30) abort();
        int64_t product = (int64_t)raw*multiplier;
        int32_t high = (int32_t)(uint32_t)arithmetic_right(product + (product >= 0 ?
            INT64_C(1073741824) : -INT64_C(1073741823)), 31);
        uint32_t mask = (UINT32_C(1) << shift)-1;
        uint32_t remainder = (uint32_t)high & mask;
        uint32_t threshold = (mask >> 1) + (high < 0);
        quant = (int32_t)(arithmetic_right(high, shift)+(remainder > threshold));
    } else abort();
}
int32_t pw_mmio_read(volatile int32_t *reg) {
    uintptr_t address = (uintptr_t)reg;
    int32_t value;
    if (address == 0x02000608 || (address >= 0x02000610 && address <= 0x0200061c)) {
        unsigned bank=address == 0x02000608 ? 0 : (unsigned)(address-0x02000610)/4;
        if (address != 0x02000608) {
            // A hardware result read waits for all four results to publish.
            if (batch_busy) { batch_busy=0; batch_valid=1; }
            if (!batch_valid) abort();
        }
        value=address == 0x02000608 ? result : batch_results[bank];
        for (int i=0; i<depth; ++i) record(0x02000500+4*i,captured[bank][i],1);
        record(0x02000604,1,1);
        record(0x02000608,value,0);
    } else if (address == 0x0200020c) { value = quant; record(address,value,0); }
    else abort();
    ++physical_count;
    return value;
}

/* Verified Level 2 reference. Physical batch ordering differs; canonical
 * traces place captured logical weights/trigger before each consumed result.
 * Quantizer ordering and values remain compared exactly. */
static void level2_reference(const int8_t *input_data, int spatial_size,
    int input_depth, int32_t input_offset, const int8_t *filter_data,
    const int32_t *bias_data, int output_depth, int8_t *output_data,
    int32_t output_offset, const int32_t *output_multiplier,
    const int8_t *output_shift, int32_t minimum, int32_t maximum) {
    PW_WRITE(PW_CONV_ACCEL_DEPTH, input_depth);
    for (int p=0; p<spatial_size; ++p) {
        for (int ic=0; ic<input_depth; ++ic)
            PW_WRITE(PW_CONV_ACCEL_INPUT+ic,
                (int32_t)input_data[ic*spatial_size+p]+input_offset);
        for (int oc=0; oc<output_depth; ++oc) {
            const int8_t *filter_ptr = &filter_data[oc*input_depth];
            int ic=0;
            for (; ic+3<input_depth; ic+=4) {
                uint32_t word=(uint32_t)(uint8_t)filter_ptr[ic] |
                    ((uint32_t)(uint8_t)filter_ptr[ic+1]<<8) |
                    ((uint32_t)(uint8_t)filter_ptr[ic+2]<<16) |
                    ((uint32_t)(uint8_t)filter_ptr[ic+3]<<24);
                PW_WRITE(PW_CONV_ACCEL_PACKED_WEIGHT+ic/4,(int32_t)word);
            }
            for (; ic<input_depth; ++ic)
                PW_WRITE(PW_CONV_ACCEL_WEIGHT+ic, (int32_t)filter_ptr[ic]);
            PW_WRITE(PW_CONV_ACCEL_CTRL, 1);
            int32_t acc = PW_READ(PW_CONV_ACCEL_RESULT);
            if (bias_data) acc += bias_data[oc];
            acc = MultiplyByQuantizedMultiplier(acc, output_multiplier[oc], output_shift[oc]);
            acc += output_offset;
            boundary_hits[0] += acc == minimum;
            boundary_hits[1] += acc == maximum;
            if (acc < minimum) { acc=minimum; ++clamp_hits[0]; }
            if (acc > maximum) { acc=maximum; ++clamp_hits[1]; }
            output_data[oc*spatial_size+p] = (int8_t)acc;
        }
    }
}
static uint32_t next_random(void) {
    random_state ^= random_state << 13;
    random_state ^= random_state >> 17;
    random_state ^= random_state << 5;
    return random_state;
}
static void reset_model(void) {
    memset(in,0,sizeof in); memset(weight,0,sizeof weight);
    memset(extra_weights,0,sizeof extra_weights); memset(captured,0,sizeof captured);
    memset(batch_results,0,sizeof batch_results);
    memset(resident,0,sizeof resident); preload_index=preload_writes=cached_triggers=0;
    batch_busy=batch_valid=0; batch_count=single_count=0;
    depth=result=raw=multiplier=shift=quant=0; trace_count=physical_count=packed_count=scalar_weight_count=0;
}

/* Independent per-pixel Conv0/DW1 reference with current hardware rounding.
 * Reconstruct the actual first-image PW1 input without external captured files. */
static int32_t reference_scale(int32_t acc, int32_t m, int8_t sh) {
    if (sh<0) acc=(int32_t)((uint32_t)acc << -sh);
    unsigned right=sh<0 ? 0 : (unsigned)sh;
    int64_t product=(int64_t)acc*m;
    int32_t hi=(int32_t)(uint32_t)arithmetic_right(product+
        (product>=0 ? INT64_C(1073741824) : -INT64_C(1073741823)),31);
    uint32_t mask=(UINT32_C(1)<<right)-1;
    return (int32_t)(arithmetic_right(hi,right)+(((uint32_t)hi&mask)>((mask>>1)+(hi<0))));
}
static int8_t reference_finish(int32_t acc,int32_t m,int8_t shift,int32_t offset) {
    acc=(int32_t)((uint32_t)reference_scale(acc,m,shift)+(uint32_t)offset);
    if (acc<-128) acc=-128;
    if (acc>127) acc=127;
    return (int8_t)acc;
}
static void save_tensor(const char *,const char *,const int8_t *,size_t);
static void first_image_pw1_input(int8_t *out,const char *artifacts) {
    int8_t conv[16*784];
    for (int c=0;c<16;++c) for (int y=0;y<28;++y) for (int x=0;x<28;++x) {
        uint32_t sum=(uint32_t)tmn_conv0_bias_data[c];
        for (int ky=0;ky<3;++ky) for (int kx=0;kx<3;++kx) {
            int iy=y+ky-1,ix=x+kx-1;
            if (iy>=0 && iy<28 && ix>=0 && ix<28)
                sum+=(uint32_t)((int64_t)(test_images[0][iy*28+ix]+tmn_conv0_input_offset)*tmn_conv0_kernel_data[c*9+ky*3+kx]);
        }
        conv[c*784+y*28+x]=reference_finish((int32_t)sum,tmn_conv0_output_multiplier[c],tmn_conv0_output_shift[c],tmn_conv0_output_offset);
    }
    save_tensor(artifacts,"Conv0_output.bin",conv,sizeof conv);
    for (int c=0;c<16;++c) for (int y=0;y<28;++y) for (int x=0;x<28;++x) {
        uint32_t sum=(uint32_t)tmn_dw1_bias_data[c];
        for (int ky=0;ky<3;++ky) for (int kx=0;kx<3;++kx) {
            int iy=y+ky-1,ix=x+kx-1;
            if (iy>=0 && iy<28 && ix>=0 && ix<28)
                sum+=(uint32_t)((int64_t)(conv[c*784+iy*28+ix]+tmn_dw1_input_offset)*tmn_dw1_kernel_data[c*9+ky*3+kx]);
        }
        out[c*784+y*28+x]=reference_finish((int32_t)sum,tmn_dw1_output_multiplier[c],tmn_dw1_output_shift[c],tmn_dw1_output_offset);
    }
}
static void save_tensor(const char *directory,const char *name,const int8_t *data,size_t size) {
    if (!directory) return;
    char path[1024]; if (snprintf(path,sizeof path,"%s/%s",directory,name)>=(int)sizeof path) abort();
    FILE *f=fopen(path,"wb"); if (!f || fwrite(data,1,size,f)!=size || fclose(f)) abort();
}
static void test_pw1_cache(const char *artifacts) {
    static int8_t input[16*784], filters_buf[516], expected[32*784], actual[32*784];
    int32_t biases[32], multipliers[32]; int8_t shifts[32];
    int dims[3]={28,28,16}, fd[3]={1,1,16}, od[3]={28,28,32}, bd[1]={32};
    for (int trial=0;trial<40;++trial) {
        int8_t *filters=filters_buf+trial%4;
        int32_t offset=trial==1 ? INT32_MAX : trial==2 ? INT32_MIN : trial%3==0 ? 128 : -17;
        int32_t out_offset=trial%2 ? -128 : 7;
        int low=trial%3==0 ? -10 : -128, high=trial%3==0 ? 10 : 127;
        for (int i=0;i<16*784;++i) input[i]=(int8_t)next_random();
        for (int i=0;i<512;++i) filters[i]=trial<4 ? (int8_t[]){-128,-1,0,127}[i%4] : (int8_t)next_random();
        if (trial==3) memset(input,0,sizeof input);
        if (trial==4) memset(filters,0,512);
        for (int c=0;c<32;++c) {
            biases[c]=(int32_t)next_random();
            multipliers[c]=trial<3 && c%3==0 ? INT32_MIN : (int32_t)(next_random()&0x7fffffff);
            shifts[c]=c%2 ? -3 : 4;
        }
        const int32_t *bias=trial%2 ? biases : NULL;
        if (!trial) {
            first_image_pw1_input(input,artifacts);
            memcpy(filters,tmn_pw1_kernel_data,512); memcpy(biases,tmn_pw1_bias_data,sizeof biases);
            memcpy(multipliers,tmn_pw1_output_multiplier,sizeof multipliers); memcpy(shifts,tmn_pw1_output_shift,sizeof shifts);
            bias=biases; offset=tmn_pw1_input_offset; out_offset=tmn_pw1_output_offset; low=-128; high=127;
            save_tensor(artifacts,"PW1_input.bin",input,sizeof input);
        }
        reset_model();
        Conv2DLevel4(input,dims,offset,filters,fd,bias,bd,1,1,0,0,expected,od,out_offset,multipliers,shifts,low,high);
        size_t n=trace_count, old_physical=physical_count;
        memcpy(baseline,trace,n*sizeof *trace);
        if (old_physical!=269697 || packed_count!=100352 || batch_count!=6272) abort();
        reset_model();
        Conv2D_TFLM(input,dims,offset,filters,fd,bias,bd,1,1,0,0,actual,od,out_offset,multipliers,shifts,low,high);
        if (memcmp(expected,actual,sizeof actual) || n!=trace_count || preload_writes!=128 ||
            packed_count || scalar_weight_count || cached_triggers!=6272 || physical_count!=169474) abort();
        for (size_t i=0;i<n;++i)
            if (baseline[i].address!=trace[i].address || baseline[i].value!=trace[i].value || baseline[i].write!=trace[i].write) abort();
        if (!trial) {
            save_tensor(artifacts,"PW1_output.bin",actual,sizeof actual);
            printf("[PASS] actual first-image PW1 tensor: 25088 bytes; MMIO 269697 -> 169474\n");
        }
    }
    printf("[PASS] PW1 cache: 40 complete tensors, ordered logical PW/quantizer traces, signed/wrap/offset/bias/clamp/shift/alignment/random\n");
}

int main(int argc, char **argv) {
    const int depths[] = {1,16,32,48,64,3,17,63};
    int8_t input[64*6], filter_storage[64*9+4], expected[6*9], actual[6*9], shifts[9];
    int32_t biases[9], multipliers[9];
    for (unsigned di=0; di<sizeof depths/sizeof depths[0]; ++di) {
        int d=depths[di];
        for (int trial=0; trial<128; ++trial) {
            int spatial=trial%6+1, channels=trial%9+1;
            int8_t *filters=filter_storage+(trial%4); // exercise alignment 0..3
            int negative_shift=(trial%4==0 || trial%4==1) && trial!=1 && trial!=5 && trial<126;
            int offset=negative_shift ? 128 : (trial%3==0 ? -17 : trial%3==1 ? 0 : 128);
            int minimum=trial%3==0 ? -10 : -128;
            int maximum=trial%3==0 ? 10 : 127;
            for (int i=0; i<d*spatial; ++i)
                input[i]=negative_shift ? (int8_t)(next_random()%128) : (int8_t)(next_random()%256-128);
            for (int i=0; i<d*channels; ++i)
                filters[i]=negative_shift ? (int8_t)(next_random()%128) : (int8_t)(next_random()%256-128);
            // Directed zero and signed-extreme cases supplement random coverage.
            if (trial==1) memset(input,0,sizeof input);
            if (trial==2) memset(filters,0,64*9);
            if (trial==3) { memset(input,0x80,sizeof input); memset(filters,0x7f,64*9); }
            if (trial==5) { memset(input,0x7f,sizeof input); memset(filters,0x80,64*9); }
            for (int oc=0; oc<channels; ++oc) {
                biases[oc]=negative_shift ? 100 : (int32_t)(next_random()%20001)-10000;
                multipliers[oc]=INT32_C(1073741824)+(int32_t)(next_random()%1073741824);
                shifts[oc]=negative_shift ? -2 : (int8_t)(next_random()%10);
                ++shift_hits[negative_shift];
            }
            if (trial>=126) {
                offset=0; minimum=-10; maximum=10;
                memset(input,0,sizeof input); memset(filters,0,64*9);
                for (int oc=0; oc<channels; ++oc) {
                    biases[oc]=trial==126 ? 236 : 276;
                    multipliers[oc]=INT32_C(1073741824); shifts[oc]=0;
                }
            }
            const int32_t *bias=(trial%2 || trial>=126) ? biases : NULL;
            reset_model();
            level2_reference(input,spatial,d,offset,filters,bias,channels,expected,-128,
                multipliers,shifts,minimum,maximum);
            total_level2_physical += physical_count;
            size_t count=trace_count;
            memcpy(baseline,trace,count*sizeof trace[0]);
            size_t wanted=1+(size_t)spatial*(d+channels*(d+7));
            if (count!=wanted) abort();
            reset_model();
            int input_dims[]={spatial,1,d}, filter_dims[]={1,1,d,channels};
            int output_dims[]={spatial,1,channels}, bias_dims[]={channels};
            Conv2D_TFLM(input,input_dims,offset,filters,filter_dims,bias,bias_dims,
                1,1,0,0,actual,output_dims,-128,multipliers,shifts,minimum,maximum);
            size_t output_count=(size_t)spatial*channels;
            size_t groups=(size_t)channels/4, tail=(size_t)channels%4;
            size_t wanted_packed=(size_t)spatial*(4*groups*((d+3)/4)+tail*(d/4));
            size_t wanted_scalar=(size_t)spatial*tail*(d%4);
            size_t wanted_batches=(size_t)spatial*groups;
            size_t wanted_singles=(size_t)spatial*tail;
            size_t wanted_physical=1+(size_t)spatial*d+wanted_packed+wanted_scalar+
                wanted_batches+wanted_singles+6*output_count;
            if (packed_count!=wanted_packed || scalar_weight_count!=wanted_scalar ||
                physical_count!=wanted_physical || batch_count!=wanted_batches || single_count!=wanted_singles) {
                fprintf(stderr,"FAIL depth=%d trial=%d packed/scalar/physical counts\n",d,trial);
                return 1;
            }
            total_physical+=physical_count; total_packed+=packed_count; total_batches+=batch_count; total_singles+=single_count;
            if (trace_count!=count || memcmp(actual,expected,spatial*channels)) {
                fprintf(stderr,"FAIL depth=%d trial=%d outputs/count\n",d,trial); return 1;
            }
            for (size_t i=0; i<count; ++i) {
                if (trace[i].address!=baseline[i].address || trace[i].value!=baseline[i].value ||
                    trace[i].write!=baseline[i].write) {
                    fprintf(stderr,"FAIL depth=%d trial=%d transaction=%zu\n",d,trial,i); return 1;
                }
                ++comparisons;
            }
            ++cases;
        }
        printf("[PASS] firmware PW depth %d: outputs and ordered PW/quantizer trace\n",d);
    }
    if (!clamp_hits[0] || !clamp_hits[1] || !shift_hits[0] || !shift_hits[1] || !boundary_hits[0] || !boundary_hits[1]) abort();
    printf("LEGACY FIRMWARE PW TESTS PASSED: %u cases, %u transactions; both clamp boundaries and shift signs covered\n",
        cases,comparisons);
    printf("Physical MMIO: Level 2 %zu; batch %zu; saved %zu; packed writes %zu\n",
        total_level2_physical,total_physical,total_level2_physical-total_physical,total_packed);
    printf("Batch triggers: %zu; legacy tail triggers: %zu\n",total_batches,total_singles);
    test_pw1_cache(argc>1 ? argv[1] : NULL);
    printf("ALL FIRMWARE PW TESTS PASSED: %u legacy cases + 40 full cached PW1 cases\n", cases);
    return 0;
}
