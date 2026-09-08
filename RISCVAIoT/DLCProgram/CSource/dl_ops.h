#ifndef DL_OPS_H
#define DL_OPS_H

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include "quantize.h"

int32_t MultiplyByQuantizedMultiplierSmallerThanOne(
    int32_t x, 
    int32_t quantized_multiplier, 
    uint8_t right_shift 
);

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

void FullyConnected2D_TFLM(
    const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims, 
    const int32_t* bias_data , const int* bias_dims,
    int8_t* output_data      , const int* output_dims,
    int32_t output_offset, int32_t output_multiplier, int8_t output_shift, 
    int32_t output_activation_min, int32_t output_activation_max
);

void MaxPool_TFLM(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int pad_width, int pad_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims,
    int32_t output_activation_min, int32_t output_activation_max
);

#endif