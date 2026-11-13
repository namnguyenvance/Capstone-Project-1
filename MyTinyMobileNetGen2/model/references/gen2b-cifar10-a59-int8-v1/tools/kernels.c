/* Gen 2 host reference. CHW activations, OIHW convolution weights.
 * Host-only: uses int64 division; not RV32 firmware. No MMIO or RTL. */
#include <stdint.h>
#include <limits.h>
#include <stddef.h>
static int32_t sat(int64_t x) {
    return x > INT32_MAX ? INT32_MAX : x < INT32_MIN ? INT32_MIN : (int32_t)x;
}
/* Q31 double rounding. Positive shift = right shift (Gen 1 convention).
 * Left shifts saturate before high multiply. High-mul ties toward +infinity;
 * power-of-two division ties away from zero. No signed shifts or overflow. */
int32_t g2_requant(int32_t x, int32_t m, int shift) {
    if (shift < -30 || shift > 31 || m < 0) return 0; /* invalid metadata */
    if (shift < 0) x = sat((int64_t)x * (INT64_C(1) << -shift));
    int64_t p = (int64_t)x * m;
    int64_t nudge = p >= 0 ? INT64_C(1073741824) : -INT64_C(1073741823);
    int32_t y = sat((p + nudge) / INT64_C(2147483648));
    if (shift > 0) {
        int64_t d = INT64_C(1) << shift;
        int64_t a = y < 0 ? -(int64_t)y : y;
        y = (int32_t)((a + d / 2) / d) * (y < 0 ? -1 : 1);
    }
    return y;
}
static int8_t finish(int32_t acc, int32_t m, int shift, int zp, int lo, int hi) {
    int64_t q = (int64_t)g2_requant(acc, m, shift) + zp;
    return (int8_t)(q < lo ? lo : q > hi ? hi : q);
}
/* Caller validates dimensions, scales and int32 accumulation bounds.
 * dw=1 requires Cout=Cin, depth multiplier 1; weights C,KH,KW.
 * Optional traces distinguish pre-bias, post-bias, post-requant stages. */
void g2_conv(const int8_t *x, const int8_t *w, const int32_t *bias,
             int h, int width, int ci, int co, int kh, int kw,
             int stride, int pt, int pl, int oh, int ow, int iz, int oz,
             const int32_t *mult, const int32_t *shift, int lo, int hi, int dw,
             int8_t *out, int32_t *raw, int32_t *biased, int32_t *scaled) {
    for (int o=0; o<co; ++o) for (int y=0; y<oh; ++y) for (int z=0; z<ow; ++z) {
        int32_t acc=0;
        for (int c=0; c<(dw ? 1 : ci); ++c)
            for (int ky=0; ky<kh; ++ky) for (int kx=0; kx<kw; ++kx) {
                int iy=y*stride+ky-pt, ix=z*stride+kx-pl;
                if (iy<0 || iy>=h || ix<0 || ix>=width) continue;
                int ic=dw ? o : c;
                size_t wi=dw ? (size_t)((o*kh+ky)*kw+kx) :
                    (size_t)(((o*ci+c)*kh+ky)*kw+kx);
                acc += ((int32_t)x[(ic*h+iy)*width+ix]-iz)*(int32_t)w[wi];
            }
        size_t j=(size_t)((o*oh+y)*ow+z);
        if (raw) raw[j]=acc;
        acc += bias[o];
        if (biased) biased[j]=acc;
        if (scaled) scaled[j]=g2_requant(acc,mult[o],shift[o]);
        out[j]=finish(acc,mult[o],shift[o],oz,lo,hi);
    }
}
void g2_mean(const int8_t *x, int spatial, int channels, int iz, int oz,
             int32_t mult, int shift, int8_t *out) {
    for (int c=0; c<channels; ++c) {
        int32_t sum=0;
        for (int p=0;p<spatial;++p) sum += (int32_t)x[c*spatial+p]-iz;
        /* Multiplier includes 1/spatial; round only after summation. */
        out[c]=finish(sum,mult,shift,oz,-128,127);
    }
}
void g2_fc(const int8_t *x, const int8_t *w, const int32_t *bias,
           int ci, int co, int iz, int oz, const int32_t *m,
           const int32_t *s, int8_t *out) {
    for (int o=0;o<co;++o) {
        int32_t acc=bias[o];
        for (int c=0;c<ci;++c) acc += ((int32_t)x[c]-iz)*w[o*ci+c];
        out[o]=finish(acc,m[o],s[o],oz,-128,127);
    }
}
