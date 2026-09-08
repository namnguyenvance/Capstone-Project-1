#ifndef DL_OPS_H
#define DL_OPS_H

#include <stdint.h>
#include <stdbool.h>
#include "quantize.h"

/* Quantized multiply via hardware accelerator */
int32_t MultiplyByQuantizedMultiplierSmallerThanOne(
    int32_t x, 
    int32_t quantized_multiplier, 
    uint8_t right_shift 
);

/* Standard 2D Convolution (used for initial conv layer) */
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
);

/*
 * Depthwise Separable 2D Convolution — CORE MOBILENET OPERATION
 * 
 * Key difference from standard Conv2D:
 *   Standard Conv2D:  Each output channel combines ALL input channels
 *   DepthwiseConv2D:  Each output channel convolves with ONLY 1 input channel
 *   => Reduces computation from O(K²·Cin·Cout) to O(K²·Cin)
 *
 * depth_multiplier: typically 1 (output_depth = input_depth * depth_multiplier)
 */
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
);

/*
 * Global Average Pooling — replaces Flatten + large FC
 * 
 * Averages all spatial positions for each channel:
 *   Input:  H x W x C  →  Output: 1 x 1 x C
 *   e.g., 8x8x64 → 64 values (instead of flatten to 4096!)
 */
void GlobalAveragePool_TFLM(
    const int8_t* input_data, const int* input_dims,
    int8_t* output_data,
    int32_t input_offset, int32_t output_offset,
    int32_t output_multiplier, int8_t output_shift,
    int32_t output_activation_min, int32_t output_activation_max
);

/* Fully Connected (Dense) layer */
void FullyConnected2D_TFLM(
    const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims, 
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
);

#endif
