#ifndef MNIST_ALPICO_MODEL_DATA_H
#define MNIST_ALPICO_MODEL_DATA_H

#include <stdint.h>

extern int32_t conv_ps_data[];
extern int32_t dense_ps_data[];

extern const int conv_output_dims[];
extern int8_t conv_output_data[];

extern const int pool_output_dims[];
extern int8_t pool_output_data[];

extern const int dense_input_dims[];

extern const int dense_output_dims[];
extern int8_t dense_output_data[];

extern const int32_t    conv_output_multiplier[];
extern const int8_t     conv_output_shift[];
extern const int32_t    dense_output_multiplier;
extern const int8_t     dense_output_shift;

extern const int        conv_weight_dims[];
extern const int8_t     conv_weight_data[];
extern const int        conv_bias_dims[];
extern const int32_t    conv_bias_data[];
extern const int        dense_weight_dims[];
extern const int8_t     dense_weight_data[];
extern const int        dense_bias_dims[];
extern const int32_t    dense_bias_data[];

#endif