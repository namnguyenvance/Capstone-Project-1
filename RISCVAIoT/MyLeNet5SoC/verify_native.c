#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#include "../DLCProgram/CSource/quantize.h"
#include "../DLCProgram/CSource/dl_ops.h"

#define LENET_RUN
#include "../DLCProgram/CSource/lenet_model_data.h"
#include "mnist_test_images.h"

int8_t lenet_conv0_output_data[26 * 26 * 6];
int8_t lenet_pool0_output_data[13 * 13 * 6];
int8_t lenet_conv1_output_data[11 * 11 * 16];
int8_t lenet_pool1_output_data[5 * 5 * 16];
int8_t lenet_dense0_output_data[120];
int8_t lenet_dense1_output_data[84];
int8_t lenet_dense2_output_data[10];

const int lenet_conv0_output_dims[] = {26, 26, 6};
const int lenet_pool0_output_dims[] = {13, 13, 6};
const int lenet_conv1_output_dims[] = {11, 11, 16};
const int lenet_pool1_output_dims[] = {5, 5, 16};
const int lenet_dense0_input_dims[]  = {400};
const int lenet_dense0_output_dims[] = {120};
const int lenet_dense1_output_dims[] = {84};
const int lenet_dense2_output_dims[] = {10};

int main() {
    printf("=== Native PC Verification (NO CHW->HWC, bias fixed) ===\n\n");
    int total_passed = 0;

    for (int i = 0; i < number_of_test; i++) {
        Conv2D_TFLM(
            test_images[i], model_input_dims, 128,
            lenet_conv0_kernel_data, lenet_conv0_kernel_dims,
            lenet_conv0_bias_data, lenet_conv0_bias_dims,
            1, 1, 0, 0,
            lenet_conv0_output_data, lenet_conv0_output_dims, 128,
            lenet_conv0_output_multiplier, lenet_conv0_output_shift,
            0, 999999);

        MaxPool_TFLM(
            lenet_conv0_output_data, lenet_conv0_output_dims,
            2, 2, 0, 0, 2, 2,
            lenet_pool0_output_data, lenet_pool0_output_dims,
            0, 999999);

        Conv2D_TFLM(
            lenet_pool0_output_data, lenet_pool0_output_dims, 128,
            lenet_conv1_kernel_data, lenet_conv1_kernel_dims,
            lenet_conv1_bias_data, lenet_conv1_bias_dims,
            1, 1, 0, 0,
            lenet_conv1_output_data, lenet_conv1_output_dims, 128,
            lenet_conv1_output_multiplier, lenet_conv1_output_shift,
            0, 999999);

        MaxPool_TFLM(
            lenet_conv1_output_data, lenet_conv1_output_dims,
            2, 2, 0, 0, 2, 2,
            lenet_pool1_output_data, lenet_pool1_output_dims,
            0, 999999);

        /* Dense weights were already reordered CHW in notebook, 
           so Pool1 CHW output feeds directly - NO conversion needed */
        FullyConnected2D_TFLM(
            lenet_pool1_output_data, lenet_dense0_input_dims, 128,
            lenet_dense0_weight_data, lenet_dense0_weight_dims,
            lenet_dense0_bias_data, lenet_dense0_bias_dims,
            lenet_dense0_output_data, lenet_dense0_output_dims, 128,
            lenet_dense0_output_multiplier, lenet_dense0_output_shift,
            0, 999999);

        FullyConnected2D_TFLM(
            lenet_dense0_output_data, lenet_dense0_output_dims, 128,
            lenet_dense1_weight_data, lenet_dense1_weight_dims,
            lenet_dense1_bias_data, lenet_dense1_bias_dims,
            lenet_dense1_output_data, lenet_dense1_output_dims, 128,
            lenet_dense1_output_multiplier, lenet_dense1_output_shift,
            0, 999999);

        FullyConnected2D_TFLM(
            lenet_dense1_output_data, lenet_dense1_output_dims, 128,
            lenet_dense2_weight_data, lenet_dense2_weight_dims,
            lenet_dense2_bias_data, lenet_dense2_bias_dims,
            lenet_dense2_output_data, lenet_dense2_output_dims, 19,
            lenet_dense2_output_multiplier, lenet_dense2_output_shift,
            -999999, 999999);

        int predicted = 0;
        int8_t max_val = lenet_dense2_output_data[0];
        for (int c = 1; c < 10; c++) {
            if (lenet_dense2_output_data[c] > max_val) {
                max_val = lenet_dense2_output_data[c];
                predicted = c;
            }
        }

        printf("Image %d (Target %d): Scores=[", i, test_labels[i]);
        for (int c = 0; c < 10; c++) {
            printf("%d", lenet_dense2_output_data[c]);
            if (c < 9) printf(", ");
        }
        printf("] -> Predicted: %d %s\n",
            predicted, (predicted == test_labels[i]) ? "PASS" : "FAIL");
        if (predicted == test_labels[i]) total_passed++;
    }

    printf("\n=== Result: %d/%d passed ===\n", total_passed, number_of_test);
    return 0;
}
