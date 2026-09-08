#ifndef LAYER_DENSE_DATA_H
#define LAYER_DENSE_DATA_H

#include <stdint.h>

#ifdef DENSE_LAYER_TEST
    extern int32_t  input_offset;
    extern int32_t  output_offset;

    extern int32_t  output_multiplier;
    extern int8_t   output_shift;

    extern int      input_dims[];
    extern int      filter_dims[];
    extern int      bias_dims[];
    extern int      output_dims[];

    extern int8_t   input_data[];
    extern int8_t   filter_data[]; 
    extern int32_t  bias_data[]; 
    extern int8_t   output_data[];
#endif

#endif