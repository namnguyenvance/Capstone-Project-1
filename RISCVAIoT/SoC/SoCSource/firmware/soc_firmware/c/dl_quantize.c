#include "dl_quantize.h"

/* Util function */ 
int32_t MaskIfNonZero(
    int32_t a
) {
    static const int32_t zero = 0;
    return a ? ~(zero) : zero;
}

int32_t ShiftRight(
    int32_t a, 
    uint8_t offset
) {
    return a >> offset;
}

int32_t BitAnd(
    int32_t a, 
    int32_t b
) {
  return a & b;
}

/* Feature functions */ 
int32_t SaturatingRoundingDoublingHighMul(
    int32_t a,
    int32_t b
) {
    bool overflow = a == b && a == INT32_MAX;
    int64_t a_64 = a;
    int64_t b_64 = b;
    int64_t ab_64 = a_64 * b_64;
    int32_t nudge = ab_64 >= 0 ? (1 << 30) : (1 - (1 << 30));
    int32_t ab_x2_high32 =
        (int32_t)((ab_64 + nudge) / (1ll << 31));
    return overflow ? INT32_MAX : ab_x2_high32;
}

int32_t RoundingDivideByPOT(
    int32_t x, 
    uint8_t exponent
) {
    const int32_t mask = (int32_t)((1ll << exponent) - 1);
    const int32_t zero = (int32_t)(0);
    const int32_t one  = (int32_t)(1);
    const int32_t remainder = BitAnd(x, mask);
    const int32_t threshold = ShiftRight(mask, 1) + BitAnd(MaskIfNonZero(x < zero), one);
    return ShiftRight(x, exponent) + BitAnd(MaskIfNonZero(remainder > threshold), one);
}

