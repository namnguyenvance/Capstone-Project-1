// Memory-mapped registers
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

// Accelerator Registers
#define REG_ACCEL_A   (*(volatile unsigned int*) 0x02000010)
#define REG_ACCEL_B   (*(volatile unsigned int*) 0x02000014)
#define REG_ACCEL_Y   (*(volatile unsigned int*) 0x02000018)

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

// Fast division by 10 using shift-and-subtract (binary division) to avoid slow subtraction loops
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
void print_dec(unsigned int val) {
    char buffer[10];
    int i = 0;
    if (val == 0) {
        putchar('0');
        return;
    }
    while (val > 0) {
        unsigned int rem;
        val = div10(val, &rem);
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

// Software implementation of multiplication (shift-and-add)
unsigned int mul_sw(unsigned int a, unsigned int b) {
    unsigned int res = 0;
    while (b > 0) {
        if (b & 1) {
            res += a;
        }
        a <<= 1;
        b >>= 1;
    }
    return res;
}

int main() {
    REG_LEDS = 0x01;

    print("PicoSoC booting in MyRISCVSoc...\n");
    print("Testing Hardware Accelerator (Multiplier)...\n");

    // Test Case 1: 6 * 7
    unsigned int a1 = 6;
    unsigned int b1 = 7;
    REG_ACCEL_A = a1;
    REG_ACCEL_B = b1;
    
    // Read the result immediately!
    unsigned int result1 = REG_ACCEL_Y;

    print("Test 1: ");
    print_dec(a1);
    print(" * ");
    print_dec(b1);
    print(" = ");
    print_dec(result1);
    print("\n");

    if (result1 == 42) {
        print("--> Test 1 SUCCESS!\n");
        REG_LEDS = 0xAA;
    } else {
        print("--> Test 1 FAILED!\n");
        REG_LEDS = 0xFF;
    }

    // Test Case 2: 123 * 456
    unsigned int a2 = 123;
    unsigned int b2 = 456;
    REG_ACCEL_A = a2;
    REG_ACCEL_B = b2;
    unsigned int result2 = REG_ACCEL_Y;

    print("Test 2: ");
    print_dec(a2);
    print(" * ");
    print_dec(b2);
    print(" = ");
    print_dec(result2);
    print("\n");

    if (result2 == 56088) {
        print("--> Test 2 SUCCESS!\n");
        REG_LEDS = 0x55;
    } else {
        print("--> Test 2 FAILED!\n");
        REG_LEDS = 0xFF;
    }

    // Benchmarking Software vs Hardware Accelerator
    print("\n=== BENCHMARK COMPARISON ===\n");
    
    unsigned int a_bench = 12345;
    unsigned int b_bench = 6789;
    
    // 1. Software multiplication benchmark
    unsigned int start_sw = rdcycle();
    unsigned int res_sw = mul_sw(a_bench, b_bench);
    unsigned int end_sw = rdcycle();
    unsigned int cycles_sw = end_sw - start_sw;
    
    // 2. Hardware Accelerated multiplication benchmark
    unsigned int start_hw = rdcycle();
    REG_ACCEL_A = a_bench;
    REG_ACCEL_B = b_bench;
    unsigned int res_hw = REG_ACCEL_Y;
    unsigned int end_hw = rdcycle();
    unsigned int cycles_hw = end_hw - start_hw;
    
    print("Software Multiplier (C code Shift-and-Add):\n");
    print("  Result: ");
    print_dec(res_sw);
    print("\n  Cycles: ");
    print_dec(cycles_sw);
    print("\n");
    
    print("Hardware Accelerator (Custom HW Multiplier):\n");
    print("  Result: ");
    print_dec(res_hw);
    print("\n  Cycles: ");
    print_dec(cycles_hw);
    print("\n");

    unsigned int saved_cycles = cycles_sw - cycles_hw;
    print("Hardware saved ");
    print_dec(saved_cycles);
    print(" cycles!\n");

    print("All tests completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
