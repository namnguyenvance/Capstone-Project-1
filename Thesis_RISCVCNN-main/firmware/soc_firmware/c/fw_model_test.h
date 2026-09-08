#ifndef FW_MODEL_TEST_H
#define FW_MODEL_TEST_H

#include <stdint.h>

#include "pico_io.h"

void testInference_CNNNEW_MNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    const int32_t cnnnew_conv0_output_multiplier[], const int8_t cnnnew_conv0_output_shift[],
    const int32_t cnnnew_conv1_output_multiplier[], const int8_t cnnnew_conv1_output_shift[],
    const int32_t cnnnew_dense0_output_multiplier, const int8_t  cnnnew_dense0_output_shift,

    const int cnnnew_conv0_kernel_dims[], const int8_t cnnnew_conv0_kernel_data[],
    const int cnnnew_conv0_bias_dims[], const int32_t cnnnew_conv0_bias_data[],

    const int cnnnew_conv1_kernel_dims[], const int8_t cnnnew_conv1_kernel_data[],
    const int cnnnew_conv1_bias_dims[], const int32_t cnnnew_conv1_bias_data[],


    const int cnnnew_dense0_weight_dims[], const int8_t cnnnew_dense0_weight_data[],
    const int cnnnew_dense0_bias_dims[], const int32_t cnnnew_dense0_bias_data[],

    const int cnnnew_conv0_output_dims[], int8_t cnnnew_conv0_output_data[],
    const int cnnnew_pool0_output_dims[], int8_t cnnnew_pool0_output_data[],
    const int cnnnew_conv1_output_dims[], int8_t cnnnew_conv1_output_data[],
    const int cnnnew_pool1_output_dims[], int8_t cnnnew_pool1_output_data[],
    const int cnnnew_dense0_input_dims[], 
    const int cnnnew_dense0_output_dims[], int8_t cnnnew_dense0_output_data[]
);

void testInference_CNNNEW_MNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    int32_t cnnnew_conv0_ps_data[], int32_t cnnnew_conv1_ps_data[], 
    int32_t cnnnew_dense0_ps_data[],

    const int32_t cnnnew_conv0_output_multiplier[], const int8_t cnnnew_conv0_output_shift[],
    const int32_t cnnnew_conv1_output_multiplier[], const int8_t cnnnew_conv1_output_shift[],
    const int32_t cnnnew_dense0_output_multiplier, const int8_t  cnnnew_dense0_output_shift,

    const int cnnnew_conv0_kernel_dims[], const int8_t cnnnew_conv0_kernel_data[],
    const int cnnnew_conv0_bias_dims[], const int32_t cnnnew_conv0_bias_data[],

    const int cnnnew_conv1_kernel_dims[], const int8_t cnnnew_conv1_kernel_data[],
    const int cnnnew_conv1_bias_dims[], const int32_t cnnnew_conv1_bias_data[],


    const int cnnnew_dense0_weight_dims[], const int8_t cnnnew_dense0_weight_data[],
    const int cnnnew_dense0_bias_dims[], const int32_t cnnnew_dense0_bias_data[],

    const int cnnnew_conv0_output_dims[], int8_t cnnnew_conv0_output_data[],
    const int cnnnew_pool0_output_dims[], int8_t cnnnew_pool0_output_data[],
    const int cnnnew_conv1_output_dims[], int8_t cnnnew_conv1_output_data[],
    const int cnnnew_pool1_output_dims[], int8_t cnnnew_pool1_output_data[],
    const int cnnnew_dense0_input_dims[], 
    const int cnnnew_dense0_output_dims[], int8_t cnnnew_dense0_output_data[]
);

void testInference_CNNMNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
    const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
    const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
    const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

    const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
    const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

    const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
    const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],


    const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
    const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

    const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
    const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

    const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
    const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
    const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
    const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
    const int cnn_dense0_input_dims[], 
    const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
    const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
);

void testInference_SimpleMNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int test_idx, 
    const int model_input_dims[], 

    const int32_t conv_output_multiplier[], const int8_t conv_output_shift[],
    const int32_t dense_output_multiplier, const int8_t  dense_output_shift,
    const int conv_weight_dims[], const int8_t conv_weight_data[],
    const int conv_bias_dims[], const int32_t conv_bias_data[],
    const int dense_weight_dims[], const int8_t dense_weight_data[],
    const int dense_bias_dims[], const int32_t dense_bias_data[],

    const int conv_output_dims[], int8_t conv_output_data[],
    const int pool_output_dims[], int8_t pool_output_data[],
    const int dense_input_dims[], 
    const int dense_output_dims[], int8_t dense_output_data[]
);

void testInference_CNNMNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    int32_t cnn_conv0_ps_data[], int32_t cnn_conv1_ps_data[], 
    int32_t cnn_dense0_ps_data[], int32_t cnn_dense1_ps_data[],

    const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
    const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
    const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
    const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

    const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
    const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

    const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
    const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],


    const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
    const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

    const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
    const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

    const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
    const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
    const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
    const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
    const int cnn_dense0_input_dims[], 
    const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
    const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
);

void testInference_SimpleMNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int test_idx, 
    const int model_input_dims[], 

    int32_t conv_ps_data[], int32_t dense_ps_data[],

    const int32_t conv_output_multiplier[], const int8_t conv_output_shift[],
    const int32_t dense_output_multiplier, const int8_t  dense_output_shift,
    const int conv_weight_dims[], const int8_t conv_weight_data[],
    const int conv_bias_dims[], const int32_t conv_bias_data[],
    const int dense_weight_dims[], const int8_t dense_weight_data[],
    const int dense_bias_dims[], const int32_t dense_bias_data[],

    const int conv_output_dims[], int8_t conv_output_data[],
    const int pool_output_dims[], int8_t pool_output_data[],
    const int dense_input_dims[], 
    const int dense_output_dims[], int8_t dense_output_data[]
);

void testInference_NewSimpleMNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int test_idx, 
    const int model_input_dims[], 

    int32_t conv_ps_data[], int32_t dense_ps_data[],

    const int32_t conv_output_multiplier[], const int8_t conv_output_shift[],
    const int32_t dense_output_multiplier, const int8_t  dense_output_shift,
    const int conv_weight_dims[], const int8_t conv_weight_data[],
    const int conv_bias_dims[], const int32_t conv_bias_data[],
    const int dense_weight_dims[], const int8_t dense_weight_data[],
    const int dense_bias_dims[], const int32_t dense_bias_data[],

    const int conv_output_dims[], int8_t conv_output_data[],
    const int pool_output_dims[], int8_t pool_output_data[],
    const int dense_input_dims[], 
    const int dense_output_dims[], int8_t dense_output_data[]
);


#endif