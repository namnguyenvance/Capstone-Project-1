/* Generated automatically by generate_test_data.py */
#ifndef CONV_DATA_H
#define CONV_DATA_H

#define IMG_ROWS 5
#define IMG_COLS 5
#define KERNEL_SIZE 3
#define OUT_ROWS 3
#define OUT_COLS 3

const int input_matrix[25] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 };
const int conv_kernel[9] = { 1, 0, -1, 2, 0, -2, 1, 0, -1 };
const int golden_output[9] = { -8, -8, -8, -8, -8, -8, -8, -8, -8 };

#endif // CONV_DATA_H