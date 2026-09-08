#ifndef AL_ACCEL_CFG_H
#define AL_ACCEL_CFG_H

#include <stdint.h>
#include <stdbool.h>

#define al_accel_cfg_reg    (*(volatile uint32_t*)0x02001050)
#define al_accel_reg_0      (*(volatile uint32_t*)0x02001000)
#define al_accel_reg_1      (*(volatile uint32_t*)0x02001004)
#define al_accel_reg_2      (*(volatile uint32_t*)0x02001008)
#define al_accel_reg_3      (*(volatile uint32_t*)0x0200100C)
#define al_accel_reg_4      (*(volatile uint32_t*)0x02001010)
#define al_accel_reg_5      (*(volatile uint32_t*)0x02001014)
#define al_accel_reg_6      (*(volatile uint32_t*)0x02001018)
#define al_accel_reg_7      (*(volatile uint32_t*)0x0200101C)
#define al_accel_reg_8      (*(volatile uint32_t*)0x02001020)
#define al_accel_reg_9      (*(volatile uint32_t*)0x02001024)
#define al_accel_reg_10     (*(volatile uint32_t*)0x02001028)
#define al_accel_reg_11     (*(volatile uint32_t*)0x0200102C)
#define al_accel_reg_12     (*(volatile uint32_t*)0x02001030)
#define al_accel_reg_13     (*(volatile uint32_t*)0x02001034)
#define al_accel_reg_14     (*(volatile uint32_t*)0x02001038)
#define al_accel_reg_15     (*(volatile uint32_t*)0x0200103C)
#define al_accel_reg_16     (*(volatile uint32_t*)0x02001040)
#define al_accel_reg_17     (*(volatile uint32_t*)0x02001044)
#define al_accel_reg_18     (*(volatile uint32_t*)0x02001048)

// Working Mode
#define RESET   0
#define CONFIG  1
#define RUN     2
#define FINISH  3

// Layer 
#define CONV    0
#define DENSE   1
#define MIXED   2
#define POOL    3

#define RELU    0
#define RELU6   1
#define SIGMOID 2
#define TANH    3
#define NO_FUNC 4

void set_al_accel_mode(uint32_t mode);
void run_and_wait_al_accel();

void config_al_accel_CONV_layer(
	const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
	int32_t* ps_data		 ,
    int stride_width		 , int stride_height, 
    const int32_t* output_multiplier, const int8_t* output_shift,
	int8_t act_funct_type
);

void config_al_accel_DENSE_layer( 
	const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
	int32_t* ps_data		 ,
    const int32_t output_multiplier, const int8_t output_shift,
	int8_t act_funct_type
); 

void config_al_accel_POOL_layer(
	const int8_t* input_data, const int* input_dims , 
    int8_t* output_data     , const int* output_dims,
	int filter_width		, int filter_height,
    int stride_width		, int stride_height
);

void config_al_accel_MIXED_layer(
	const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims,
	const int* output_conv_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
	int32_t* ps_data		 ,
    int stride_width		 , int stride_height, 
    const int32_t* output_multiplier, const int8_t* output_shift,
	int8_t act_funct_type
);




#endif