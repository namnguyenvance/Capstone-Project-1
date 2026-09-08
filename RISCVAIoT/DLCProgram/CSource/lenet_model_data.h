#ifndef LENET_MODEL_DATA_H
#define LENET_MODEL_DATA_H

#include <stdint.h>

#ifdef LENET_RUN
    /* Quantize Operators */
    // First CONV Layer
    extern const int32_t   lenet_conv0_output_multiplier[];
    extern const int8_t    lenet_conv0_output_shift[];
    // Second CONV Layer
    extern const int32_t   lenet_conv1_output_multiplier[];
    extern const int8_t    lenet_conv1_output_shift[];
    // First DENSE Layer
    extern const int32_t   lenet_dense0_output_multiplier;
    extern const int8_t    lenet_dense0_output_shift;
    // Second DENSE Layer
    extern const int32_t   lenet_dense1_output_multiplier;
    extern const int8_t    lenet_dense1_output_shift;
    // Third DENSE Layer
    extern const int32_t   lenet_dense2_output_multiplier;
    extern const int8_t    lenet_dense2_output_shift;
    /*******************/

    /* Model Operators */
    // First CONV Layer
    extern const int lenet_conv0_kernel_dims[];
    extern const int8_t lenet_conv0_kernel_data[];
    extern const int lenet_conv0_bias_dims[];
    extern const int32_t lenet_conv0_bias_data[];
    // Second CONV Layer
    extern const int lenet_conv1_kernel_dims[];
    extern const int8_t lenet_conv1_kernel_data[];
    extern const int lenet_conv1_bias_dims[];
    extern const int32_t lenet_conv1_bias_data[];
    // First DENSE Layer
    extern const int lenet_dense0_weight_dims[];
    extern const int8_t lenet_dense0_weight_data[];
    extern const int lenet_dense0_bias_dims[];
    extern const int32_t lenet_dense0_bias_data[];
    // Second DENSE Layer
    extern const int lenet_dense1_weight_dims[];
    extern const int8_t lenet_dense1_weight_data[];
    extern const int lenet_dense1_bias_dims[];
    extern const int32_t lenet_dense1_bias_data[];
    // Third DENSE Layer
    extern const int lenet_dense2_weight_dims[];
    extern const int8_t lenet_dense2_weight_data[];
    extern const int lenet_dense2_bias_dims[];
    extern const int32_t lenet_dense2_bias_data[];
    /*******************/
#endif

#endif