# Paths relative to MyTinyMobileNetSoC. Explicit synthesis-only manifest.
# my_soc instantiates the seven modules below. picorv32.v also defines its
# enabled iterative PCPI multiplier; no separate multiplier source is needed.
set rtl_sources [list \
    my_soc.v \
    picorv32.v \
    simpleuart.v \
    my_accel.v \
    my_conv_accel.v \
    my_quant_accel.v \
    my_dw_conv_accel.v \
    my_pw_conv_accel.v \
]
