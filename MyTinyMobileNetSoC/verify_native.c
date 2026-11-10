#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define TINYMOBILENET_RUN
#include "tinymobilenet_model_data.h"
#include "mnist_test_images.h"
#include "dl_ops.h"

/* MNIST class names */
const char* const class_names[] = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
};

/* ========================================================================
 * Static Layer Buffers
 * ======================================================================== */
int8_t buf_a[28 * 28 * 32];
int8_t buf_b[28 * 28 * 32];
int8_t gap_output[64];
int8_t fc_output[10];

/* ========================================================================
 * Layer dimension arrays
 * Format: {width, height, channels}
 * ======================================================================== */
const int input_dims[] = {28, 28, 1};
const int conv0_out_dims[] = {28, 28, 16};
const int dw1_out_dims[] = {28, 28, 16};
const int pw1_out_dims[] = {28, 28, 32};
const int dw2_out_dims[] = {14, 14, 32};
const int pw2_out_dims[] = {14, 14, 48};
const int dw3_out_dims[] = {7, 7, 48};
const int pw3_out_dims[] = {7, 7, 64};
const int gap_out_dims[] = {64};
const int fc_out_dims[] = {10};

/* Helper to get predicted label */
int get_predicted_class(const int8_t *scores, int size) {
    int max_idx = 0;
    int8_t max_val = scores[0];
    for (int i = 1; i < size; i++) {
        if (scores[i] > max_val) {
            max_val = scores[i];
            max_idx = i;
        }
    }
    return max_idx;
}

int main() {
    printf("=== Native PC Verification (Software ONLY) ===\n\n");
    int total_passed = 0;

    for (int img_idx = 0; img_idx < number_of_test; img_idx++) {
        printf("=== Image %d (Target: %s) ===\n", img_idx, class_names[test_labels[img_idx]]);

        /* ---- Layer 1: Conv0 ---- */
        Conv2D_TFLM(
            test_images[img_idx], input_dims, tmn_conv0_input_offset,
            tmn_conv0_kernel_data, tmn_conv0_kernel_dims,
            tmn_conv0_bias_data, tmn_conv0_bias_dims,
            1, 1,   /* stride */
            1, 1,   /* padding (same) */
            buf_a, conv0_out_dims, tmn_conv0_output_offset,
            tmn_conv0_output_multiplier, tmn_conv0_output_shift,
            -128, 127  /* ReLU6 / int8 bounds */
        );

        /* ---- Layer 2: DW Block 1 - DepthwiseConv 3x3 ---- */
        DepthwiseConv2D_TFLM(
            buf_a, conv0_out_dims, tmn_dw1_input_offset,
            tmn_dw1_kernel_data, tmn_dw1_kernel_dims,
            tmn_dw1_bias_data, tmn_dw1_bias_dims,
            1, 1,   /* stride */
            1, 1,   /* padding (same) */
            1,       /* depth_multiplier */
            buf_b, dw1_out_dims, tmn_dw1_output_offset,
            tmn_dw1_output_multiplier, tmn_dw1_output_shift,
            -128, 127
        );

        /* ---- Layer 3: DW Block 1 - PointwiseConv 1x1 ---- */
        Conv2D_TFLM(
            buf_b, dw1_out_dims, tmn_pw1_input_offset,
            tmn_pw1_kernel_data, tmn_pw1_kernel_dims,
            tmn_pw1_bias_data, tmn_pw1_bias_dims,
            1, 1,   /* stride */
            0, 0,   /* no padding for 1x1 */
            buf_a, pw1_out_dims, tmn_pw1_output_offset,
            tmn_pw1_output_multiplier, tmn_pw1_output_shift,
            -128, 127
        );

        /* ---- Layer 4: DW Block 2 - DepthwiseConv 3x3 (stride 2) ---- */
        DepthwiseConv2D_TFLM(
            buf_a, pw1_out_dims, tmn_dw2_input_offset,
            tmn_dw2_kernel_data, tmn_dw2_kernel_dims,
            tmn_dw2_bias_data, tmn_dw2_bias_dims,
            2, 2,   /* stride 2 */
            0, 0,   /* padding (same) -> left=0, right=1 for stride 2 */
            1,
            buf_b, dw2_out_dims, tmn_dw2_output_offset,
            tmn_dw2_output_multiplier, tmn_dw2_output_shift,
            -128, 127
        );

        /* ---- Layer 5: DW Block 2 - PointwiseConv 1x1 ---- */
        Conv2D_TFLM(
            buf_b, dw2_out_dims, tmn_pw2_input_offset,
            tmn_pw2_kernel_data, tmn_pw2_kernel_dims,
            tmn_pw2_bias_data, tmn_pw2_bias_dims,
            1, 1,
            0, 0,
            buf_a, pw2_out_dims, tmn_pw2_output_offset,
            tmn_pw2_output_multiplier, tmn_pw2_output_shift,
            -128, 127
        );

        /* ---- Layer 6: DW Block 3 - DepthwiseConv 3x3 (stride 2) ---- */
        DepthwiseConv2D_TFLM(
            buf_a, pw2_out_dims, tmn_dw3_input_offset,
            tmn_dw3_kernel_data, tmn_dw3_kernel_dims,
            tmn_dw3_bias_data, tmn_dw3_bias_dims,
            2, 2,
            0, 0,   /* padding (same) -> left=0, right=1 for stride 2 */
            1,
            buf_b, dw3_out_dims, tmn_dw3_output_offset,
            tmn_dw3_output_multiplier, tmn_dw3_output_shift,
            -128, 127
        );

        /* ---- Layer 7: DW Block 3 - PointwiseConv 1x1 ---- */
        Conv2D_TFLM(
            buf_b, dw3_out_dims, tmn_pw3_input_offset,
            tmn_pw3_kernel_data, tmn_pw3_kernel_dims,
            tmn_pw3_bias_data, tmn_pw3_bias_dims,
            1, 1,
            0, 0,
            buf_a, pw3_out_dims, tmn_pw3_output_offset,
            tmn_pw3_output_multiplier, tmn_pw3_output_shift,
            -128, 127
        );

        /* ---- Layer 8: Global Average Pooling ---- */
        GlobalAveragePool_TFLM(
            buf_a, pw3_out_dims,
            gap_output,
            tmn_gap_input_offset, tmn_gap_output_offset,
            tmn_gap_output_multiplier, tmn_gap_output_shift,
            -128, 127
        );

        /* ---- Layer 9: Final Dense ---- */
        FullyConnected2D_TFLM(
            gap_output, gap_out_dims, tmn_dense_input_offset,
            tmn_dense_weight_data, tmn_dense_weight_dims,
            tmn_dense_bias_data, tmn_dense_bias_dims,
            fc_output, fc_out_dims, tmn_dense_output_offset,
            tmn_dense_output_multiplier, tmn_dense_output_shift,
            -128, 127
        );

        /* Print results */
        int predicted = get_predicted_class(fc_output, 10);

        printf("  Scores: [");
        for (int c = 0; c < 10; c++) {
            printf("%d", fc_output[c]);
            if (c < 9) printf(", ");
        }
        printf("]\n");

        printf("  >> Predicted: %s %s\n\n", class_names[predicted], (predicted == test_labels[img_idx]) ? "PASS" : "FAIL");

        if (predicted == test_labels[img_idx]) {
            total_passed++;
        }
    }

    printf("========================================\n");
    printf("FINAL RESULT: %d/%d passed\n", total_passed, number_of_test);

    return 0;
}
