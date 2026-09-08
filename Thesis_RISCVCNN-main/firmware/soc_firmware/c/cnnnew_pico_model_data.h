#ifndef CNNNEW_PICO_MODEL_DATA_H
#define CNNNEW_PICO_MODEL_DATA_H

#include <stdint.h>

#if defined(CNNNEW_TEST) || defined(CNNNEW_RUN)
    /* Internal Storage */
    extern const int   cnnnew_conv0_output_dims[];
    extern int8_t      cnnnew_conv0_output_data[];
        
    extern const int   cnnnew_pool0_output_dims[];
    extern int8_t      cnnnew_pool0_output_data[];

    extern const int   cnnnew_conv1_output_dims[];
    extern int8_t      cnnnew_conv1_output_data[];

    extern const int   cnnnew_pool1_output_dims[];
    extern int8_t      cnnnew_pool1_output_data[];

    extern const int   cnnnew_dense0_input_dims[];

    extern const int   cnnnew_dense0_output_dims[];
    extern int8_t      cnnnew_dense0_output_data[];

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