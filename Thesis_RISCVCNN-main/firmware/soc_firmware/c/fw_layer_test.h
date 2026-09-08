#ifndef FW_LAYER_TEST_H
#define FW_LAYER_TEST_H

#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

#include "pico_std.h"
#include "dl_ops.h"
#include "fw_utils.h"

// Normal Version
void testFullyConnected2D_NoAccel(
    const int8_t* input_data , const int* input_dims , int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift,
    int8_t act_funct_type
);

void testConv2D_NoAccel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int8_t act_funct_type
);

void testMaxPool_NoAccel(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims
);

void testMixed2D_NoAccel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height,
    int8_t* output_conv_data , const int* output_conv_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int8_t act_funct_type
);
// Accel Version
void testFullyConnected2D_Accel(
    const int8_t* input_data , const int* input_dims , int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
);

void testConv2D_Accel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
);

void testMaxPool_Accel(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims
);

void testMixed2D_Accel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height,
    const int* output_conv_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
);

#endif