#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// Mock hardware registers
unsigned char REG_LEDS;
unsigned int REG_UART_DATA;

// Mock rdcycle
unsigned int rdcycle() { return 0; }

// Define putchar and print to use stdio
void putchar_mock(char c) {
    putchar(c);
}
#define putchar putchar_mock

// Include the entire main_lenet.c except we need to redefine its putchar
#define main main_lenet
#include "main_lenet.c"
#undef main

int main() {
    printf("Running native test...\n");
    main_lenet();
    return 0;
}
