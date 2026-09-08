#ifndef FW_DATA_H
#define FW_DATA_H

#include <stdint.h>

/* Convolutional Layer */
#ifdef CL_TEST
    extern int32_t  input_offset;
    extern int32_t  output_offset;

    extern int32_t  output_multiplier[];
    extern int8_t   output_shift[];

    extern int input_dims [];
    extern int filter_dims[];
    extern int bias_dims  [];
    extern int stride_width;
    extern int stride_height;
    extern int output_dims[];

    extern int8_t input_data [];
    extern int8_t filter_data[];
    extern int32_t bias_data [];
    extern int8_t output_data[];

    #ifdef AL_ACCEL
        extern int32_t ps_data[];
    #endif
#endif

/* Fully-Connected Layer */
#ifdef FCL_TEST
    extern int32_t  input_offset;
    extern int32_t  output_offset;

    extern int32_t output_multiplier;
    extern int8_t  output_shift;

    extern int input_dims [];
    extern int filter_dims[]; 
    extern int bias_dims  [];
    extern int output_dims[];

    extern int8_t input_data [];
    extern int8_t filter_data[];
    extern int32_t bias_data [];
    extern int8_t output_data[];

    #ifdef AL_ACCEL
        extern int32_t ps_data[];
    #endif
#endif
/***************************/

/* Pooling Layer */
#ifdef PL_TEST 
    extern int input_dims[];
    extern int output_dims[];
    extern int stride_width;
    extern int filter_width;
    extern int stride_height;
    extern int filter_height;

    extern int8_t input_data[];
    extern int8_t output_data[];
#endif
/***************************/

#ifdef  NO_TEST
    #error "NOOOOOO TESTTTT"
#endif


/* Mixed Layer */
#ifdef ML_TEST
    extern int32_t  input_offset;
    extern int32_t  output_offset;

    extern int32_t  output_multiplier[];
    extern int8_t   output_shift[];

    extern int input_dims [];
    extern int filter_dims[];
    extern int bias_dims  [];
    extern int stride_width;
    extern int stride_height;
    extern int output_dims[];
    extern int output_conv_dims[];
    

    extern int8_t input_data [];
    extern int8_t filter_data[];
    extern int32_t bias_data [];
    extern int8_t output_data[];
    extern int8_t output_conv_data[]; 

    #ifdef AL_ACCEL
        extern int32_t ps_data[];
    #endif
#endif


#endif