#ifndef LAYER_POOL_DATA_H
#define LAYER_POOL_DATA_H

#include <stdint.h>

#ifdef POOL_LAYER_TEST
    extern int      stride_width;
    extern int      stride_height;
    extern int      filter_width;
    extern int      filter_height;

    extern int      input_dims[];
    extern int      output_dims[];

    extern int8_t   input_data[];
    extern int8_t   output_data[];
#endif

#endif