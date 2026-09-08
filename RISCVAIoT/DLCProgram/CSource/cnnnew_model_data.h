#ifndef CNNNEW_MODEL_DATA_H
#define CNNNEW_MODEL_DATA_H

#include <stdint.h>

#ifdef CNNNEW_RUN
    /* Quantize Operators */
    // First CONV Layer
    extern const int32_t   cnnnew_conv0_output_multiplier[];
    extern const int8_t    cnnnew_conv0_output_shift[];
    // Second CONV Layer
    extern const int32_t   cnnnew_conv1_output_multiplier[];
    extern const int8_t    cnnnew_conv1_output_shift[];
    // // First DENSE Layer
    extern const int32_t   cnnnew_dense0_output_multiplier;
    extern const int8_t    cnnnew_dense0_output_shift;
    /*******************/

    /* Model Operators */
    // First CONV Layer
    extern const int cnnnew_conv0_kernel_dims[];
    extern const int8_t cnnnew_conv0_kernel_data[];
    extern const int cnnnew_conv0_bias_dims[];
    extern const int32_t cnnnew_conv0_bias_data[];
    // // Second CONV Layer
    extern const int cnnnew_conv1_kernel_dims[];
    extern const int8_t cnnnew_conv1_kernel_data[];
    extern const int cnnnew_conv1_bias_dims[];
    extern const int32_t cnnnew_conv1_bias_data[];
    // First DENSE Layer
    extern const int cnnnew_dense0_weight_dims[];
    extern const int8_t cnnnew_dense0_weight_data[];
    extern const int cnnnew_dense0_bias_dims[];
    extern const int32_t cnnnew_dense0_bias_data[];
    /*******************/
#endif

#endif