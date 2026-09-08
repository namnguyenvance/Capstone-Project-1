#define TINYMOBILENET_RUN
#include "tinymobilenet_model_data.h"
#include "mnist_test_images.h"
#include "dl_ops.h"

/* ========================================================================
 * TinyMobileNet MNIST Classifier
 * 
 * Architecture (inspired by MobileNetV2, scaled down for PicoRV32):
 *   Input 28x28x1 → Conv2D 3x3 → [DWConv + PWConv]×3 → GAP → FC → 10 classes
 * 
 * Key differences from LeNet-5:
 *   1. Depthwise Separable Convolution (not standard Conv2D)
 *   2. GlobalAveragePooling (not Flatten + large FC)
 *   3. ReLU6 activation (not ReLU)
 * ======================================================================== */

/* Memory-mapped registers for basic peripherals */
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

/* MNIST class names */
const char* const class_names[] = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
};

/* ========================================================================
 * UART output helpers
 * ======================================================================== */
void putchar(char c) {
    if (c == '\n') {
        REG_UART_DATA = '\r';
    }
    REG_UART_DATA = c;
}

void print(const char *str) {
    while (*str) {
        putchar(*str);
        str++;
    }
}

unsigned int div10(unsigned int n, unsigned int *rem) {
    unsigned int q = 0, r = 0;
    for (int i = 31; i >= 0; i--) {
        r = (r << 1) | ((n >> i) & 1);
        if (r >= 10) {
            r -= 10;
            q |= (1U << i);
        }
    }
    *rem = r;
    return q;
}

void print_dec(int val) {
    if (val < 0) {
        putchar('-');
        val = -val;
    }
    char buffer[10];
    int i = 0;
    unsigned int uval = (unsigned int)val;
    if (uval == 0) {
        putchar('0');
        return;
    }
    while (uval > 0) {
        unsigned int rem;
        uval = div10(uval, &rem);
        buffer[i++] = '0' + rem;
    }
    while (i > 0) {
        putchar(buffer[--i]);
    }
}

/* Read CPU cycle counter */
static inline unsigned int rdcycle(void) {
    unsigned int cycle;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

/* rv32i software multiplication helpers (no M extension fallback) */
int __mulsi3(int a, int b) {
    int res = 0;
    unsigned int ua = (a < 0) ? -a : a;
    unsigned int ub = (b < 0) ? -b : b;
    while (ub > 0) {
        if (ub & 1) {
            res += ua;
        }
        ua <<= 1;
        ub >>= 1;
    }
    if ((a < 0) ^ (b < 0)) {
        res = -res;
    }
    return res;
}

long long __muldi3(long long a, long long b) {
    long long res = 0;
    unsigned long long ua = (a < 0) ? -a : a;
    unsigned long long ub = (b < 0) ? -b : b;
    while (ub > 0) {
        if (ub & 1) {
            res += ua;
        }
        ua <<= 1;
        ub >>= 1;
    }
    if ((a < 0) ^ (b < 0)) {
        res = -res;
    }
    return res;
}

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
/* Input */
const int input_dims[] = {28, 28, 1};

/* Conv0: 3x3, stride 1, pad 1 → 28x28x16 */
const int conv0_out_dims[] = {28, 28, 16};

/* DW Block 1: DW 3x3 s1 p1 → 28x28x16, PW 1x1 → 28x28x32 */
const int dw1_out_dims[] = {28, 28, 16};
const int pw1_out_dims[] = {28, 28, 32};

/* DW Block 2: DW 3x3 s2 p1 → 14x14x32, PW 1x1 → 14x14x48 */
const int dw2_out_dims[] = {14, 14, 32};
const int pw2_out_dims[] = {14, 14, 48};

/* DW Block 3: DW 3x3 s2 p1 → 7x7x48, PW 1x1 → 7x7x64 */
const int dw3_out_dims[] = {7, 7, 48};
const int pw3_out_dims[] = {7, 7, 64};

/* GAP output + FC */
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

/* ========================================================================
 * Main Inference Pipeline
 * ======================================================================== */
int main() {
    REG_LEDS = 0x01;
    print("PicoSoC booting: TinyMobileNet MNIST Classifier\n");
    print("Architecture: Conv2D -> [DWConv+PWConv]x3 -> GAP -> FC\n\n");

    int total_passed = 0;

    // Limit to 1 image for hardware simulation to save time
    for (int img_idx = 0; img_idx < 1; img_idx++) {
        print("=== Image ");
        print_dec(img_idx);
        print(" (Target: ");
        print(class_names[test_labels[img_idx]]);
        print(") ===\n");

        unsigned int total_start = rdcycle();
        unsigned int layer_start, layer_end;

        /* ---- Layer 1: Conv0 (standard 3x3 conv, 1→16 channels) ---- */
        print("  Conv0 3x3 [1->16]...");
        layer_start = rdcycle();
        Conv2D_TFLM(
            test_images[img_idx], input_dims, tmn_conv0_input_offset,
            tmn_conv0_kernel_data, tmn_conv0_kernel_dims,
            tmn_conv0_bias_data, tmn_conv0_bias_dims,
            1, 1,   /* stride */
            1, 1,   /* padding (same) */
            buf_a, conv0_out_dims, tmn_conv0_output_offset,
            tmn_conv0_output_multiplier, tmn_conv0_output_shift,
            -128, 127  /* ReLU6: min=0, max will be clamped by quantization */
        );
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 2: DW Block 1 - DepthwiseConv 3x3 (16ch, stride 1) ---- */
        print("  DW1 3x3 [16ch s1]...");
        layer_start = rdcycle();
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
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 3: DW Block 1 - PointwiseConv 1x1 (16→32) ---- */
        print("  PW1 1x1 [16->32]...");
        layer_start = rdcycle();
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
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 4: DW Block 2 - DepthwiseConv 3x3 (32ch, stride 2) ---- */
        print("  DW2 3x3 [32ch s2]...");
        layer_start = rdcycle();
        DepthwiseConv2D_TFLM(
            buf_a, pw1_out_dims, tmn_dw2_input_offset,
            tmn_dw2_kernel_data, tmn_dw2_kernel_dims,
            tmn_dw2_bias_data, tmn_dw2_bias_dims,
            2, 2,   /* stride 2 → downsample */
            0, 0,   /* padding (same) -> left=0, right=1 for stride 2 */
            1,
            buf_b, dw2_out_dims, tmn_dw2_output_offset,
            tmn_dw2_output_multiplier, tmn_dw2_output_shift,
            -128, 127
        );
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 5: DW Block 2 - PointwiseConv 1x1 (32→48) ---- */
        print("  PW2 1x1 [32->48]...");
        layer_start = rdcycle();
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
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 6: DW Block 3 - DepthwiseConv 3x3 (48ch, stride 2) ---- */
        print("  DW3 3x3 [48ch s2]...");
        layer_start = rdcycle();
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
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 7: DW Block 3 - PointwiseConv 1x1 (48→64) ---- */
        print("  PW3 1x1 [48->64]...");
        layer_start = rdcycle();
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
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 8: Global Average Pooling (7x7x64 → 64) ---- */
        print("  GAP [7x7x64->64]...");
        layer_start = rdcycle();
        GlobalAveragePool_TFLM(
            buf_a, pw3_out_dims,
            gap_output,
            tmn_gap_input_offset, tmn_gap_output_offset,
            tmn_gap_output_multiplier, tmn_gap_output_shift,
            -128, 127
        );
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        /* ---- Layer 9: Final Dense (64 → 10 classes) ---- */
        print("  FC [64->10]...");
        layer_start = rdcycle();
        FullyConnected2D_TFLM(
            gap_output, gap_out_dims, tmn_dense_input_offset,
            tmn_dense_weight_data, tmn_dense_weight_dims,
            tmn_dense_bias_data, tmn_dense_bias_dims,
            fc_output, fc_out_dims, tmn_dense_output_offset,
            tmn_dense_output_multiplier, tmn_dense_output_shift,
            -128, 127
        );
        layer_end = rdcycle();
        print_dec(layer_end - layer_start);
        print(" cycles\n");

        unsigned int total_end = rdcycle();

        /* Print results */
        int predicted = get_predicted_class(fc_output, 10);

        print("  Scores: [");
        for (int c = 0; c < 10; c++) {
            print_dec(fc_output[c]);
            if (c < 9) print(", ");
        }
        print("]\n");

        print("  >> Predicted: ");
        print(class_names[predicted]);
        print(" | Total: ");
        print_dec(total_end - total_start);
        print(" cycles\n\n");

        if (predicted == test_labels[img_idx]) {
            total_passed++;
        }
    }

    print("========================================\n");
    print("FINAL RESULT: ");
    print_dec(total_passed);
    print("/");
    print_dec(number_of_test);
    print(" correct\n");

    if (total_passed == number_of_test) {
        print("--> TinyMobileNet Classification SUCCESS!\n");
        REG_LEDS = 0xAA;
    } else {
        print("--> TinyMobileNet Classification PARTIAL.\n");
        REG_LEDS = 0xFF;
    }

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
