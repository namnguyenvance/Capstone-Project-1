#ifndef FW_UTIL_H
#define FW_UTIL_H

#include <stdint.h>
#include <stdbool.h>

#include "pico_io.h"

/* IO Util Function for DL */
void printArray4DI(const int8_t* arr, const int* dims);
void printArray3DI(const int8_t* arr, const int* dims);
void printArray2DI(const int8_t* arr, const int* dims);
void printArray1DI(const int8_t* arr, const int len);\

/* For PS DATA */
void printArray1DV(const int8_t* arr, const int len);
/* SoC Util Function */
void *memcpy(void *dest, const void *src, size_t n);
void *memset(void *s, int c,  unsigned int len);



/* DL Util Function */
int get_label(const int8_t model_output_data[], const int model_output_len);
/* Pico Origrnal */
// void flashio(uint8_t *data, int len, uint8_t wrencmd);
// void set_flash_qspi_flag();
// void set_flash_latency(uint8_t value);

// void set_flash_mode_spi();
// void set_flash_mode_dual();
// void set_flash_mode_quad();
// void set_flash_mode_qddr();

// void cmd_print_spi_state();

// uint32_t cmd_benchmark(bool verbose);
// uint32_t func_benchmark(void (*fp)());
#endif

