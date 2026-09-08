#ifndef DEMO_DATA_H
#define DEMO_DATA_H

#include <stdint.h>

extern const int32_t    conv_output_multiplier[];
extern const int8_t     conv_output_shift[];
extern const int32_t 	dense_output_multiplier;
extern const int8_t 	dense_output_shift;

extern const int        model_input_dims[];
extern const int8_t     model_input_data[];

extern const int        conv_weight_dims[];
extern const int8_t     conv_weight_data[];
extern const int        conv_bias_dims[];
extern const int32_t    conv_bias_data[];

extern const int        dense_weight_dims[];
extern const int8_t     dense_weight_data[];
extern const int        dense_bias_dims[];
extern const int32_t    dense_bias_data[];

#endif