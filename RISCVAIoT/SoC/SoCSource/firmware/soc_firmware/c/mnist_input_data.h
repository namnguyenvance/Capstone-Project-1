#ifndef MNIST_INPUT_DATA_H
#define MNIST_INPUT_DATA_H

#include <stdint.h>

extern const int    model_input_dims[];
extern const int    number_of_test;
extern const int8_t test_labels[];
extern const int8_t test_images[][28 * 28 * 1];

#endif