/* Host verification of the actual hardware PW path and its dispatch.
 * No NATIVE_RUN: MMIO is intercepted, while production arithmetic is retained.
 * Build: cc -O2 verify_pw_firmware.c quantize.c -o /tmp/verify_pw_firmware
 */
#define PW_MMIO_TEST
#include "dl_ops.c"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct transaction { uintptr_t address; int32_t value; int write; };
static struct transaction trace[8192], baseline[8192];
static size_t trace_count, physical_count, packed_count, scalar_weight_count;
static size_t total_physical, total_packed;
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
    if (address >= 0x02000700 && address <= 0x0200073c) {
        unsigned lane = (unsigned)((address - 0x02000700) / 4) * 4;
        ++packed_count;
        for (unsigned byte = 0; byte < 4; ++byte) {
            unsigned bits = ((uint32_t)value >> (8 * byte)) & 255;
            int32_t signed_byte = bits < 128 ? (int32_t)bits : (int32_t)bits - 256;
            weight[lane + byte] = signed_byte;
            record(0x02000500 + 4 * (lane + byte), signed_byte, 1);
        }
        return;
    }
    if (address >= 0x02000500 && address < 0x02000600) ++scalar_weight_count;
    record(address, value, 1);
    if (address >= 0x02000400 && address < 0x02000500)
        in[(address-0x02000400)/4] = value;
    else if (address >= 0x02000500 && address < 0x02000600)
        weight[(address-0x02000500)/4] = value;
    else if (address == 0x02000600) depth = value;
    else if (address == 0x02000604) {
        int64_t sum = 0;
        for (int i=0; i<depth; ++i) sum += (int64_t)in[i]*weight[i];
        if (sum < INT32_MIN || sum > INT32_MAX) abort();
        result = (int32_t)sum;
    } else if (address == 0x02000200) raw = value;
    else if (address == 0x02000204) multiplier = value;
    else if (address == 0x02000208) shift = value;
    else if (address == 0x02000210) {
        if (shift < 0 || shift > 30) abort();
        int64_t product = (int64_t)raw*multiplier;
        int64_t high = arithmetic_right(product + (product >= 0 ?
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
    if (address == 0x02000608) value = result;
    else if (address == 0x0200020c) value = quant;
    else abort();
    ++physical_count;
    record(address, value, 0);
    return value;
}

/* Level 1 reference: four separate legacy writes and a scalar remainder.
 * Its ordered logical trace is compared with expanded Level 2 packed writes.
 */
static void scalar_reference(const int8_t *input_data, int spatial_size,
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
                PW_WRITE(PW_CONV_ACCEL_WEIGHT+ic, (int32_t)filter_ptr[ic]);
                PW_WRITE(PW_CONV_ACCEL_WEIGHT+ic+1, (int32_t)filter_ptr[ic+1]);
                PW_WRITE(PW_CONV_ACCEL_WEIGHT+ic+2, (int32_t)filter_ptr[ic+2]);
                PW_WRITE(PW_CONV_ACCEL_WEIGHT+ic+3, (int32_t)filter_ptr[ic+3]);
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
    depth=result=raw=multiplier=shift=quant=0; trace_count=physical_count=packed_count=scalar_weight_count=0;
}
int main(void) {
    const int depths[] = {1,16,32,48,64,3,17,63};
    int8_t input[64*6], filters[64*5], expected[6*5], actual[6*5], shifts[5];
    int32_t biases[5], multipliers[5];
    for (unsigned di=0; di<sizeof depths/sizeof depths[0]; ++di) {
        int d=depths[di];
        for (int trial=0; trial<128; ++trial) {
            int spatial=trial%6+1, channels=trial%5+1;
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
            if (trial==2) memset(filters,0,sizeof filters);
            if (trial==3) { memset(input,0x80,sizeof input); memset(filters,0x7f,sizeof filters); }
            if (trial==5) { memset(input,0x7f,sizeof input); memset(filters,0x80,sizeof filters); }
            for (int oc=0; oc<channels; ++oc) {
                biases[oc]=negative_shift ? 100 : (int32_t)(next_random()%20001)-10000;
                multipliers[oc]=INT32_C(1073741824)+(int32_t)(next_random()%1073741824);
                shifts[oc]=negative_shift ? -2 : (int8_t)(next_random()%10);
                ++shift_hits[negative_shift];
            }
            if (trial>=126) {
                offset=0; minimum=-10; maximum=10;
                memset(input,0,sizeof input); memset(filters,0,sizeof filters);
                for (int oc=0; oc<channels; ++oc) {
                    biases[oc]=trial==126 ? 236 : 276;
                    multipliers[oc]=INT32_C(1073741824); shifts[oc]=0;
                }
            }
            const int32_t *bias=(trial%2 || trial>=126) ? biases : NULL;
            reset_model();
            scalar_reference(input,spatial,d,offset,filters,bias,channels,expected,-128,
                multipliers,shifts,minimum,maximum);
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
            size_t wanted_packed=output_count*(d/4);
            size_t wanted_scalar=output_count*(d%4);
            size_t wanted_physical=1+(size_t)spatial*d+output_count*(d/4+d%4+7);
            if (packed_count!=wanted_packed || scalar_weight_count!=wanted_scalar ||
                physical_count!=wanted_physical) {
                fprintf(stderr,"FAIL depth=%d trial=%d packed/scalar/physical counts\n",d,trial);
                return 1;
            }
            total_physical+=physical_count; total_packed+=packed_count;
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
    printf("ALL FIRMWARE PW TESTS PASSED: %u cases, %u transactions; both clamp boundaries and shift signs covered\n",
        cases,comparisons);
    printf("Physical MMIO: %zu; packed writes: %zu; saved: %zu\n",
        total_physical,total_packed,(size_t)comparisons-total_physical);
    return 0;
}
