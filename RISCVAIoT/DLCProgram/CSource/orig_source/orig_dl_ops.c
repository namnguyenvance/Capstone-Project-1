#include "orig_dl_ops.h"

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

float ActivationFunctionWithMinMaxFloat(float var, float min, float max) {
    return (var < min) ? min : ((var > max) ? max : var);
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
// Fully ConnectedLayer
void FullyConnected2DFloat(
    const float* input_data  , const int* input_dims,
    const float* weights_data, const int* weights_dims, 
    const float* bias_data   , const int* bias_dims,
    float* output_data       , const int* output_dims,
    float output_activation_min, float output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [N]
          - filter_data will be a matrix with dimension [N x M]
          - output_data will be a matrix with dimension [M]
          - bias_data   will be a matrix with dimension [M]
        2. For simplify, the input_offset, filter_offest and ouput_offset may be zero
    */

    // Debug
    // assert(input_dims[0]  == weights_dims[0]);
    // assert(output_dims[0] == weights_dims[1]);
    // assert(bias_dims[0]   == output_dims[0]);

    // Setup var
    const int output_depth = output_dims[0];
    const int accum_depth  = input_dims[0];

    for (int out_c = 0; out_c < output_depth; ++out_c) {
        float total = 0.f;
        for (int d = 0; d < accum_depth; ++d) 
            total += input_data[d] * weights_data[out_c * accum_depth + d];

        float bias_value = 0.0f;
        if (bias_data) 
            bias_value = bias_data[out_c];

        output_data[out_c] = ActivationFunctionWithMinMaxFloat(
            total + bias_value, output_activation_min, output_activation_max);
    }
}

void FullyConnected2DInt(
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

            // if (d % 9 == 8) {
            //     printf("depth = %d,\t acc = %d\n", d, acc);
            // }
        }

        // if (bias_data) {
        //     acc += bias_data[out_c];
        // }

        // printf("out_c = %d, acc = %d\n", 
        //             out_c, acc);

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


// After debug, this function may be use

// void FullyConnected2DIntAlAccel(
//     const int8_t* input_data , const int* input_dims , int32_t input_offset, 
//     const int8_t* filter_data, const int* filter_dims, int32_t filter_offset,
//     const int32_t* bias_data  , const int* bias_dims,
//     int8_t* output_data      , const int* output_dims,
//     int32_t output_offset, int32_t output_multiplier, int8_t output_shift, 
//     int32_t output_activation_min, int32_t output_activation_max
// ) {
//     /* 
//         Note:
//         1. 
//           - input_data  will be a matrix with dimension [N]
//           - filter_data will be a matrix with dimension [N x M]
//           - output_data will be a matrix with dimension [M]
//           - bias_data   will be a matrix with dimension [M]
//         2. For simplify, the input_offset, filter_offest and ouput_offset may be zero
//     */

//     // Debug
//     // assert(input_dims[0]  == filter_dims[0]);
//     // assert(output_dims[0] == filter_dims[1]);
//     // assert(bias_dims[0]   == output_dims[0]);

//     // Setup var
//     const int output_depth = output_dims[0];
//     const int accum_depth  = input_dims[0];

//     /* Calculation part -- Explore this part */
//     // Create temporary value for output_data -- May be or may be not :))
//     for (int out_c = 0; out_c < output_depth; ++out_c) {
//         if (bias_data) 
//             al_accel_buf[out_c] = bias_data[out_c] + output_offset;
//         else
//             al_accel_buf[out_c] = output_offset;
//     }

//     // Main calculation
//     for (int in_c = 0; in_c < accum_depth; ++in_c) {
//         int32_t input_val = input_data[in_c];
//         for (int out_c = 0; out_c < output_depth; ++out_c) {
//             int32_t acc = 0;
            
//             // MAC operation
//             int32_t filter_val = filter_data[in_c * output_depth + out_c];
//             acc = (filter_val + filter_offset) * (input_val + input_offset);
//             al_accel_buf[out_c] += acc;
//         }
//     }

//     for (int out_c = 0; out_c < output_depth; ++out_c) {
//         // Quantization result
//         al_accel_buf[out_c] += 
//           MultiplyByQuantizedMultiplierSmallerThanOne(
//             al_accel_buf[out_c], output_multiplier, output_shift);
        
//         // Activation function
//         al_accel_buf[out_c] = ActivationFunctionWithMinMax(
//             al_accel_buf[out_c], output_activation_min, output_activation_max);
//         // output_data[out_c] = max(output_data[out_c], output_activation_min);
//         // output_data[out_c] = min(output_data[out_c], output_activation_max);

//         // Quantization
//         output_data[out_c] = (int8_t)(al_accel_buf[out_c]);
//     }
// }

// Reference function FullyConnected in Tensorflow

// inline void FullyConnected(const float* input_data, const Dims<4>& input_dims,
//                            const float* weights_data,
//                            const Dims<4>& weights_dims, const float* bias_data,
//                            const Dims<4>& bias_dims,
//                            float output_activation_min,
//                            float output_activation_max, float* output_data,
//                            const Dims<4>& output_dims) {
//   // TODO(benoitjacob): This really should be:
//   //     const int batches = ArraySize(output_dims, 1);
//   // but the current --variable_batch hack consists in overwriting the 3rd
//   // dimension with the runtime batch size, as we don't keep track for each
//   // array of which dimension is the batch dimension in it.
//   const int batches = ArraySize(output_dims, 1) * ArraySize(output_dims, 2) *
//                       ArraySize(output_dims, 3);
//   const int output_depth = MatchingArraySize(weights_dims, 1, output_dims, 0);
//   const int accum_depth = ArraySize(weights_dims, 0);
//   TFLITE_DCHECK(IsPackedWithoutStrides(input_dims));
//   TFLITE_DCHECK(IsPackedWithoutStrides(weights_dims));
//   for (int b = 0; b < batches; ++b) {
//     for (int out_c = 0; out_c < output_depth; ++out_c) {
//       float total = 0.f;
//       for (int d = 0; d < accum_depth; ++d) {
//         total += input_data[b * accum_depth + d] *
//                  weights_data[out_c * accum_depth + d];
//       }
//       float bias_value = 0.0f;
//       if (bias_data) {
//         bias_value = bias_data[Offset(bias_dims, out_c, 0, 0, 0)];
//       }
//       output_data[out_c + output_depth * b] = ActivationFunctionWithMinMax(
//           total + bias_value, output_activation_min, output_activation_max);
//     }
//   }
// }

// inline void FullyConnected(const uint8* input_data, const Dims<4>& input_dims,
//                            int32 input_offset, const uint8* filter_data,
//                            const Dims<4>& filter_dims, int32 filter_offset,
//                            const int32* bias_data, const Dims<4>& bias_dims,
//                            int32 output_offset, int32 output_multiplier,
//                            int output_shift, int32 output_activation_min,
//                            int32 output_activation_max, uint8* output_data,
//                            const Dims<4>& output_dims,
//                            gemmlowp::GemmContext* gemm_context) {
//   (void)gemm_context;  // only used in optimized code.
//   TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
//   // TODO(benoitjacob): This really should be:
//   //     const int batches = ArraySize(output_dims, 1);
//   // but the current --variable_batch hack consists in overwriting the 3rd
//   // dimension with the runtime batch size, as we don't keep track for each
//   // array of which dimension is the batch dimension in it.
//   const int batches = ArraySize(output_dims, 1) * ArraySize(output_dims, 2) *
//                       ArraySize(output_dims, 3);
//   const int output_depth = MatchingArraySize(filter_dims, 1, output_dims, 0);
//   const int accum_depth = ArraySize(filter_dims, 0);
//   TFLITE_DCHECK(IsPackedWithoutStrides(input_dims));
//   TFLITE_DCHECK(IsPackedWithoutStrides(filter_dims));
//   for (int b = 0; b < batches; ++b) {
//     for (int out_c = 0; out_c < output_depth; ++out_c) {
//       int32 acc = 0;
//       for (int d = 0; d < accum_depth; ++d) {
//         int32 input_val = input_data[b * accum_depth + d];
//         int32 filter_val = filter_data[out_c * accum_depth + d];
//         acc += (filter_val + filter_offset) * (input_val + input_offset);
//       }
//       if (bias_data) {
//         acc += bias_data[Offset(bias_dims, out_c, 0, 0, 0)];
//       }
//       acc = MultiplyByQuantizedMultiplierSmallerThanOne(acc, output_multiplier,
//                                                         output_shift);
//       acc += output_offset;
//       acc = std::max(acc, output_activation_min);
//       acc = std::min(acc, output_activation_max);
//       output_data[out_c + output_depth * b] = static_cast<uint8>(acc);
//     }
//   }
// }


// Convolution Layer
void Conv3DFloat(
    const float* input_data , const int* input_dims,
    const float* filter_data, const int* filter_dims,
    const float* bias_data  , const int* bias_dims,
    int stride_width, int stride_height, 
    int pad_width   , int pad_height, 
    float* output_data      , const int* output_dims,
    float output_activation_min, float output_activation_max
) {
    /* 
        Note:
        1. 
          - input_data  will be a matrix with dimension [Ifm0 x Ifm1 x Ifm2]
          - filter_data will be a matrix with dimension [Krn0 x Krn1 x Krn2 x Number of Kernel]
          - output_data will be a matrix with dimension [Ofm0 x Ofm1 x Ofm2]
          - bias_data   will be a matrix with dimension [Number of Kernel]
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

    // Calculation 
    for (int out_y = 0; out_y < output_height; ++out_y) {
        for (int out_x = 0; out_x < output_width; ++out_x) {
            for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
                const int in_x_origin = (out_x * stride_width ) - pad_width;
                const int in_y_origin = (out_y * stride_height) - pad_height;

                float total = 0.f;
                for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
                    for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
                        for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
                            const int in_x = in_x_origin + filter_x;
                            const int in_y = in_y_origin + filter_y;
                            // If the location is outside the bounds of the input image,
                            // use zero as a default value.
                            if ((in_x >= 0) && (in_x < input_width) 
                             && (in_y >= 0) && (in_y < input_height)) {
                                float input_value = input_data[
                                    in_channel * input_height * input_width + in_y * input_width + in_x];
                                float filter_value = filter_data[
                                    out_channel * filter_depth * filter_height * filter_width + 
                                        in_channel * filter_height * filter_width + 
                                            filter_y * filter_width + filter_x];

                                total += (input_value * filter_value);
                            }
                        }
                    }
                }
                    
                float bias_value = 0.0f;
                if (bias_data) {
                    bias_value = bias_data[out_channel];
                }

                output_data[out_channel * output_height * output_width + out_y * output_width + out_x] =
                    ActivationFunctionWithMinMaxFloat(total + bias_value,
                                                output_activation_min,
                                                output_activation_max);
            }
        }
    }
}

void Conv3DInt(
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
                                // printf("Add %d\n", (filter_val + filter_offset) * (input_val + input_offset));
                                acc += (filter_val + filter_offset) * (input_val + input_offset);
                            }
                        }
                    }
                    // if (in_channel % 3 == 2) {
                    //     printf("in_channel = %d,\t acc = %d\n", in_channel, acc);
                    // }
                }

                // if (bias_data) 
                //     acc += bias_data[out_channel];

                // printf("out_x = %d,\t out_y = %d,\t out_channel = %d,\t acc = %d\n", 
                //     out_x, out_y, out_channel, acc);

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

// Reference function Conv in Tensorflow

// inline void Conv(const float* input_data, const Dims<4>& input_dims,
//                  const float* filter_data, const Dims<4>& filter_dims,
//                  const float* bias_data, const Dims<4>& bias_dims,
//                  int stride_width, int stride_height, int pad_width,
//                  int pad_height, float output_activation_min,
//                  float output_activation_max, float* output_data,
//                  const Dims<4>& output_dims, float* im2col_data,
//                  const Dims<4>& im2col_dims) {
//   (void)im2col_data;  // only used in optimized code.
//   (void)im2col_dims;  // only used in optimized code.
//   const int batches = MatchingArraySize(input_dims, 3, output_dims, 3);
//   const int input_depth = MatchingArraySize(input_dims, 0, filter_dims, 0);
//   const int output_depth = MatchingArraySize(filter_dims, 3, output_dims, 0);
//   if (bias_data) {
//     TFLITE_DCHECK_EQ(ArraySize(filter_dims, 3), ArraySize(bias_dims, 0));
//   }
//   const int input_height = ArraySize(input_dims, 2);
//   const int input_width = ArraySize(input_dims, 1);
//   const int filter_height = ArraySize(filter_dims, 2);
//   const int filter_width = ArraySize(filter_dims, 1);
//   const int output_height = ArraySize(output_dims, 2);
//   const int output_width = ArraySize(output_dims, 1);
//   for (int batch = 0; batch < batches; ++batch) {
//     for (int out_y = 0; out_y < output_height; ++out_y) {
//       for (int out_x = 0; out_x < output_width; ++out_x) {
//         for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
//           const int in_x_origin = (out_x * stride_width) - pad_width;
//           const int in_y_origin = (out_y * stride_height) - pad_height;
//           float total = 0.f;
//           for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
//             for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
//               for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
//                 const int in_x = in_x_origin + filter_x;
//                 const int in_y = in_y_origin + filter_y;
//                 // If the location is outside the bounds of the input image,
//                 // use zero as a default value.
//                 if ((in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
//                     (in_y < input_height)) {
//                   float input_value = input_data[Offset(input_dims, in_channel,
//                                                         in_x, in_y, batch)];
//                   float filter_value =
//                       filter_data[Offset(filter_dims, in_channel, filter_x,
//                                          filter_y, out_channel)];
//                   total += (input_value * filter_value);
//                 }
//               }
//             }
//           }
//           float bias_value = 0.0f;
//           if (bias_data) {
//             bias_value = bias_data[Offset(bias_dims, out_channel, 0, 0, 0)];
//           }
//           output_data[Offset(output_dims, out_channel, out_x, out_y, batch)] =
//               ActivationFunctionWithMinMax(total + bias_value,
//                                            output_activation_min,
//                                            output_activation_max);
//         }
//       }
//     }
//   }
// }

// inline void Conv(const uint8* input_data, const Dims<4>& input_dims,
//                  int32 input_offset, const uint8* filter_data,
//                  const Dims<4>& filter_dims, int32 filter_offset,
//                  const int32* bias_data, const Dims<4>& bias_dims,
//                  int stride_width, int stride_height, int pad_width,
//                  int pad_height, int32 output_offset, int32 output_multiplier,
//                  int output_shift, int32 output_activation_min,
//                  int32 output_activation_max, uint8* output_data,
//                  const Dims<4>& output_dims, uint8* im2col_data,
//                  const Dims<4>& im2col_dims,
//                  gemmlowp::GemmContext* gemm_context) {
//   (void)im2col_data;   // only used in optimized code.
//   (void)im2col_dims;   // only used in optimized code.
//   (void)gemm_context;  // only used in optimized code.
//   TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
//   const int batches = MatchingArraySize(input_dims, 3, output_dims, 3);
//   const int input_depth = MatchingArraySize(input_dims, 0, filter_dims, 0);
//   const int output_depth =
//       MatchingArraySize(filter_dims, 3, bias_dims, 0, output_dims, 0);
//   const int input_height = ArraySize(input_dims, 2);
//   const int input_width = ArraySize(input_dims, 1);
//   const int filter_height = ArraySize(filter_dims, 2);
//   const int filter_width = ArraySize(filter_dims, 1);
//   const int output_height = ArraySize(output_dims, 2);
//   const int output_width = ArraySize(output_dims, 1);
//   for (int batch = 0; batch < batches; ++batch) {
//     for (int out_y = 0; out_y < output_height; ++out_y) {
//       for (int out_x = 0; out_x < output_width; ++out_x) {
//         for (int out_channel = 0; out_channel < output_depth; ++out_channel) {
//           const int in_x_origin = (out_x * stride_width) - pad_width;
//           const int in_y_origin = (out_y * stride_height) - pad_height;
//           int32 acc = 0;
//           for (int filter_y = 0; filter_y < filter_height; ++filter_y) {
//             for (int filter_x = 0; filter_x < filter_width; ++filter_x) {
//               for (int in_channel = 0; in_channel < input_depth; ++in_channel) {
//                 const int in_x = in_x_origin + filter_x;
//                 const int in_y = in_y_origin + filter_y;
//                 // If the location is outside the bounds of the input image,
//                 // use zero as a default value.
//                 if ((in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
//                     (in_y < input_height)) {
//                   int32 input_val = input_data[Offset(input_dims, in_channel,
//                                                       in_x, in_y, batch)];
//                   int32 filter_val =
//                       filter_data[Offset(filter_dims, in_channel, filter_x,
//                                          filter_y, out_channel)];
//                   acc +=
//                       (filter_val + filter_offset) * (input_val + input_offset);
//                 }
//               }
//             }
//           }
//           if (bias_data) {
//             acc += bias_data[Offset(bias_dims, out_channel, 0, 0, 0)];
//           }
//           acc = MultiplyByQuantizedMultiplierSmallerThanOne(
//               acc, output_multiplier, output_shift);
//           acc += output_offset;
//           acc = std::max(acc, output_activation_min);
//           acc = std::min(acc, output_activation_max);
//           output_data[Offset(output_dims, out_channel, out_x, out_y, batch)] =
//               static_cast<uint8>(acc);
//         }
//       }
//     }
//   }
// }

// Pooling Layer

void MaxPoolFloat(
    const float* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int pad_width   , int pad_height, 
    int filter_width, int filter_height,
    float output_activation_min, float output_activation_max,
    float* output_data     , const int* output_dims
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
                float max = -999999999.0f;
                for (int filter_y = filter_y_start; filter_y < filter_y_end; ++filter_y) {
                    for (int filter_x = filter_x_start; filter_x < filter_x_end; ++filter_x) {
                        const int in_x = in_x_origin + filter_x;
                        const int in_y = in_y_origin + filter_y;

                        float tmp = input_data[
                            channel * input_height * input_width + in_y * input_width + in_x
                        ];
                        max = (max > tmp) ? max : tmp; 
                    }
                }

                // output_data[
                //     channel * output_height * output_width + out_y * output_width + out_x
                // ] = ActivationFunctionWithMinMaxFloat(max, output_activation_min, output_activation_max);

                output_data[
                    channel * output_height * output_width + out_y * output_width + out_x
                ] = max;
            }
        }
    }
}

void MaxPoolInt(
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

// Reference function MaxPool in Tensorflow

// inline void MaxPool(const float* input_data, const Dims<4>& input_dims,
//                     int stride_width, int stride_height, int pad_width,
//                     int pad_height, int filter_width, int filter_height,
//                     float output_activation_min, float output_activation_max,
//                     float* output_data, const Dims<4>& output_dims) {
//   const int batches = MatchingArraySize(input_dims, 3, output_dims, 3);
//   const int depth = MatchingArraySize(input_dims, 0, output_dims, 0);
//   const int input_height = ArraySize(input_dims, 2);
//   const int input_width = ArraySize(input_dims, 1);
//   const int output_height = ArraySize(output_dims, 2);
//   const int output_width = ArraySize(output_dims, 1);
//   for (int batch = 0; batch < batches; ++batch) {
//     for (int out_y = 0; out_y < output_height; ++out_y) {
//       for (int out_x = 0; out_x < output_width; ++out_x) {
//         for (int channel = 0; channel < depth; ++channel) {
//           const int in_x_origin = (out_x * stride_width) - pad_width;
//           const int in_y_origin = (out_y * stride_height) - pad_height;
//           // Compute the boundaries of the filter region clamped so as to
//           // ensure that the filter window fits in the input array.
//           const int filter_x_start = std::max(0, -in_x_origin);
//           const int filter_x_end =
//               std::min(filter_width, input_width - in_x_origin);
//           const int filter_y_start = std::max(0, -in_y_origin);
//           const int filter_y_end =
//               std::min(filter_height, input_height - in_y_origin);
//           float max = std::numeric_limits<float>::lowest();
//           for (int filter_y = filter_y_start; filter_y < filter_y_end;
//                ++filter_y) {
//             for (int filter_x = filter_x_start; filter_x < filter_x_end;
//                  ++filter_x) {
//               const int in_x = in_x_origin + filter_x;
//               const int in_y = in_y_origin + filter_y;
//               max = std::max(
//                   max,
//                   input_data[Offset(input_dims, channel, in_x, in_y, batch)]);
//             }
//           }
//           output_data[Offset(output_dims, channel, out_x, out_y, batch)] =
//               ActivationFunctionWithMinMax(max, output_activation_min,
//                                            output_activation_max);
//         }
//       }
//     }
//   }
// }

// inline void MaxPool(const uint8* input_data, const Dims<4>& input_dims,
//                     int stride_width, int stride_height, int pad_width,
//                     int pad_height, int filter_width, int filter_height,
//                     int32 output_activation_min, int32 output_activation_max,
//                     uint8* output_data, const Dims<4>& output_dims) {
//   TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
//   TFLITE_DCHECK_GE(output_activation_min, 0);
//   TFLITE_DCHECK_LE(output_activation_max, 255);
//   const int batches = MatchingArraySize(input_dims, 3, output_dims, 3);
//   const int depth = MatchingArraySize(input_dims, 0, output_dims, 0);
//   const int input_height = ArraySize(input_dims, 2);
//   const int input_width = ArraySize(input_dims, 1);
//   const int output_height = ArraySize(output_dims, 2);
//   const int output_width = ArraySize(output_dims, 1);
//   for (int batch = 0; batch < batches; ++batch) {
//     for (int out_y = 0; out_y < output_height; ++out_y) {
//       for (int out_x = 0; out_x < output_width; ++out_x) {
//         for (int channel = 0; channel < depth; ++channel) {
//           const int in_x_origin = (out_x * stride_width) - pad_width;
//           const int in_y_origin = (out_y * stride_height) - pad_height;
//           // Compute the boundaries of the filter region clamped so as to
//           // ensure that the filter window fits in the input array.
//           const int filter_x_start = std::max(0, -in_x_origin);
//           const int filter_x_end =
//               std::min(filter_width, input_width - in_x_origin);
//           const int filter_y_start = std::max(0, -in_y_origin);
//           const int filter_y_end =
//               std::min(filter_height, input_height - in_y_origin);
//           uint8 max = 0;
//           for (int filter_y = filter_y_start; filter_y < filter_y_end;
//                ++filter_y) {
//             for (int filter_x = filter_x_start; filter_x < filter_x_end;
//                  ++filter_x) {
//               const int in_x = in_x_origin + filter_x;
//               const int in_y = in_y_origin + filter_y;
//               max = std::max(
//                   max,
//                   input_data[Offset(input_dims, channel, in_x, in_y, batch)]);
//             }
//           }
//           max = std::max<uint8>(max, output_activation_min);
//           max = std::min<uint8>(max, output_activation_max);
//           output_data[Offset(output_dims, channel, out_x, out_y, batch)] =
//               static_cast<uint8>(max);
//         }
//       }
//     }
//   }
// }
