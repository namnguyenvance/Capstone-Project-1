#define LENET_RUN
#include "../DLCProgram/CSource/lenet_model_data.h"
#include "mnist_test_images.h"
#include "dl_ops.h"

// Memory-mapped registers for basic peripherals
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

// Send a single character via UART
void putchar(char c) {
    if (c == '\n') {
        REG_UART_DATA = '\r';
    }
    REG_UART_DATA = c;
}

// Print a null-terminated string
void print(const char *str) {
    while (*str) {
        putchar(*str);
        str++;
    }
}

// Fast division by 10 using shift-and-subtract
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

// Print a decimal number
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

// Read CPU cycle counter
static inline unsigned int rdcycle(void) {
    unsigned int cycle;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

// rv32i software multiplication helpers
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

// Quantization operators
// Layer parameters are now coming from lenet_model_data.h

// Static layer buffers
int8_t lenet_conv0_output_data[26 * 26 * 6];
int8_t lenet_pool0_output_data[13 * 13 * 6];
int8_t lenet_conv1_output_data[11 * 11 * 16];
int8_t lenet_pool1_output_data[5 * 5 * 16];
int8_t lenet_dense0_output_data[120];
int8_t lenet_dense1_output_data[84];
int8_t lenet_dense2_output_data[10];

// Intermediate dimensions not in lenet_model_data.h
const int lenet_conv0_output_dims[] = {26, 26, 6};
const int lenet_pool0_output_dims[] = {13, 13, 6};
const int lenet_conv1_output_dims[] = {11, 11, 16};
const int lenet_pool1_output_dims[] = {5, 5, 16};
const int lenet_dense0_input_dims[]  = {400};
const int lenet_dense0_output_dims[] = {120};
const int lenet_dense1_output_dims[] = {84};
const int lenet_dense2_output_dims[] = {10};

// Helper to get predicted label from FC scores
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
    REG_LEDS = 0x01;
    print("PicoSoC booting: Running LeNet-5 MNIST Classifier...\n\n");

    int total_passed = 0;

    for (int i = 0; i < number_of_test; i++) {
        print("--- Running Inference on Image ");
        print_dec(i);
        print(" (Target: ");
        print_dec(test_labels[i]);
        print(") ---\n");

        unsigned int start_time = rdcycle();

        print("  - Running Conv0...\n");
        // 1. Conv0 (3x3 kernel, 1 -> 6 channels, no padding, stride 1)
        Conv2D_TFLM(
            test_images[i], model_input_dims, 128,
            lenet_conv0_kernel_data, lenet_conv0_kernel_dims,
            lenet_conv0_bias_data, lenet_conv0_bias_dims,
            1, 1,
            0, 0,
            lenet_conv0_output_data, lenet_conv0_output_dims, 128,
            lenet_conv0_output_multiplier, lenet_conv0_output_shift,
            0, 999999
        );

        print("  - Running Pool0...\n");
        // 2. Pool0 (MaxPool 2x2, stride 2)
        MaxPool_TFLM(
            lenet_conv0_output_data, lenet_conv0_output_dims,
            2, 2,
            0, 0,
            2, 2,
            lenet_pool0_output_data, lenet_pool0_output_dims,
            0, 999999
        );

        print("  - Running Conv1...\n");
        // 3. Conv1 (3x3 kernel, 6 -> 16 channels, no padding, stride 1)
        Conv2D_TFLM(
            lenet_pool0_output_data, lenet_pool0_output_dims, 128,
            lenet_conv1_kernel_data, lenet_conv1_kernel_dims,
            lenet_conv1_bias_data, lenet_conv1_bias_dims,
            1, 1,
            0, 0,
            lenet_conv1_output_data, lenet_conv1_output_dims, 128,
            lenet_conv1_output_multiplier, lenet_conv1_output_shift,
            0, 999999
        );

        print("  - Running Pool1...\n");
        // 4. Pool1 (MaxPool 2x2, stride 2)
        MaxPool_TFLM(
            lenet_conv1_output_data, lenet_conv1_output_dims,
            2, 2,
            0, 0,
            2, 2,
            lenet_pool1_output_data, lenet_pool1_output_dims,
            0, 999999
        );

        print("  - Running Dense0...\n");
        // 5. Dense0 (400 -> 120 units)
        FullyConnected2D_TFLM(
            lenet_pool1_output_data, lenet_dense0_input_dims, 128,
            lenet_dense0_weight_data, lenet_dense0_weight_dims,
            lenet_dense0_bias_data, lenet_dense0_bias_dims,
            lenet_dense0_output_data, lenet_dense0_output_dims, 128,
            lenet_dense0_output_multiplier, lenet_dense0_output_shift,
            0, 999999
        );

        print("  - Running Dense1...\n");
        // 6. Dense1 (120 -> 84 units)
        FullyConnected2D_TFLM(
            lenet_dense0_output_data, lenet_dense0_output_dims, 128,
            lenet_dense1_weight_data, lenet_dense1_weight_dims,
            lenet_dense1_bias_data, lenet_dense1_bias_dims,
            lenet_dense1_output_data, lenet_dense1_output_dims, 128,
            lenet_dense1_output_multiplier, lenet_dense1_output_shift,
            0, 999999
        );

        print("  - Running Dense2...\n");
        // 7. Dense2 (84 -> 10 units)
        FullyConnected2D_TFLM(
            lenet_dense1_output_data, lenet_dense1_output_dims, 128,
            lenet_dense2_weight_data, lenet_dense2_weight_dims,
            lenet_dense2_bias_data, lenet_dense2_bias_dims,
            lenet_dense2_output_data, lenet_dense2_output_dims, 19,
            lenet_dense2_output_multiplier, lenet_dense2_output_shift,
            -999999, 999999
        );

        unsigned int end_time = rdcycle();
        unsigned int cycles = end_time - start_time;

        int predicted = get_predicted_class(lenet_dense2_output_data, 10);

        print("      Scores: [");
        for (int c = 0; c < 10; c++) {
            print_dec(lenet_dense2_output_data[c]);
            if (c < 9) print(", ");
        }
        print("] -> Predicted: ");
        print_dec(predicted);
        print("\n");

        print("      Cycles: ");
        print_dec(cycles);
        print("\n\n");

        if (predicted == test_labels[i]) {
            total_passed++;
        }
    }

    print("=== FINAL EVALUATION RESULT ===\n");
    print_dec(total_passed);
    print("/");
    print_dec(number_of_test);
    print(" test cases passed.\n");

    if (total_passed == number_of_test) {
        print("--> LeNet-5 Classification SUCCESS! All test images correctly identified.\n");
        REG_LEDS = 0xAA;
    } else {
        print("--> LeNet-5 Classification FAILED!\n");
        REG_LEDS = 0xFF;
    }

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
