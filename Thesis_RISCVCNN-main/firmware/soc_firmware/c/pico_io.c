#include "pico_io.h"
// #define VITIS
// -------------------------------------------------------- //

void putchar(char c) {
	if (c == '\n')
		putchar('\r');
	
	#ifndef VITIS
		reg_uart_data = c;
	#else
		reg_ps_data = c;
	#endif
}

void print(const char *p) {
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		// if (c == '0' && i >= digits) continue;
		if (i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v) {
	if (v < 10) {
		putchar('0' + v);
		return;
	}
	print_dec(v / 10);
	putchar('0' + (v % 10));
	// if (v >= 1000) {
	// 	print(">=1000");
	// 	return;
	// }

	// if      (v >= 900) { putchar('9'); v -= 900; }
	// else if (v >= 800) { putchar('8'); v -= 800; }
	// else if (v >= 700) { putchar('7'); v -= 700; }
	// else if (v >= 600) { putchar('6'); v -= 600; }
	// else if (v >= 500) { putchar('5'); v -= 500; }
	// else if (v >= 400) { putchar('4'); v -= 400; }
	// else if (v >= 300) { putchar('3'); v -= 300; }
	// else if (v >= 200) { putchar('2'); v -= 200; }
	// else if (v >= 100) { putchar('1'); v -= 100; }

	// if      (v >= 90) { putchar('9'); v -= 90; }
	// else if (v >= 80) { putchar('8'); v -= 80; }
	// else if (v >= 70) { putchar('7'); v -= 70; }
	// else if (v >= 60) { putchar('6'); v -= 60; }
	// else if (v >= 50) { putchar('5'); v -= 50; }
	// else if (v >= 40) { putchar('4'); v -= 40; }
	// else if (v >= 30) { putchar('3'); v -= 30; }
	// else if (v >= 20) { putchar('2'); v -= 20; }
	// else if (v >= 10) { putchar('1'); v -= 10; }
	// else putchar('0');

	// if      (v >= 9) { putchar('9'); v -= 9; }
	// else if (v >= 8) { putchar('8'); v -= 8; }
	// else if (v >= 7) { putchar('7'); v -= 7; }
	// else if (v >= 6) { putchar('6'); v -= 6; }
	// else if (v >= 5) { putchar('5'); v -= 5; }
	// else if (v >= 4) { putchar('4'); v -= 4; }
	// else if (v >= 3) { putchar('3'); v -= 3; }
	// else if (v >= 2) { putchar('2'); v -= 2; }
	// else if (v >= 1) { putchar('1'); v -= 1; }
	// else putchar('0');
}

void print_dec_8b(int8_t v) {
	int8_t v_signed = v & 0b1000000;
	
	int8_t v_val = (v_signed != 0) ? -v : v;

	if (v_signed) putchar('-');
	print_dec(v_val);
}


// -------------------------------------------------------- //

char getchar_prompt(char *prompt) {
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	reg_leds = ~0;

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			reg_leds = ~reg_leds;
		}
		c = reg_uart_data;
	}

	reg_leds = 0;
	return c;
}

char getcharacter() {
	return getchar_prompt(0);
}

// -------------------------------------------------------- //