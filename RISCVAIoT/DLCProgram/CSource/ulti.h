#ifndef ULTI_H
#define ULTI_H

#include <stdint.h>
#include <stdio.h>
#include <limits.h>
#include <assert.h>
#include <math.h>
#include "dl_ops.h"
#include "quantize.h"

void printArray1DI32(const int32_t* arr, const int len);

void printArray4DI(const int8_t* arr, const int* dims);
void printArray3DI(const int8_t* arr, const int* dims);
void printArray2DI(const int8_t* arr, const int* dims);
void printArray1DI(const int8_t* arr, const int len);

void printArray3DIH(const int8_t* arr, const int* dims);
void printArray2DIH(const int8_t* arr, const int* dims);
void printArray1DIH(const int8_t* arr, const int len);

// void printArray4DF(const float* arr, const int* dims);
// void printArray3DF(const float* arr, const int* dims);
// void printArray2DF(const float* arr, const int* dims);
// void printArray1DF(const float* arr, const int len);

int get_label(const int8_t model_output_data[], const int model_output_len);

void dummy();

#endif