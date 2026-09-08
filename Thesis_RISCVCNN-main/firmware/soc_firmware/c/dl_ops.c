#include "dl_ops.h"

// extern uint32_t* al_accel_buf;

/* Ulti function */
int32_t ActivationFunctionWithMinMaxInt(int32_t var, int32_t min, int32_t max) {
    if (var < min)
        return min;
    else if (var > max) 
        return max;
    else 
        return var;
    // return (var < min) ? min : ((var > max) ? max : var);
}


/* Support function */
int32_t MultiplyByQuantizedMultiplierSmallerThanOne(
    int32_t x, 
    int32_t quantized_multiplier, 
    uint8_t right_shift 
) {
    return RoundingDivideByPOT(
        SaturatingRoundingDoublingHighMul(x, quantized_multiplier), 
        right_shift
    );
}


/* Feature function */
// Normal Version

// Fully ConnectedLayer
void FullyConnected2D_NormalVer(
    const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims, int32_t filter_offset,
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims,
    int32_t output_offset, int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    // Debug
    // assert(input_dims[0]  == filter_dims[0]);
    // assert(output_dims[0] == filter_dims[1]);
    // assert(bias_dims[0]   == output_dims[0]);

    // Setup var
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
            acc += (filter_val + filter_offset) * (input_val + input_offset);
        }

        acc = MultiplyByQuantizedMultiplierSmallerThanOne(acc, output_multiplier,
                                                            output_shift);

        // acc = ActivationFunctionWithMinMaxInt(
        //     acc + output_offset, output_activation_min, output_activation_max);

        acc = acc + output_offset;

        // acc += output_offset;
        // acc = max(acc, output_activation_min);
        // acc = min(acc, output_activation_max);
        output_data[out_c] = (int8_t)(acc);
    }
}

// Convolution Layer

void Conv2D_NormalVer(
    const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims, int32_t filter_offset,
    const int32_t* bias_data , const int* bias_dims, 
    int stride_width, int stride_height, 
    int pad_width   , int pad_height, 
    int8_t* output_data      , const int* output_dims,
    int32_t output_offset, int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - filter_data will be a matrix with dimension [Krn0 x Krn1 x Krn2 x Number of Kernel]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
          - bias_data   will be a matrix with dimension [Number of Kernel]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // Debug
    // assert(input_dims[2] == filter_dims[2]);
    // assert(ouput_dims[2] == filter_dims[3]);
    // assert(bias_dims[0]  == filter_dims[3]);
    // assert((input_dims[0] - filter_dims[0]) % stride_width == 0);
    // assert((ouput_dims[0] - 2 * pad_width - 1) == ((input_dims[0] - filter_dims[0])/stride_width) == 0);
    // assert((input_dims[1] - filter_dims[1]) % stride_height == 0);
    // assert((ouput_dims[1] - 2 * pad_height - 1) == ((input_dims[1] - filter_dims[1])/stride_height) == 0);

    // Setup var
    const int input_depth   = input_dims[2];
    const int output_depth  = output_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int filter_height = filter_dims[1];
    const int filter_width  = filter_dims[0];
    const int filter_depth  = filter_dims[2];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    /* Calculation part -- Explore this part */
    // Create temporary value for output_data

    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                const int in_x_origin = (out_x * stride_width) - pad_width;
                const int in_y_origin = (out_y * stride_height) - pad_height;

                int32_t acc = 0;

                if (bias_data) 
                    acc += bias_data[out_channel];
                // for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                //     for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                //         for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                    for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                        for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                            const int in_x = in_x_origin + filter_x;
                            const int in_y = in_y_origin + filter_y;

                            // If the location is outside the bounds of the input image,
                            // use zero as a default value.
                            if ((in_x >= 0) && (in_x < input_width) 
                             && (in_y >= 0) && (in_y < input_height)) {
                                int32_t input_val = input_data[
                                    in_channel * input_height * input_width + in_y * input_width + in_x];
                                int32_t filter_val = filter_data[
                                    out_channel * filter_depth * filter_height * filter_width + 
                                        in_channel * filter_height * filter_width + 
                                            filter_y * filter_width + filter_x];

                                acc += (filter_val + filter_offset) * (input_val + input_offset);
                            }
                        }
                    }
                }

                // if (bias_data) 
                //     acc += bias_data[out_channel];

                acc = MultiplyByQuantizedMultiplierSmallerThanOne(
                    acc, output_multiplier, output_shift);

                // acc = ActivationFunctionWithMinMaxInt(
                //     acc + output_offset, output_activation_min, output_activation_max);

                acc = acc + output_offset;

                // acc += output_offset;
                // acc = max(acc, output_activation_min);
                // acc = min(acc, output_activation_max);
                output_data[out_channel * output_height * output_width + out_y * output_width + out_x] = (int8_t)(acc);
            }
        }
    }
}

// Pooling Layer

void MaxPool_NormalVer(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int pad_width, int pad_height, 
    int filter_width, int filter_height,
    int32_t output_activation_min, int32_t output_activation_max,
    int8_t* output_data     , const int* output_dims
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // assert(input_dims[2] == output_dims[2]);

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

                // Compute the boundaries of the filter region clamped so as to
                // ensure that the filter window fits in the input array.
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

                // max = std::max<uint8>(max, output_activation_min);
                // max = std::min<uint8>(max, output_activation_max);
                // output_data[Offset(output_dims, channel, out_x, out_y, batch)] =
                    // static_cast<uint8>(max);
            }
        }
    }
}

// Compact Version

// Fully-Connected Layer
void FullyConnected2D_CompactVer(
    const int8_t* input_data , const int* input_dims , 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims,
    int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    // Debug
    // assert(input_dims[0]  == filter_dims[0]);
    // assert(output_dims[0] == filter_dims[1]);
    // assert(bias_dims[0]   == output_dims[0]);

    // Setup var
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
            acc += filter_val * input_val;
        }

        acc = MultiplyByQuantizedMultiplierSmallerThanOne(acc, output_multiplier,
                                                            output_shift);

        // acc = ActivationFunctionWithMinMaxInt(
        //     acc + output_offset, output_activation_min, output_activation_max);

        // acc += output_offset;
        // acc = max(acc, output_activation_min);
        // acc = min(acc, output_activation_max);
        output_data[out_c] = (int8_t)(acc);
    }
}

// Convolution Layer
void Conv2D_CompactVer(
    const int8_t* input_data , const int* input_dims , 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims, 
    int stride_width, int stride_height, 
    int8_t* output_data      , const int* output_dims,
    int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - filter_data will be a matrix with dimension [Krn0 x Krn1 x Krn2 x Number of Kernel]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
          - bias_data   will be a matrix with dimension [Number of Kernel]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // Debug
    // assert(input_dims[2] == filter_dims[2]);
    // assert(ouput_dims[2] == filter_dims[3]);
    // assert(bias_dims[0]  == filter_dims[3]);
    // assert((input_dims[0] - filter_dims[0]) % stride_width == 0);
    // assert((ouput_dims[0] - 2 * pad_width - 1) == ((input_dims[0] - filter_dims[0])/stride_width) == 0);
    // assert((input_dims[1] - filter_dims[1]) % stride_height == 0);
    // assert((ouput_dims[1] - 2 * pad_height - 1) == ((input_dims[1] - filter_dims[1])/stride_height) == 0);

    // Setup var
    const int input_depth   = input_dims[2];
    const int output_depth  = output_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int filter_height = filter_dims[1];
    const int filter_width  = filter_dims[0];
    const int filter_depth  = filter_dims[2];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    /* Calculation part -- Explore this part */
    // Create temporary value for output_data

    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                const int in_x_origin = (out_x * stride_width);
                const int in_y_origin = (out_y * stride_height);

                int32_t acc = 0;

                if (bias_data) 
                    acc += bias_data[out_channel];
                // for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                //     for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                //         for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                    for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                        for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                            const int in_x = in_x_origin + filter_x;
                            const int in_y = in_y_origin + filter_y;

                            // If the location is outside the bounds of the input image,
                            // use zero as a default value.
                            if ((in_x >= 0) && (in_x < input_width) 
                             && (in_y >= 0) && (in_y < input_height)) {
                                int32_t input_val = input_data[
                                    in_channel * input_height * input_width + in_y * input_width + in_x];
                                int32_t filter_val = filter_data[
                                    out_channel * filter_depth * filter_height * filter_width + 
                                        in_channel * filter_height * filter_width + 
                                            filter_y * filter_width + filter_x];

                                acc += filter_val * input_val;
                            }
                        }
                    }
                }

                // if (bias_data) 
                //     acc += bias_data[out_channel];

                acc = MultiplyByQuantizedMultiplierSmallerThanOne(
                    acc, output_multiplier, output_shift);

                // acc = ActivationFunctionWithMinMaxInt(
                //     acc + output_offset, output_activation_min, output_activation_max);

                // acc += output_offset;
                // acc = max(acc, output_activation_min);
                // acc = min(acc, output_activation_max);
                output_data[out_channel * output_height * output_width + out_y * output_width + out_x] = (int8_t)(acc);
            }
        }
    }
}

// Pooling Layer
void MaxPool_CompactVer(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // assert(input_dims[2] == output_dims[2]);

    const int depth         = input_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int channel = 0; channel < depth; ++channel) {
                const int in_x_origin = (out_x * stride_width);
                const int in_y_origin = (out_y * stride_height);

                // Compute the boundaries of the filter region clamped so as to
                // ensure that the filter window fits in the input array.
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

                // max = std::max<uint8>(max, output_activation_min);
                // max = std::min<uint8>(max, output_activation_max);
                // output_data[Offset(output_dims, channel, out_x, out_y, batch)] =
                    // static_cast<uint8>(max);
            }
        }
    }
}

// TFLM Version

// Fully-Connected Layer
void FullyConnected2D_TFLM(
    const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims, 
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
) {
    // Debug
    // assert(input_dims[0]  == filter_dims[0]);
    // assert(output_dims[0] == filter_dims[1]);
    // assert(bias_dims[0]   == output_dims[0]);

    // Setup var
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

            // if (d % 9 == 8) {
            //     printf("depth = %d,\t acc = %d\n", d, acc);
            // }
        }

        // printf("out_c = %d, acc = %d\n", 
        //             out_c, acc);
        
        acc = MultiplyByQuantizedMultiplierSmallerThanOne(
            acc, output_multiplier, output_shift);

        acc = (acc < output_activation_min) ? output_activation_min : acc;
        acc = (acc > output_activation_max) ? output_activation_max : acc;

        acc = acc - output_offset;
        output_data[out_c] = (int8_t)(acc);
    }
}

// Convolution Layer
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
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - filter_data will be a matrix with dimension [Krn0 x Krn1 x Krn2 x Number of Kernel]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
          - bias_data   will be a matrix with dimension [Number of Kernel]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // Debug
    // assert(input_dims[2] == filter_dims[2]);
    // assert(ouput_dims[2] == filter_dims[3]);
    // assert(bias_dims[0]  == filter_dims[3]);
    // assert((input_dims[0] - filter_dims[0]) % stride_width == 0);
    // assert((ouput_dims[0] - 2 * pad_width - 1) == ((input_dims[0] - filter_dims[0])/stride_width) == 0);
    // assert((input_dims[1] - filter_dims[1]) % stride_height == 0);
    // assert((ouput_dims[1] - 2 * pad_height - 1) == ((input_dims[1] - filter_dims[1])/stride_height) == 0);

    // Setup var
    const int input_depth   = input_dims[2];
    const int output_depth  = output_dims[2];
    const int input_height  = input_dims[1];
    const int input_width   = input_dims[0];
    const int filter_height = filter_dims[1];
    const int filter_width  = filter_dims[0];
    const int filter_depth  = filter_dims[2];
    const int output_height = output_dims[1];
    const int output_width  = output_dims[0];

    /* Calculation part -- Explore this part */
    // Create temporary value for output_data

    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                const int in_x_origin = (out_x * stride_width) - pad_width;
                const int in_y_origin = (out_y * stride_height) - pad_height;

                int32_t acc = 0;

                if (bias_data) 
                    acc += bias_data[out_channel];

                // for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                //     for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                //         for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                    for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                        for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                            const int in_x = in_x_origin + filter_x;
                            const int in_y = in_y_origin + filter_y;

                            // If the location is outside the bounds of the input image,
                            // use zero as a default value.
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
                    // if (in_channel % 3 == 2) {
                    //     printf("in_channel = %d,\t acc = %d\n", in_channel, acc);
                    // }
                }

                // printf("out_x = %d,\t out_y = %d,\t out_channel = %d,\t acc = %d\n", 
                //     out_x, out_y, out_channel, acc);
                // printf("Before quant = %d; \n", acc);

                
                acc = MultiplyByQuantizedMultiplierSmallerThanOne(
                    acc, output_multiplier[out_channel], output_shift[out_channel]);

                // printf("Expect quant = %lf; ", acc);
                // printf("After quant = %d\n", acc);

                // acc = ActivationFunctionWithMinMaxInt(
                //     acc + output_offset, output_activation_min, output_activation_max);
                acc = (acc < output_activation_min) ? output_activation_min : acc;
                acc = (acc > output_activation_max) ? output_activation_max : acc;

                acc = acc - output_offset;

                output_data[out_channel * output_height * output_width + out_y * output_width + out_x] = (int8_t)(acc);
            }
        }
    }
}

// Pooling Layer
void MaxPool_TFLM(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int pad_width, int pad_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims,
    int32_t output_activation_min, int32_t output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
        2. For simplify, the input_offset and filter_offest will be zero
    */

    // assert(input_dims[2] == output_dims[2]);

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

                // Compute the boundaries of the filter region clamped so as to
                // ensure that the filter window fits in the input array.
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

                // max = std::max<uint8>(max, output_activation_min);
                // max = std::min<uint8>(max, output_activation_max);
                // output_data[Offset(output_dims, channel, out_x, out_y, batch)] =
                    // static_cast<uint8>(max);
            }
        }
    }
}
