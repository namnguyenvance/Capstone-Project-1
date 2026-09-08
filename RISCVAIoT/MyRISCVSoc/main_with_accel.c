// Memory-mapped registers for basic peripherals
#define REG_LEDS      (*(volatile unsigned char*)0x03000000)
#define REG_UART_DATA (*(volatile unsigned int*) 0x02000008)

// Accelerator Registers (Memory-mapped IO)
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

int main() {
    // Set LED status to 0x02 (Running Hardware Accelerator Mode)
    REG_LEDS = 0x02;

    print("--- RUNNING WITH HARDWARE ACCELERATOR ---\n");

    unsigned int a = 12345;
    unsigned int b = 6789;

    // Start benchmark
    unsigned int start_time = rdcycle();
    
    // Write operands to accelerator memory-mapped registers
    REG_ACCEL_A = a;
    REG_ACCEL_B = b;
    
    // Read the multiplication result immediately from accelerator output register
    unsigned int result = REG_ACCEL_Y;
    
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

    print("Cycles consumed by Hardware Accelerator: ");
    print_dec(elapsed_cycles);
    print(" cycles\n");

    print("All tasks completed. Entering infinite loop.\n");
    while (1) {
        // Loop forever
    }

    return 0;
}
