#include "fw_utils.h"

extern uint32_t flashio_worker_begin;
extern uint32_t flashio_worker_end;

/* IO Util Function for DL */
void printArray4DI(const int8_t* arr, const int* dims) {
    for (int t_i = 0; t_i < dims[3]; ++t_i) {
        print("Channel = "); print_dec(t_i); print("\n");
        printArray3DI(arr + t_i * dims[2] * dims[1] * dims[0], dims);
        print("\n");
    }
}

void printArray3DI(const int8_t* arr, const int* dims) {
    for (int z_i = 0; z_i < dims[2]; ++z_i) {
		print("  z = "); print_dec(z_i); print("\n");
        printArray2DI(arr + z_i * dims[1] * dims[0], dims);
        print("\n");
    }
}

void printArray2DI(const int8_t* arr, const int* dims) {
    for (int y_i = 0; y_i < dims[1]; ++y_i) {
        printArray1DI(arr + y_i * dims[0], dims[0]);
    }
}

void printArray1DI(const int8_t* arr, const int len) {
    for (int i = 0; i < len; ++i) {
		// print("\t"); print_hex((uint32_t)arr[i], 8); 
		print(" "); print_hex((uint32_t)arr[i], 2);
    } 
    // print("\n");
}

void printArray1DV(const int8_t* arr, const int len) {
    for (int i = 0; i < len; ++i) {
        putchar((uint32_t)arr[i]);
    } 
}

/* SoC Util Function */
void *memcpy(void *dest, const void *src, size_t n)
{
    for (size_t i = 0; i < n; i++)
    {
        ((char*)dest)[i] = ((char*)src)[i];
    }
}

void *memset(void *s, int c,  unsigned int len)
{
    unsigned char* p=s;
    while(len--) {
        *p++ = (unsigned char)c;
    }
    return s;
}

int get_label(const int8_t model_output_data[], const int model_output_len) {
    // for (int i = 0; i < model_output_len; i++) 
    //     printf("%d ", model_output_data[i] + 128);
    // printf("\n");

    int8_t max_idx = 0;
    for (int idx = 1; idx < model_output_len; idx++) {
        if (model_output_data[idx] > model_output_data[max_idx]) max_idx = idx;
    }

    return max_idx;
}

/* Pico Original Firmware */
// void flashio(uint8_t *data, int len, uint8_t wrencmd)
// {
// 	uint32_t func[&flashio_worker_end - &flashio_worker_begin];

// 	uint32_t *src_ptr = &flashio_worker_begin;
// 	uint32_t *dst_ptr = func;

// 	while (src_ptr != &flashio_worker_end)
// 		*(dst_ptr++) = *(src_ptr++);

// 	((void(*)(uint8_t*, uint32_t, uint32_t))func)(data, len, wrencmd);
// }

// void set_flash_qspi_flag()
// {
// 	uint8_t buffer[8];

// 	// Read Configuration Registers (RDCR1 35h)
// 	buffer[0] = 0x35;
// 	buffer[1] = 0x00; // rdata
// 	flashio(buffer, 2, 0);
// 	uint8_t sr2 = buffer[1];

// 	// Write Enable Volatile (50h) + Write Status Register 2 (31h)
// 	buffer[0] = 0x31;
// 	buffer[1] = sr2 | 2; // Enable QSPI
// 	flashio(buffer, 2, 0x50);
// }

// void set_flash_qspi_flag()
// {
// 	uint8_t buffer[8];
// 	uint32_t addr_cr1v = 0x800002;

// 	// Read Any Register (RDAR 65h)
// 	buffer[0] = 0x65;
// 	buffer[1] = addr_cr1v >> 16;
// 	buffer[2] = addr_cr1v >> 8;
// 	buffer[3] = addr_cr1v;
// 	buffer[4] = 0; // dummy
// 	buffer[5] = 0; // rdata
// 	flashio(buffer, 6, 0);
// 	uint8_t cr1v = buffer[5];

// 	// Write Enable (WREN 06h) + Write Any Register (WRAR 71h)
// 	buffer[0] = 0x71;
// 	buffer[1] = addr_cr1v >> 16;
// 	buffer[2] = addr_cr1v >> 8;
// 	buffer[3] = addr_cr1v;
// 	buffer[4] = cr1v | 2; // Enable QSPI
// 	flashio(buffer, 5, 0x06);
// }


// void set_flash_latency(uint8_t value)
// {
// 	reg_spictrl = (reg_spictrl & ~0x007f0000) | ((value & 15) << 16);

// 	uint32_t addr = 0x800004;
// 	uint8_t buffer_wr[5] = {0x71, addr >> 16, addr >> 8, addr, 0x70 | value};
// 	flashio(buffer_wr, 5, 0x06);
// }

// void set_flash_mode_spi()
// {
// 	reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00000000;
// }

// void set_flash_mode_dual()
// {
// 	reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00400000;
// }

// void set_flash_mode_quad()
// {
// 	reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00200000;
// }

// void set_flash_mode_qddr()
// {
// 	reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00600000;
// }
// // /// 
// void cmd_print_spi_state()
// {
// 	print("SPI State:\n");

// 	print("  LATENCY ");
// 	print_dec((reg_spictrl >> 16) & 15);
// 	print("\n");

// 	print("  DDR ");
// 	if ((reg_spictrl & (1 << 22)) != 0)
// 		print("ON\n");
// 	else
// 		print("OFF\n");

// 	print("  QSPI ");
// 	if ((reg_spictrl & (1 << 21)) != 0)
// 		print("ON\n");
// 	else
// 		print("OFF\n");

// 	print("  CRM ");
// 	if ((reg_spictrl & (1 << 20)) != 0)
// 		print("ON\n");
// 	else
// 		print("OFF\n");
// }


// uint32_t cmd_benchmark(bool verbose)
// {
// 	uint8_t data[256];
// 	uint32_t *words = (void*)data;

// 	uint32_t x32 = 314159265;

// 	uint32_t cycles_begin, cycles_end;
// 	uint32_t instns_begin, instns_end;
// 	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
// 	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

// 	for (int i = 0; i < 1; i++)
// 	{
// 		for (int k = 0; k < 256; k++)
// 		{
// 			x32 ^= x32 << 13;
// 			x32 ^= x32 >> 17;
// 			x32 ^= x32 << 5;
// 			data[k] = x32;
// 		}

// 		for (int k = 0, p = 0; k < 256; k++)
// 		{
// 			if (data[k])
// 				data[p++] = k;
// 		}

// 		for (int k = 0, p = 0; k < 64; k++)
// 		{
// 			x32 = x32 ^ words[k];
// 		}
// 	}

// 	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
// 	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

// 	if (verbose)
// 	{
// 		print("Cycles: 0x");
// 		print_hex(cycles_end - cycles_begin, 8);
// 		putchar('\n');

// 		print("Instns: 0x");
// 		print_hex(instns_end - instns_begin, 8);
// 		putchar('\n');

// 		// print("Chksum: 0x");
// 		// print_hex(x32, 8);
// 		// putchar('\n');
// 	}

// 	return cycles_end - cycles_begin;
// }

// uint32_t func_benchmark(void (*fp)())
// {
// 	print("Function Benchmark!!\n");

// 	uint32_t cycles_begin, cycles_end;
// 	uint32_t instns_begin, instns_end;

// 	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
// 	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

// 	fp();

// 	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
// 	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

// 	print("Cycles: 0x");
// 	print_hex(cycles_end - cycles_begin, 8);
// 	putchar('\n');

// 	print("Instns: 0x");
// 	print_hex(instns_end - instns_begin, 8);
// 	putchar('\n');

// 	return cycles_end - cycles_begin;
// }