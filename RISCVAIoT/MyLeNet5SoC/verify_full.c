#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#include "../DLCProgram/CSource/quantize.h"
#include "../DLCProgram/CSource/dl_ops.h"

#define LENET_RUN
#include "../DLCProgram/CSource/lenet_model_data.h"
#include "../DLCProgram/CSource/mnist_input_data.h"

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
    printf("=== LeNet-5 Full MNIST Test (10000 images) ===\n\n");
    int total_passed = 0;
    int class_correct[10] = {0};
    int class_total[10] = {0};

    for (int i = 0; i < number_of_test; i++) {
        Conv2D_TFLM(test_images[i], model_input_dims, 128, lenet_conv0_kernel_data, lenet_conv0_kernel_dims, lenet_conv0_bias_data, lenet_conv0_bias_dims, 1, 1, 0, 0, lenet_conv0_output_data, lenet_conv0_output_dims, 128, lenet_conv0_output_multiplier, lenet_conv0_output_shift, 0, 999999);
        MaxPool_TFLM(lenet_conv0_output_data, lenet_conv0_output_dims, 2, 2, 0, 0, 2, 2, lenet_pool0_output_data, lenet_pool0_output_dims, 0, 999999);
        Conv2D_TFLM(lenet_pool0_output_data, lenet_pool0_output_dims, 128, lenet_conv1_kernel_data, lenet_conv1_kernel_dims, lenet_conv1_bias_data, lenet_conv1_bias_dims, 1, 1, 0, 0, lenet_conv1_output_data, lenet_conv1_output_dims, 128, lenet_conv1_output_multiplier, lenet_conv1_output_shift, 0, 999999);
        MaxPool_TFLM(lenet_conv1_output_data, lenet_conv1_output_dims, 2, 2, 0, 0, 2, 2, lenet_pool1_output_data, lenet_pool1_output_dims, 0, 999999);
        FullyConnected2D_TFLM(lenet_pool1_output_data, lenet_dense0_input_dims, 128, lenet_dense0_weight_data, lenet_dense0_weight_dims, lenet_dense0_bias_data, lenet_dense0_bias_dims, lenet_dense0_output_data, lenet_dense0_output_dims, 128, lenet_dense0_output_multiplier, lenet_dense0_output_shift, 0, 999999);
        FullyConnected2D_TFLM(lenet_dense0_output_data, lenet_dense0_output_dims, 128, lenet_dense1_weight_data, lenet_dense1_weight_dims, lenet_dense1_bias_data, lenet_dense1_bias_dims, lenet_dense1_output_data, lenet_dense1_output_dims, 128, lenet_dense1_output_multiplier, lenet_dense1_output_shift, 0, 999999);
        FullyConnected2D_TFLM(lenet_dense1_output_data, lenet_dense1_output_dims, 128, lenet_dense2_weight_data, lenet_dense2_weight_dims, lenet_dense2_bias_data, lenet_dense2_bias_dims, lenet_dense2_output_data, lenet_dense2_output_dims, 19, lenet_dense2_output_multiplier, lenet_dense2_output_shift, -999999, 999999);

        int predicted = 0;
        int8_t max_val = lenet_dense2_output_data[0];
        for (int c = 1; c < 10; c++) {
            if (lenet_dense2_output_data[c] > max_val) { max_val = lenet_dense2_output_data[c]; predicted = c; }
        }

        int label = test_labels[i];
        class_total[label]++;
        if (predicted == label) { total_passed++; class_correct[label]++; }

        if ((i+1) % 1000 == 0) {
            printf("  Progress: %d/%d (accuracy so far: %.2f%%)\n", i+1, number_of_test, 100.0*total_passed/(i+1));
        }
    }

    printf("\n=== RESULTS ===\n");
    printf("Total: %d/%d correct (%.2f%% accuracy)\n\n", total_passed, number_of_test, 100.0*total_passed/number_of_test);
    printf("Per-class accuracy:\n");
    for (int c = 0; c < 10; c++) {
        printf("  Digit %d: %d/%d (%.1f%%)\n", c, class_correct[c], class_total[c], 100.0*class_correct[c]/class_total[c]);
    }
    return 0;
}
