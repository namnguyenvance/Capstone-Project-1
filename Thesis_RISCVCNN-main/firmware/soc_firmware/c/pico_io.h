#ifndef AL_IO_H
#define AL_IO_H

#include "pico_std.h"

/* Input Data */
void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v, int digits);
void print_dec(uint32_t v);
void print_dec_8b(int8_t v);

/* Output Data */
char getchar_prompt(char *prompt);
char getcharacter();

#endif