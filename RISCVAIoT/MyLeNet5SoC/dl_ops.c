#include "dl_ops.h"

#define CONV_ACCEL_BASE  0x02000100
#define CONV_ACCEL_IMG   ((volatile int32_t*)(CONV_ACCEL_BASE + 0x00))
#define CONV_ACCEL_KER   ((volatile int32_t*)(CONV_ACCEL_BASE + 0x70))
#define CONV_ACCEL_OUT   ((volatile int32_t*)(CONV_ACCEL_BASE + 0xA0))
#define CONV_ACCEL_CTRL  ((volatile int32_t*)(CONV_ACCEL_BASE + 0xF0))

#define QUANT_ACCEL_BASE 0x02000200
#define QUANT_ACCEL_RAW   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x00))
#define QUANT_ACCEL_MUL   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x04))
#define QUANT_ACCEL_SHIFT ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x08))
#define QUANT_ACCEL_OUT   ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x0C))
#define QUANT_ACCEL_CTRL  ((volatile int32_t*)(QUANT_ACCEL_BASE + 0x10))

int32_t MultiplyByQuantizedMultiplierSmallerThanOne(
    int32_t x, 
    int32_t quantized_multiplier, 
    uint8_t right_shift 
) {
    *QUANT_ACCEL_RAW = x;
    *QUANT_ACCEL_MUL = quantized_multiplier;
    *QUANT_ACCEL_SHIFT = right_shift;
    *QUANT_ACCEL_CTRL = 1;
    return *QUANT_ACCEL_OUT;
}

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
                                int32_t final_acc = MultiplyByQuantizedMultiplierSmallerThanOne(
                                    acc[i * 3 + j], output_multiplier[out_channel], output_shift[out_channel]);

                                final_acc = (final_acc < output_activation_min) ? output_activation_min : final_acc;
                                final_acc = (final_acc > output_activation_max) ? output_activation_max : final_acc;
                                final_acc = final_acc - output_offset;

                                output_data[out_channel * output_height * output_width + 
                                            (out_y + i) * output_width + (out_x + j)] = (int8_t)final_acc;
                            }
                        }
                    }
                }
            }
        }
    } else {
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

                    acc = MultiplyByQuantizedMultiplierSmallerThanOne(
                        acc, output_multiplier[out_channel], output_shift[out_channel]);

                    acc = (acc < output_activation_min) ? output_activation_min : acc;
                    acc = (acc > output_activation_max) ? output_activation_max : acc;

                    acc = acc - output_offset;

                    output_data[out_channel * output_height * output_width + out_y * output_width + out_x] = (int8_t)(acc);
                }
            }
        }
    }
}

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

        acc = MultiplyByQuantizedMultiplierSmallerThanOne(
            acc, output_multiplier, output_shift);

        acc = (acc < output_activation_min) ? output_activation_min : acc;
        acc = (acc > output_activation_max) ? output_activation_max : acc;

        acc = acc - output_offset;
        output_data[out_c] = (int8_t)(acc);
    }
}

void MaxPool_TFLM(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int pad_width, int pad_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims,
    int32_t output_activation_min, int32_t output_activation_max
) {
    const int depth         = input_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int channel = 0; channel < depth; ++channel) {
                const int in_x_origin = (out_x * stride_width) - pad_width;
                const int in_y_origin = (out_y * stride_height) - pad_height;

                const int filter_x_start = (0 > -in_x_origin) ? 0 : -in_x_origin;
                const int filter_x_end   = (filter_width < (input_width - in_x_origin)) ? filter_width : (input_width - in_x_origin);
                const int filter_y_start = (0 > -in_y_origin) ? 0 : -in_y_origin;
                const int filter_y_end   = (filter_height < (input_height - in_y_origin)) ? filter_height : (input_height - in_y_origin);
                
                int8_t max = -128;
                for (int filter_y = filter_y_start; filter_y < filter_y_end; ++filter_y) {
                    for (int filter_x = filter_x_start; filter_x < filter_x_end; ++filter_x) {
                        const int in_x = in_x_origin + filter_x;
                        const int in_y = in_y_origin + filter_y;

                        int8_t tmp = input_data[
                                channel * input_height * input_width + in_y * input_width + in_x
                            ];
                        max = (max > tmp) ? max : tmp;
                    }
                }

                output_data[
                    channel * output_height * output_width + out_y * output_width + out_x
                ] = max;
            }
        }
    }
}
