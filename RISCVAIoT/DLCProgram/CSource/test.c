#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define TENSOR_SIZE 4

// Util functions
// int32_t MaskIfNonZero(int32_t a) {
//     static const int32_t zero = 0;
//     return a ? ~(zero) : zero;
// }

// int32_t ShiftRight(int32_t a, uint8_t offset) {
//     return a >> offset;
// }

// int32_t BitAnd(int32_t a, int32_t b) {
//     return a & b;
// }

// Feature functions
int32_t SaturatingRoundingDoublingHighMul(int32_t a, int32_t b) {
    int64_t a_64 = a;
    printf("a_64 = %d\n", a_64);
    int64_t b_64 = b;
    printf("b_64 = %d\n", b_64);
    int64_t ab_64 = a_64 * b_64;
    printf("ab_64 = %d\n", ab_64);
    int32_t nudge = ab_64 >= 0 ? (1 << 30) : (1 - (1 << 30));
    printf("nudge = %d\n", nudge);
    return (int32_t)((ab_64 + nudge) / (1LL << 31));
}

// int32_t RoundingDivideByPOT(int32_t x, uint8_t exponent) {
//     const int32_t mask = (1LL << exponent) - 1;
//     const int32_t zero = 0;
//     const int32_t one = 1;
//     const int32_t remainder = BitAnd(x, mask);
//     const int32_t threshold = ShiftRight(mask, 1) + BitAnd(MaskIfNonZero(x < zero), one);
//     return ShiftRight(x, exponent) + BitAnd(MaskIfNonZero(remainder > threshold), one);
// }

// Quantization function
void QuantizeTensor(const float input[TENSOR_SIZE][TENSOR_SIZE], 
                    int32_t quantized[TENSOR_SIZE][TENSOR_SIZE], 
                    float f_min, float f_max, int bit_width) {
    // Calculate scale
    float scale = (f_max - f_min) / ((1 << bit_width) - 1);
    printf("scale = %f\n", scale);
    int32_t scale_fixed = (int32_t)(scale * (1 << 31));  // Fixed-point scale
    printf("scale_fixed = %d\n", scale_fixed);

    // Quantize each element
    for (int i = 0; i < TENSOR_SIZE; i++) {
        for (int j = 0; j < TENSOR_SIZE; j++) {
            // Map input to quantized value
            float f = input[i][j];
            float q_float = (f - f_min) / scale;
            printf("q_float = %f\n", q_float);
            int32_t q_int = (int32_t)round(q_float);

            // Apply SaturatingRoundingDoublingHighMul for precision
            quantized[i][j] = SaturatingRoundingDoublingHighMul(q_int, scale_fixed);
        }
    }
}

int main() {
    // Input tensor
    float input[TENSOR_SIZE][TENSOR_SIZE] = {
        {-1.2, 0.3, 2.7, -0.8},
        {1.5, -2.1, 0.0, 1.9},
        {3.2, -3.5, 2.4, -0.2},
        {-1.8, 0.5, 1.1, -0.6}
    };

    // Output quantized tensor
    int32_t quantized[TENSOR_SIZE][TENSOR_SIZE];

    // Quantization parameters
    float f_min = -3.5; // Minimum value in the tensor
    float f_max = 3.2;  // Maximum value in the tensor
    int bit_width = 8;  // Quantization to 8-bit

    // Perform quantization
    QuantizeTensor(input, quantized, f_min, f_max, bit_width);

    // Print results
    printf("Quantized Tensor:\n");
    for (int i = 0; i < TENSOR_SIZE; i++) {
        for (int j = 0; j < TENSOR_SIZE; j++) {
            printf("%d ", quantized[i][j]);
        }
        printf("\n");
    }

    return 0;
}
