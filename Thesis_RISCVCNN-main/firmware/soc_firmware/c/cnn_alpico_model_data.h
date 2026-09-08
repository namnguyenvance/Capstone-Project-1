#ifndef CNN_AL_PICO_MODEL_DATA_H
#define CNN_AL_PICO_MODEL_DATA_H

#include <stdint.h>

#if defined(CNN_TEST) || defined(CNN_RUN)
    /* Partial-Sum Storage */
    extern int32_t cnn_conv0_ps_data[];
    extern int32_t cnn_conv1_ps_data[];
    extern int32_t cnn_dense0_ps_data[];
    extern int32_t cnn_dense1_ps_data[];

    /* Internal Storage */
    extern const int   cnn_conv0_output_dims[];
    extern int8_t      cnn_conv0_output_data[];
        
    extern const int   cnn_pool0_output_dims[];
    extern int8_t      cnn_pool0_output_data[];

    extern const int   cnn_conv1_output_dims[];
    extern int8_t      cnn_conv1_output_data[];

    extern const int   cnn_pool1_output_dims[];
    extern int8_t      cnn_pool1_output_data[];

    extern const int   cnn_dense0_input_dims[];

    extern const int   cnn_dense0_output_dims[];
    extern int8_t      cnn_dense0_output_data[];

    extern const int   cnn_dense1_output_dims[];
    extern int8_t      cnn_dense1_output_data[];

    /* Quantize Operators */
    // First CONV Layer
    extern const int32_t   cnn_conv0_output_multiplier[];
    extern const int8_t    cnn_conv0_output_shift[];
    // Second CONV Layer
    extern const int32_t   cnn_conv1_output_multiplier[];
    extern const int8_t    cnn_conv1_output_shift[];
    // // First DENSE Layer
    extern const int32_t   cnn_dense0_output_multiplier;
    extern const int8_t    cnn_dense0_output_shift;
    // Second DENSE Layer
    extern const int32_t   cnn_dense1_output_multiplier;
    extern const int8_t    cnn_dense1_output_shift;
    /*******************/

    /* Model Operators */
    // First CONV Layer
    extern const int cnn_conv0_kernel_dims[];
    extern const int8_t cnn_conv0_kernel_data[];
    extern const int cnn_conv0_bias_dims[];
    extern const int32_t cnn_conv0_bias_data[];
    // // Second CONV Layer
    extern const int cnn_conv1_kernel_dims[];
    extern const int8_t cnn_conv1_kernel_data[];
    extern const int cnn_conv1_bias_dims[];
    extern const int32_t cnn_conv1_bias_data[];
    // First DENSE Layer
    extern const int cnn_dense0_weight_dims[];
    extern const int8_t cnn_dense0_weight_data[];
    extern const int cnn_dense0_bias_dims[];
    extern const int32_t cnn_dense0_bias_data[];
    // Second DENSE Layer
    extern const int cnn_dense1_weight_dims[];
    extern const int8_t cnn_dense1_weight_data[];
    extern const int cnn_dense1_bias_dims[];
    extern const int32_t cnn_dense1_bias_data[];
    /*******************/
#endif

#endif