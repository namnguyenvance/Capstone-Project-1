#include "al_accel_cfg.h"
#include "pico_io.h"

void set_al_accel_mode(uint32_t mode) {
    al_accel_cfg_reg = mode;
}

uint32_t get_al_accel_mode() {
	return al_accel_cfg_reg;
}

void run_and_wait_al_accel() {
    al_accel_cfg_reg = RUN;
	while (al_accel_cfg_reg != FINISH);
}

void config_al_accel_CONV_layer(
	const int8_t* input_data , const int* input_dims , int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
	int32_t* ps_data		 ,
    int stride_width		 , int stride_height, 
    const int32_t* output_multiplier, const int8_t* output_shift,
	int8_t act_funct_type
) {
	al_accel_reg_0 = (uint32_t)input_data;
	al_accel_reg_1 = (uint32_t)filter_data;
	al_accel_reg_2 = (uint32_t)output_data;
	al_accel_reg_3 = (uint32_t)bias_data;
	al_accel_reg_4 = (uint32_t)ps_data;
	al_accel_reg_5 = ((stride_height  << 12) & 0x0000f000) 
				   | ((stride_width   <<  8) & 0x00000f00) 
				   | ((act_funct_type <<  4) & 0x000000f0) 
				   | ((CONV                ) & 0x0000000f);
	al_accel_reg_6 = ((filter_dims[1] << 16) & 0xffff0000) 
				   | ((filter_dims[0]      ) & 0x0000ffff);
	al_accel_reg_7 = ((filter_dims[3] << 16) & 0xffff0000) 
	               | ((filter_dims[2] 	   ) & 0x0000ffff);
	al_accel_reg_8 = ((input_dims[1]  << 16) & 0xffff0000) 
	               | ((input_dims[0]	   ) & 0x0000ffff);
	al_accel_reg_9 = ((output_dims[1] << 16) & 0xffff0000) 
	               | ((output_dims[0]      ) & 0x0000ffff);
	al_accel_reg_10 = (((output_dims[0] * output_dims[1]) << 16) & 0xffff0000) 
	                | (((input_dims[0]  * input_dims[1])       ) & 0x0000ffff);

	al_accel_reg_11 = filter_dims[0] * filter_dims[1] * filter_dims[2];
	
	for (int i = 0; i < filter_dims[3]; i++) {
		al_accel_reg_12 = i;
		al_accel_reg_13 = output_multiplier[i];
		al_accel_reg_14 = output_shift[i];
	}

	al_accel_reg_15 = input_offset;
	al_accel_reg_16 = output_offset;
}

void config_al_accel_DENSE_layer( 
	const int8_t* input_data , const int* input_dims, int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset,
	int32_t* ps_data		 ,
    const int32_t output_multiplier, const int8_t output_shift,
	int8_t act_funct_type
) {
	al_accel_reg_0 = (uint32_t)input_data;
	al_accel_reg_1 = (uint32_t)filter_data;
	al_accel_reg_2 = (uint32_t)output_data;
	al_accel_reg_3 = (uint32_t)bias_data;
	al_accel_reg_4 = (uint32_t)ps_data;
	al_accel_reg_5 = ((act_funct_type <<  4) & 0x000000f0) 
				   | ((DENSE               ) & 0x0000000f);
	al_accel_reg_6 = ((filter_dims[1] << 16) & 0xffff0000) 
				   | ((filter_dims[0]      ) & 0x0000ffff);
	al_accel_reg_7 = 0;
	al_accel_reg_8 = ((input_dims[0]	   ) & 0x0000ffff);
	al_accel_reg_9 = ((output_dims[0]      ) & 0x0000ffff);
	al_accel_reg_10 = (((output_dims[0]) << 16) & 0xffff0000) 
	                | (((input_dims[0])       ) & 0x0000ffff);
	al_accel_reg_11 = filter_dims[0] * filter_dims[1];
	al_accel_reg_12 = 0;
	al_accel_reg_13 = output_multiplier;
	al_accel_reg_14 = output_shift;
	al_accel_reg_15 = input_offset;
	al_accel_reg_16 = output_offset;
}


void config_al_accel_POOL_layer(
	const int8_t* input_data, const int* input_dims , 
    int8_t* output_data     , const int* output_dims,
	int filter_width		, int filter_height,
    int stride_width		, int stride_height
) {
	al_accel_reg_0 = (uint32_t)input_data;
	al_accel_reg_1 = 0;
	al_accel_reg_2 = (uint32_t)output_data;
	al_accel_reg_3 = 0;
	al_accel_reg_4 = 0;
	al_accel_reg_5 = ((stride_height  << 12) & 0x0000f000) 
				   | ((stride_width   <<  8) & 0x00000f00) 
				   | ((POOL                ) & 0x0000000f);
	al_accel_reg_6 = ((filter_height << 16 ) & 0xffff0000) 
				   | ((filter_width        ) & 0x0000ffff);
	al_accel_reg_7 = (input_dims[2]          & 0x0000ffff);
	al_accel_reg_8 = ((input_dims[1]  << 16) & 0xffff0000) 
	               | ((input_dims[0]	   ) & 0x0000ffff);
	al_accel_reg_9 = ((output_dims[1] << 16) & 0xffff0000) 
	               | ((output_dims[0]      ) & 0x0000ffff);
	al_accel_reg_10 = (((output_dims[0] * output_dims[1]) << 16) & 0xffff0000) 
	                | (((input_dims[0]  * input_dims[1] )      ) & 0x0000ffff);
	// al_accel_reg_11 = 0; 
	al_accel_reg_11 = (input_dims[0] - filter_width) % stride_width; 
	al_accel_reg_12 = 0;
	al_accel_reg_13 = 0;
	al_accel_reg_14 = 0;
	al_accel_reg_15 = 0;
	al_accel_reg_16 = 0;
}


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
) {
	al_accel_reg_0 = (uint32_t)input_data;
	al_accel_reg_1 = (uint32_t)filter_data;
	al_accel_reg_2 = (uint32_t)output_data;
	al_accel_reg_3 = (uint32_t)bias_data;
	al_accel_reg_4 = (uint32_t)ps_data;
	al_accel_reg_5 = ((stride_height  << 12) & 0x0000f000) 
				   | ((stride_width   <<  8) & 0x00000f00) 
				   | ((act_funct_type <<  4) & 0x000000f0) 
				   | ((MIXED                ) & 0x0000000f);
	al_accel_reg_6 = ((filter_dims[1] << 16) & 0xffff0000) 
				   | ((filter_dims[0]      ) & 0x0000ffff);
	al_accel_reg_7 = ((filter_dims[3] << 16) & 0xffff0000) 
	               | ((filter_dims[2] 	   ) & 0x0000ffff);
	al_accel_reg_8 = ((input_dims[1]  << 16) & 0xffff0000) 
	               | ((input_dims[0]	   ) & 0x0000ffff);
	al_accel_reg_9 = ((output_conv_dims[1] << 16) & 0xffff0000) 
	               | ((output_conv_dims[0]      ) & 0x0000ffff);
	al_accel_reg_10 = (((output_conv_dims[0] * output_conv_dims[1]) << 16) & 0xffff0000) 
	                | (((input_dims[0]  * input_dims[1])       ) & 0x0000ffff);

	al_accel_reg_11 = filter_dims[0] * filter_dims[1] * filter_dims[2];
	
	for (int i = 0; i < filter_dims[3]; i++) {
		al_accel_reg_12 = i;
		al_accel_reg_13 = output_multiplier[i];
		al_accel_reg_14 = output_shift[i];
	}

	al_accel_reg_15 = input_offset;
	al_accel_reg_16 = output_offset;

	al_accel_reg_17 = ((output_dims[1] << 16) & 0xffff0000) 
	               | ((output_dims[0]      ) & 0x0000ffff);

	al_accel_reg_18 = 	output_dims[0] * output_dims[1];
}



