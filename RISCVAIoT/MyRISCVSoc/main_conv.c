#include "conv_data.h"

// Memory-mapped registers for basic peripherals
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

// 2D Convolution Accelerator Addresses
#define CONV_IMG_BASE   ((volatile int*) 0x02000100) // 25 words (offsets 0 to 24)
#define CONV_KER_BASE   ((volatile int*) 0x02000170) // 9 words (offsets 28 to 36)
#define CONV_OUT_BASE   ((volatile int*) 0x020001A0) // 9 words (offsets 40 to 48)
#define CONV_CTRL       (*(volatile int*) 0x020001F0) // 1 word (offset 60)

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

// Print a decimal number (supports signed integers by printing '-' if negative)
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

// Software implementation of 2D Convolution (Valid padding, stride = 1)
void conv_sw(const int *image, const int *kernel, int *output) {
    for (int r = 0; r < OUT_ROWS; r++) {
        for (int c = 0; c < OUT_COLS; c++) {
            int sum = 0;
            for (int kr = 0; kr < KERNEL_SIZE; kr++) {
                for (int kc = 0; kc < KERNEL_SIZE; kc++) {
                    int img_val = image[(r + kr) * IMG_COLS + (c + kc)];
                    int ker_val = kernel[kr * KERNEL_SIZE + kc];
                    sum += img_val * ker_val;
                }
            }
            output[r * OUT_COLS + c] = sum;
        }
    }
}

int main() {
    REG_LEDS = 0x01;
    print("PicoSoC booting: Testing 2D Convolution Accelerator...\n\n");

    int sw_out[9] = {0};
    int hw_out[9] = {0};

    // --- 1. RUN SOFTWARE CONVOLUTION ---
    unsigned int start_sw = rdcycle();
    conv_sw(input_matrix, conv_kernel, sw_out);
    unsigned int end_sw = rdcycle();
    unsigned int cycles_sw = end_sw - start_sw;

    // --- 2. RUN HARDWARE ACCELERATED CONVOLUTION ---
    unsigned int start_hw = rdcycle();
    
    // Write image inputs
    for (int i = 0; i < 25; i++) {
        CONV_IMG_BASE[i] = input_matrix[i];
    }
    
    // Write kernel inputs
    for (int i = 0; i < 9; i++) {
        CONV_KER_BASE[i] = conv_kernel[i];
    }
    
    // Trigger convolution
    CONV_CTRL = 1;
    
    // Read output registers
    for (int i = 0; i < 9; i++) {
        hw_out[i] = CONV_OUT_BASE[i];
    }
    
    unsigned int end_hw = rdcycle();
    unsigned int cycles_hw = end_hw - start_hw;

    // --- 3. PRINT AND VERIFY RESULTS ---
    print("--- Convolution Input Image (5x5) ---\n");
    for (int r = 0; r < IMG_ROWS; r++) {
        for (int c = 0; c < IMG_COLS; c++) {
            print_dec(input_matrix[r * IMG_COLS + c]);
            print("\t");
        }
        print("\n");
    }

    print("\n--- Software Output (3x3) ---\n");
    for (int r = 0; r < OUT_ROWS; r++) {
        for (int c = 0; c < OUT_COLS; c++) {
            print_dec(sw_out[r * OUT_COLS + c]);
            print("\t");
        }
        print("\n");
    }

    print("\n--- Hardware Output (3x3) ---\n");
    for (int r = 0; r < OUT_ROWS; r++) {
        for (int c = 0; c < OUT_COLS; c++) {
            print_dec(hw_out[r * OUT_COLS + c]);
            print("\t");
        }
        print("\n");
    }

    // Verification against Golden Output
    int success = 1;
    for (int i = 0; i < 9; i++) {
        if (sw_out[i] != golden_output[i] || hw_out[i] != golden_output[i]) {
            success = 0;
            break;
        }
    }

    print("\n=== CONV BENCHMARK RESULT ===\n");
    print("Software Convolution Cycles: ");
    print_dec(cycles_sw);
    print("\n");

    print("Hardware Accelerator Cycles: ");
    print_dec(cycles_hw);
    print("\n");

    if (success) {
        print("--> Verification SUCCESS! Output matches Golden Output.\n");
        unsigned int saved = cycles_sw - cycles_hw;
        print("Hardware saved ");
        print_dec(saved);
        print(" cycles!\n");
        REG_LEDS = 0xAA;
    } else {
        print("--> Verification FAILED! Output mismatch.\n");
        REG_LEDS = 0xFF;
    }

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
