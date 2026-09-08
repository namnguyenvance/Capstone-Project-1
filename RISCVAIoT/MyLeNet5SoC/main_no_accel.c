// Memory-mapped registers for basic peripherals (No Accelerator)
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

// Software implementation of multiplication (Shift-and-Add)
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
    // Set LED status to 0x01 (Running Software Mode)
    REG_LEDS = 0x01;

    print("--- RUNNING WITHOUT ACCELERATOR (SOFTWARE ONLY) ---\n");

    unsigned int a = 12345;
    unsigned int b = 6789;

    // Start benchmark
    unsigned int start_time = rdcycle();
    unsigned int result = mul_sw(a, b);
    unsigned int end_time = rdcycle();
    unsigned int elapsed_cycles = end_time - start_time;

    // Print results
    print("Calculation: ");
    print_dec(a);
    print(" * ");
    print_dec(b);
    print(" = ");
    print_dec(result);
    print("\n");

    print("Cycles consumed by Software: ");
    print_dec(elapsed_cycles);
    print(" cycles\n");

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
