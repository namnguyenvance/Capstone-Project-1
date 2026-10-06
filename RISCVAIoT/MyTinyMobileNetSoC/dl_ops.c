#include "dl_ops.h"

/* ========================================================================
 * Hardware Accelerator Definitions
 * ======================================================================== */

/* Standard 3x3 Convolution Accelerator (reused from LeNet5) */
#ifndef NATIVE_RUN
#define CONV_ACCEL_BASE  0x02000100
#define CONV_ACCEL_IMG   ((volatile int32_t*)(CONV_ACCEL_BASE + 0x00))
#define CONV_ACCEL_KER   ((volatile int32_t*)(CONV_ACCEL_BASE + 0x70))
#define CONV_ACCEL_OUT   ((volatile int32_t*)(CONV_ACCEL_BASE + 0xA0))
#define CONV_ACCEL_CTRL  ((volatile int32_t*)(CONV_ACCEL_BASE + 0xF0))

/* Quantization Accelerator (reused from LeNet5) */
#define QUANT_ACCEL_BASE 0x02000200
#define QUANT_ACCEL_RAW   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x00))
#define QUANT_ACCEL_MUL   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x04))
#define QUANT_ACCEL_SHIFT ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x08))
#define QUANT_ACCEL_OUT   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x0C))
#define QUANT_ACCEL_CTRL  ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x10))

/* NEW: Depthwise Convolution Accelerator */
#define DW_CONV_ACCEL_BASE  0x02000300
#define DW_CONV_ACCEL_IMG   ((volatile int32_t*)(DW_CONV_ACCEL_BASE + 0x00))
#define DW_CONV_ACCEL_KER   ((volatile int32_t*)(DW_CONV_ACCEL_BASE + 0x70))
#define DW_CONV_ACCEL_OUT   ((volatile int32_t*)(DW_CONV_ACCEL_BASE + 0xA0))
#define DW_CONV_ACCEL_CTRL  ((volatile int32_t*)(DW_CONV_ACCEL_BASE + 0xF0))

/* NEW: Pointwise (1x1) Convolution Accelerator */
#define PW_CONV_ACCEL_BASE   0x02000400
#define PW_CONV_ACCEL_INPUT  ((volatile int32_t*)(PW_CONV_ACCEL_BASE + 0x000))
#define PW_CONV_ACCEL_WEIGHT ((volatile int32_t*)(PW_CONV_ACCEL_BASE + 0x100))
#define PW_CONV_ACCEL_DEPTH  ((volatile int32_t*)(PW_CONV_ACCEL_BASE + 0x200))
#define PW_CONV_ACCEL_CTRL   ((volatile int32_t*)(PW_CONV_ACCEL_BASE + 0x204))
#define PW_CONV_ACCEL_RESULT ((volatile int32_t*)(PW_CONV_ACCEL_BASE + 0x208))
#endif


/* ========================================================================
 * Quantization Helper (via hardware accelerator)
 * ======================================================================== */
int32_t MultiplyByQuantizedMultiplierSmallerThanOne(
    int32_t x, 
    int32_t quantized_multiplier, 
    uint8_t right_shift 
) {
#ifndef NATIVE_RUN
    *QUANT_ACCEL_RAW = x;
    *QUANT_ACCEL_MUL = quantized_multiplier;
    *QUANT_ACCEL_SHIFT = right_shift;
    *QUANT_ACCEL_CTRL = 1;
    return *QUANT_ACCEL_OUT;
#else
    return RoundingDivideByPOT(
        SaturatingRoundingDoublingHighMul(x, quantized_multiplier),
        right_shift
    );
#endif
}

int32_t MultiplyByQuantizedMultiplier(
    int32_t x, 
    int32_t quantized_multiplier, 
    int8_t shift 
) {
    if (shift < 0) {
        x = x << (-shift);
        return MultiplyByQuantizedMultiplierSmallerThanOne(x, quantized_multiplier, 0);
    } else {
        return MultiplyByQuantizedMultiplierSmallerThanOne(x, quantized_multiplier, shift);
    }
}


/* ========================================================================
 * Standard 2D Convolution (Conv2D_TFLM)
 * Used for the initial 3x3 conv layer that bootstraps channels.
 * Reused from LeNet5 with both accelerated (3x3 s1) and generic paths.
 * ======================================================================== */
void Conv2D_TFLM(
    const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims, 
    const int32_t* bias_data , const int* bias_dims, 
    int stride_width, int stride_height, 
    int pad_width   , int pad_height, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    const int32_t* output_multiplier, 
    const int8_t*  output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    const int input_depth   = input_dims[2];
    const int output_depth  = output_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int filter_height = filter_dims[1];
    const int filter_width  = filter_dims[0];
    const int filter_depth  = filter_dims[2];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    /* Accelerated path: 3x3 kernel, stride 1 — compute 3x3 output tile per pass */
#ifndef NATIVE_RUN
    if (filter_width == 3 && filter_height == 3 && stride_width == 1 && stride_height == 1) {
        for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
            for (int out_y = 0; out_y < output_height; out_y += 3) {
                for (int out_x = 0; out_x < output_width; out_x += 3) {
                    int32_t acc[9];
                    for (int i = 0; i < 9; ++i) {
                        acc[i] = bias_data ? bias_data[out_channel] : 0;
                    }
                    for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                        for (int filter_y = 0; filter_y < 3; ++filter_y) {
                            for (int filter_x = 0; filter_x < 3; ++filter_x) {
                                CONV_ACCEL_KER[filter_y * 3 + filter_x] = filter_data[
                                    out_channel * filter_depth * 9 + 
                                        in_channel * 9 + 
                                            filter_y * 3 + filter_x];
                            }
                        }

                        const int in_x_origin = (out_x * stride_width) - pad_width;
                        const int in_y_origin = (out_y * stride_height) - pad_height;

                        for (int iy = 0; iy < 5; ++iy) {
                            for (int ix = 0; ix < 5; ++ix) {
                                const int in_x = in_x_origin + ix;
                                const int in_y = in_y_origin + iy;
                                int32_t val = 0;
                                if ((in_x >= 0) && (in_x < input_width) 
                                 && (in_y >= 0) && (in_y < input_height)) {
                                    val = input_data[
                                        in_channel * input_height * input_width + in_y * input_width + in_x] + input_offset;
                                }
                                CONV_ACCEL_IMG[iy * 5 + ix] = val;
                            }
                        }

                        CONV_ACCEL_CTRL[0] = 1;
                        for (int i = 0; i < 9; ++i) {
                            acc[i] += CONV_ACCEL_OUT[i];
                        }
                    }

                    for (int i = 0; i < 3; ++i) {
                        for (int j = 0; j < 3; ++j) {
                            if ((out_y + i) < output_height && (out_x + j) < output_width) {
                                int32_t final_acc = MultiplyByQuantizedMultiplier(
                                    acc[i * 3 + j], output_multiplier[out_channel], output_shift[out_channel]);

                                final_acc = final_acc + output_offset;
                                final_acc = (final_acc < output_activation_min) ? output_activation_min : final_acc;
                                final_acc = (final_acc > output_activation_max) ? output_activation_max : final_acc;

                                output_data[out_channel * output_height * output_width + 
                                            (out_y + i) * output_width + (out_x + j)] = (int8_t)final_acc;
                            }
                        }
                    }
                }
            }
        }
    } else if (filter_width == 1 && filter_height == 1 && stride_width == 1 && stride_height == 1) {
        /* Hardware-accelerated 1x1 Pointwise Convolution via dot product engine.
         * 
         * For each spatial position:
         *   1. Load input vector (all channels at this position) to PW accel INPUT buffer
         *   2. For each output channel:
         *      - Load weight vector to PW accel WEIGHT buffer
         *      - Trigger dot product (single-cycle hardware computation)
         *      - Read result, add bias, quantize, store
         *
         * Key optimization: input vector loaded ONCE per spatial position,
         * reused across all output channels.
         */
        const int spatial_size = input_height * input_width;
        
        /* Set dot product length (once per layer) */
        *PW_CONV_ACCEL_DEPTH = input_depth;
        
        for (int p = 0; p < spatial_size; ++p) {
            /* Load input values for this spatial position (all channels) */
            for (int ic = 0; ic < input_depth; ++ic) {
                PW_CONV_ACCEL_INPUT[ic] = (int32_t)input_data[ic * spatial_size + p] + input_offset;
            }
            
            for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                /* Load weights for this output channel */
                const int8_t* filter_ptr = &filter_data[out_channel * input_depth];
                for (int ic = 0; ic < input_depth; ++ic) {
                    PW_CONV_ACCEL_WEIGHT[ic] = (int32_t)filter_ptr[ic];
                }
                
                /* Trigger dot product computation */
                *PW_CONV_ACCEL_CTRL = 1;
                
                /* Read dot product result and add bias */
                int32_t acc = *PW_CONV_ACCEL_RESULT;
                if (bias_data) acc += bias_data[out_channel];
                
                /* Apply quantization scaling */
                acc = MultiplyByQuantizedMultiplier(
                    acc, output_multiplier[out_channel], output_shift[out_channel]);
                
                acc = acc + output_offset;
                acc = (acc < output_activation_min) ? output_activation_min : acc;
                acc = (acc > output_activation_max) ? output_activation_max : acc;
                
                output_data[out_channel * spatial_size + p] = (int8_t)acc;
            }
        }
    } else 
#endif
    {
        /* Generic path: any kernel size, any stride */
        for (int out_y = 0; out_y < output_height; ++out_y) {
            for (int out_x = 0; out_x < output_width; ++out_x) {
                for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                    const int in_x_origin = (out_x * stride_width) - pad_width;
                    const int in_y_origin = (out_y * stride_height) - pad_height;

                    int32_t acc = 0;

                    if (bias_data) 
                        acc += bias_data[out_channel];

                    for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                        for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                            for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                                const int in_x = in_x_origin + filter_x;
                                const int in_y = in_y_origin + filter_y;

                                if ((in_x >= 0) && (in_x < input_width) 
                                 && (in_y >= 0) && (in_y < input_height)) {
                                    int32_t input_val = input_data[
                                        in_channel * input_height * input_width + in_y * input_width + in_x];
                                    int32_t filter_val = filter_data[
                                        out_channel * filter_depth * filter_height * filter_width + 
                                            in_channel * filter_height * filter_width + 
                                                filter_y * filter_width + filter_x];

                                    acc += filter_val * (input_val + input_offset);
                                }
                            }
                        }
                    }

                    acc = MultiplyByQuantizedMultiplier(
                        acc, output_multiplier[out_channel], output_shift[out_channel]);

                    acc = acc + output_offset;
                    acc = (acc < output_activation_min) ? output_activation_min : acc;
                    acc = (acc > output_activation_max) ? output_activation_max : acc;

                    output_data[out_channel * output_height * output_width + out_y * output_width + out_x] = (int8_t)(acc);
                }
            }
        }
    }
}


/* ========================================================================
 * Depthwise 2D Convolution (DepthwiseConv2D_TFLM)
 * 
 * THE CORE MOBILENET OPERATION — completely different from standard Conv2D!
 * 
 * Standard Conv2D: output[oc] = sum over ALL input channels
 * Depthwise Conv:  output[ic*dm+m] = convolve ONLY input channel ic
 * 
 * This means each filter only operates on a SINGLE input channel,
 * making it much cheaper computationally.
 *
 * Uses the DW conv accelerator for 3x3 stride-1 case,
 * falls back to software for stride-2 case.
 * ======================================================================== */
void DepthwiseConv2D_TFLM(
    const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims,
    int stride_width, int stride_height,
    int pad_width   , int pad_height,
    int depth_multiplier,
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
    const int32_t* output_multiplier,
    const int8_t*  output_shift,
    int32_t output_activation_min, int32_t output_activation_max
) {
    const int input_depth   = input_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int filter_height = filter_dims[1];
    const int filter_width  = filter_dims[0];
    const int output_depth  = output_dims[2];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    /*
     * Accelerated path: 3x3 kernel, stride 1, depth_multiplier 1
     * Uses the dedicated DW conv accelerator which processes one channel
     * at a time with a 5x5 input tile → 3x3 output tile.
     * 
     * Key difference from standard conv accel:
     *   Standard conv accel: called N times per output pixel (N = input channels), accumulates
     *   DW conv accel: called ONCE per channel, independent — no cross-channel accumulation!
     */
#ifndef NATIVE_RUN
    if (filter_width == 3 && filter_height == 3 && stride_width == 1 && stride_height == 1 && depth_multiplier == 1) {
        for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
            int out_channel = in_channel; /* depth_multiplier == 1 */

            /* Load kernel for this single channel (9 values) */
            for (int ky = 0; ky < 3; ++ky) {
                for (int kx = 0; kx < 3; ++kx) {
                    DW_CONV_ACCEL_KER[ky * 3 + kx] = filter_data[
                        in_channel * 9 + ky * 3 + kx];
                }
            }

            /* Process output in 3x3 tiles */
            for (int out_y = 0; out_y < output_height; out_y += 3) {
                for (int out_x = 0; out_x < output_width; out_x += 3) {

                    /* Load 5x5 input tile for this channel */
                    const int in_x_origin = out_x - pad_width;
                    const int in_y_origin = out_y - pad_height;

                    for (int iy = 0; iy < 5; ++iy) {
                        for (int ix = 0; ix < 5; ++ix) {
                            const int in_x = in_x_origin + ix;
                            const int in_y = in_y_origin + iy;
                            int32_t val = 0;
                            if ((in_x >= 0) && (in_x < input_width) 
                             && (in_y >= 0) && (in_y < input_height)) {
                                val = input_data[
                                    in_channel * input_height * input_width + 
                                    in_y * input_width + in_x] + input_offset;
                            }
                            DW_CONV_ACCEL_IMG[iy * 5 + ix] = val;
                        }
                    }

                    /* Trigger computation */
                    DW_CONV_ACCEL_CTRL[0] = 1;

                    /* Read 3x3 output tile and apply bias + quantize */
                    for (int i = 0; i < 3; ++i) {
                        for (int j = 0; j < 3; ++j) {
                            if ((out_y + i) < output_height && (out_x + j) < output_width) {
                                int32_t acc = DW_CONV_ACCEL_OUT[i * 3 + j];

                                /* Add bias (this is the ONLY accumulation — no cross-channel!) */
                                if (bias_data) acc += bias_data[out_channel];

                                acc = MultiplyByQuantizedMultiplier(
                                    acc, output_multiplier[out_channel], output_shift[out_channel]);

                                acc = acc + output_offset;
                                acc = (acc < output_activation_min) ? output_activation_min : acc;
                                acc = (acc > output_activation_max) ? output_activation_max : acc;

                                output_data[out_channel * output_height * output_width + 
                                            (out_y + i) * output_width + (out_x + j)] = (int8_t)acc;
                            }
                        }
                    }
                }
            }
        }
    } else if (filter_width == 3 && filter_height == 3 && stride_width == 2 && stride_height == 2 && depth_multiplier == 1) {
        /* Highly optimized software path for stride-2 Depthwise Convolution */
        const int in_ch_size = input_height * input_width;
        const int out_ch_size = output_height * output_width;
        
        for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
            const int8_t* in_ptr = &input_data[in_channel * in_ch_size];
            int8_t* out_ptr = &output_data[in_channel * out_ch_size];
            const int8_t* filter_ptr = &filter_data[in_channel * 9];
            int32_t bias = bias_data ? bias_data[in_channel] : 0;
            
            for (int out_y = 0; out_y < output_height; ++out_y) {
                const int in_y_origin = (out_y * 2) - pad_height;
                for (int out_x = 0; out_x < output_width; ++out_x) {
                    const int in_x_origin = (out_x * 2) - pad_width;
                    int32_t acc = bias;
                    
                    for (int fy = 0; fy < 3; ++fy) {
                        const int in_y = in_y_origin + fy;
                        if (in_y >= 0 && in_y < input_height) {
                            for (int fx = 0; fx < 3; ++fx) {
                                const int in_x = in_x_origin + fx;
                                if (in_x >= 0 && in_x < input_width) {
                                    acc += filter_ptr[fy * 3 + fx] * (in_ptr[in_y * input_width + in_x] + input_offset);
                                }
                            }
                        }
                    }
                    
                    acc = MultiplyByQuantizedMultiplier(acc, output_multiplier[in_channel], output_shift[in_channel]);
                    acc += output_offset;
                    acc = (acc < output_activation_min) ? output_activation_min : acc;
                    acc = (acc > output_activation_max) ? output_activation_max : acc;
                    out_ptr[out_y * output_width + out_x] = (int8_t)acc;
                }
            }
        }
    } else 
#endif
    {
        /* Generic software path: any stride, any kernel size, any depth_multiplier */
        for (int out_y = 0; out_y < output_height; ++out_y) {
            for (int out_x = 0; out_x < output_width; ++out_x) {
                for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                    for (int m = 0; m < depth_multiplier; ++m) {
                        int out_channel = in_channel * depth_multiplier + m;
                        const int in_x_origin = (out_x * stride_width) - pad_width;
                        const int in_y_origin = (out_y * stride_height) - pad_height;

                        int32_t acc = 0;
                        if (bias_data) acc += bias_data[out_channel];

                        /* Key difference: only iterate over ONE input channel! */
                        for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                            for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                                const int in_x = in_x_origin + filter_x;
                                const int in_y = in_y_origin + filter_y;

                                if ((in_x >= 0) && (in_x < input_width) 
                                 && (in_y >= 0) && (in_y < input_height)) {
                                    int32_t input_val = input_data[
                                        in_channel * input_height * input_width + 
                                        in_y * input_width + in_x];
                                    int32_t filter_val = filter_data[
                                        in_channel * depth_multiplier * filter_height * filter_width +
                                        m * filter_height * filter_width +
                                        filter_y * filter_width + filter_x];

                                    acc += filter_val * (input_val + input_offset);
                                }
                            }
                        }

                        acc = MultiplyByQuantizedMultiplier(
                            acc, output_multiplier[out_channel], output_shift[out_channel]);

                        acc = acc + output_offset;
                        acc = (acc < output_activation_min) ? output_activation_min : acc;
                        acc = (acc > output_activation_max) ? output_activation_max : acc;

                        output_data[out_channel * output_height * output_width + 
                                    out_y * output_width + out_x] = (int8_t)acc;
                    }
                }
            }
        }
    }
}


/* ========================================================================
 * Global Average Pooling (GlobalAveragePool_TFLM)
 * 
 * NEW OPERATION — not in LeNet-5!
 * 
 * Instead of flattening H×W×C = 4096 values and using a huge FC layer,
 * we average each channel's spatial values down to a single number.
 * Input:  H x W x C  →  Output: C
 * 
 * This dramatically reduces the number of FC parameters needed.
 * ======================================================================== */
void GlobalAveragePool_TFLM(
    const int8_t* input_data, const int* input_dims,
    int8_t* output_data,
    int32_t input_offset, int32_t output_offset,
    int32_t output_multiplier, int8_t output_shift,
    int32_t output_activation_min, int32_t output_activation_max
) {
    const int input_width  = input_dims[0];
    const int input_height = input_dims[1];
    const int depth        = input_dims[2];
    const int num_elements = input_width * input_height;

    for (int channel = 0; channel < depth; ++channel) {
        /* Sum all spatial positions for this channel */
        int32_t acc = 0;
        for (int y = 0; y < input_height; ++y) {
            for (int x = 0; x < input_width; ++x) {
                acc += (int32_t)input_data[
                    channel * input_height * input_width + y * input_width + x] + input_offset;
            }
        }

        /* 
         * Divide by number of spatial elements (H * W)
         * Use integer division — sufficient for quantized inference.
         * The TFLite reference also uses simple integer division here.
         *
         * We implement division using repeated subtraction since PicoRV32
         * doesn't have hardware divider (ENABLE_DIV=0).
         */
        int32_t sign = 1;
        int32_t abs_acc = acc;
        if (acc < 0) {
            sign = -1;
            abs_acc = -acc;
        }
        int32_t avg = 0;
        int32_t remainder = abs_acc;
        /* Use shift-and-subtract division */
        for (int bit = 31; bit >= 0; --bit) {
            int32_t shifted = num_elements << bit;
            if (shifted > 0 && remainder >= shifted) {
                remainder -= shifted;
                avg |= (1 << bit);
            }
        }
        /* Round: if remainder >= num_elements/2, round up */
        if (remainder * 2 >= num_elements) {
            avg += 1;
        }
        acc = sign * avg;

        /* Apply quantization scaling */
        acc = MultiplyByQuantizedMultiplier(
            acc, output_multiplier, output_shift);

        acc = acc + output_offset;
        acc = (acc < output_activation_min) ? output_activation_min : acc;
        acc = (acc > output_activation_max) ? output_activation_max : acc;

        output_data[channel] = (int8_t)acc;
    }
}


/* ========================================================================
 * Fully Connected / Dense Layer (FullyConnected2D_TFLM)
 * Reused from LeNet5.
 * ======================================================================== */
void FullyConnected2D_TFLM(
    const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims, 
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    const int output_depth = output_dims[0];
    const int accum_depth  = input_dims[0];

    for (int out_c = 0; out_c < output_depth; ++out_c) {
        int32_t acc = 0;
        if (bias_data) {
            acc += bias_data[out_c];
        }

        for (int d = 0; d < accum_depth; ++d) { 
            int32_t input_val  = input_data[d];
            int32_t filter_val = filter_data[out_c * accum_depth + d];
            acc += filter_val * (input_val + input_offset);
        }

        acc = MultiplyByQuantizedMultiplier(
            acc, output_multiplier, output_shift);

        acc = acc + output_offset;
        acc = (acc < output_activation_min) ? output_activation_min : acc;
        acc = (acc > output_activation_max) ? output_activation_max : acc;

        output_data[out_c] = (int8_t)(acc);
    }
}
