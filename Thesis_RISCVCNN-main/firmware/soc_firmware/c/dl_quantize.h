#ifndef DL_QUANTIZE_H
#define DL_QUANTIZE_H

#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

/* Util function */ 
int32_t MaskIfNonZero(
    int32_t a
);
int32_t ShiftRight(
    int32_t a, 
    uint8_t offset
);
int32_t BitAnd(
    int32_t a, 
    int32_t b
);

/* Feature functions */ 
int32_t SaturatingRoundingDoublingHighMul(
    int32_t a,
    int32_t b
);

int32_t RoundingDivideByPOT(
    int32_t x, 
    uint8_t exponent
);

#endif