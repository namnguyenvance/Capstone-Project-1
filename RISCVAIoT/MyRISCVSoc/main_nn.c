#include "nn_data.h"

// Memory-mapped registers for basic peripherals
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

// 2D Convolution Accelerator Addresses
#define CONV_IMG_BASE   ((volatile int*) 0x02000100) // 25 words (offsets 0 to 24)
#define CONV_KER_BASE   ((volatile int*) 0x02000170) // 9 words (offsets 28 to 36)
#define CONV_OUT_BASE   ((volatile int*) 0x020001A0) // 9 words (offsets 40 to 48)
#define CONV_CTRL       (*(volatile int*) 0x020001F0) // 1 word (offset 60)

// Hardware Quantization Accelerator Addresses
#define QUANT_RAW_VAL    (*(volatile int*) 0x02000200)
#define QUANT_MULTIPLIER (*(volatile int*) 0x02000204)
#define QUANT_SHIFT      (*(volatile int*) 0x02000208)
#define QUANT_OUT        (*(volatile int*) 0x0200020C)
#define QUANT_CTRL       (*(volatile int*) 0x02000210)

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

// Fast division by 10 using shift-and-subtract (binary division)
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

// Print a decimal number (supports signed integers)
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

// Read CPU cycle counter (rdcycle instruction)
static inline unsigned int rdcycle(void) {
    unsigned int cycle;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

// Define compiler helper for multiplication under rv32i without libgcc
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

// Compiler helper for 64-bit multiplication
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

// Hardware-accelerated convolution helper
void conv_hw(const int *image, const int *kernel, int *output) {
    // Write image
    for (int i = 0; i < 25; i++) {
        CONV_IMG_BASE[i] = image[i];
    }
    // Write kernel
    for (int i = 0; i < 9; i++) {
        CONV_KER_BASE[i] = kernel[i];
    }
    // Trigger
    CONV_CTRL = 1;
    // Read output
    for (int i = 0; i < 9; i++) {
        output[i] = CONV_OUT_BASE[i];
    }
}

// Hardware Quantization helper
int quantize_hw(int raw_val, int multiplier, int shift) {
    QUANT_RAW_VAL = raw_val;
    QUANT_MULTIPLIER = multiplier;
    QUANT_SHIFT = shift;
    QUANT_CTRL = 1; // trigger compute
    return QUANT_OUT;
}

// Run CNN Inference pipeline for a single 5x5 image
int run_inference(const int *image, int *cycles_consumed) {
    int fmap_v[9];
    int fmap_h[9];
    int flat_features[18];

    unsigned int start_time = rdcycle();

    // 1. Feature Extraction: Vertical Filter using HW Accel
    conv_hw(image, conv_kernel_v, fmap_v);

    // 2. Feature Extraction: Horizontal Filter using HW Accel
    conv_hw(image, conv_kernel_h, fmap_h);

    // Flatten features (18 elements)
    for (int i = 0; i < 9; i++) {
        flat_features[i] = fmap_v[i];
        flat_features[i + 9] = fmap_h[i];
    }

    // 3. Fully Connected (FC) Layer computation: Score = Weight * Features + Bias
    int class_scores[3] = {0};
    for (int c = 0; c < NUM_CLASSES; c++) {
        int raw_acc = fc_biases[c];
        for (int f = 0; f < NUM_FEATURES; f++) {
            // fc_weights is a flattened 18x3 matrix
            raw_acc += flat_features[f] * fc_weights[f * NUM_CLASSES + c];
        }
        // Quantization Scaling (Hardware Accelerated)
        class_scores[c] = quantize_hw(raw_acc, FC_OUTPUT_MULTIPLIER, FC_OUTPUT_SHIFT);
    }

    unsigned int end_time = rdcycle();
    *cycles_consumed = end_time - start_time;

    // 4. Argmax: Find class with highest score
    int predicted_class = 0;
    int max_score = class_scores[0];
    for (int c = 1; c < NUM_CLASSES; c++) {
        if (class_scores[c] > max_score) {
            max_score = class_scores[c];
            predicted_class = c;
        }
    }

    // Print scores for debugging
    print("      Scores: [");
    for (int c = 0; c < NUM_CLASSES; c++) {
        print_dec(class_scores[c]);
        if (c < NUM_CLASSES - 1) print(", ");
    }
    print("] -> Predicted: ");
    print_dec(predicted_class);
    print("\n");

    return predicted_class;
}

int main() {
    REG_LEDS = 0x01;
    print("PicoSoC booting: Running Mini CNN Neural Network Classifier...\n\n");

    int cycles_0, cycles_1, cycles_2;
    int pred_0, pred_1, pred_2;

    print("--- Running Inference on Image 0 (Target: 0) ---\n");
    pred_0 = run_inference(test_image_0, &cycles_0);
    print("    Cycles: ");
    print_dec(cycles_0);
    print("\n\n");

    print("--- Running Inference on Image 1 (Target: 1) ---\n");
    pred_1 = run_inference(test_image_1, &cycles_1);
    print("    Cycles: ");
    print_dec(cycles_1);
    print("\n\n");

    print("--- Running Inference on Image 2 (Target: 2) ---\n");
    pred_2 = run_inference(test_image_2, &cycles_2);
    print("    Cycles: ");
    print_dec(cycles_2);
    print("\n\n");

    // Verification
    int success = (pred_0 == 0 && pred_1 == 1 && pred_2 == 2);

    print("=== FINAL EVALUATION RESULT ===\n");
    if (success) {
        print("--> CNN Classification SUCCESS! All test images correctly identified.\n");
        int total_cycles = cycles_0 + cycles_1 + cycles_2;
        print("Total inference cycles: ");
        print_dec(total_cycles);
        print(" cycles\n");
        REG_LEDS = 0xAA;
    } else {
        print("--> CNN Classification FAILED! Inconsistent prediction.\n");
        REG_LEDS = 0xFF;
    }

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
