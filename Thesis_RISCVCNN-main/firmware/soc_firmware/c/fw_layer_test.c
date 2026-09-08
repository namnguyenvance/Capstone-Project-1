#include "fw_layer_test.h"

/* Test Layer without Al Accel */
void testFullyConnected2D_NoAccel(
    const int8_t* input_data , const int* input_dims , int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift,
    int8_t act_funct_type
) {
	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

    reg_leds = 255;

    // Test right here !!!
	FullyConnected2D_TFLM(
        input_data  , input_dims , input_offset,
        filter_data , filter_dims, 
        bias_data   , bias_dims, 
        output_data , output_dims, output_offset,
        output_multiplier, output_shift,
        -999999, 99999
    );

    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray1DI(output_data, output_dims[0]);
}

void testConv2D_NoAccel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int8_t act_funct_type
) {
    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

    reg_leds = 255;

    // Test right here !!!
    Conv2D_TFLM(
        input_data, input_dims, input_offset,
        filter_data, filter_dims,
        bias_data, bias_dims, 
        stride_width, stride_height,
        0, 0, 
        output_data, output_dims, output_offset,
        output_multiplier, output_shift,
        0, 9999999
    );

    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}

void testMaxPool_NoAccel(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims
) {
    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

    reg_leds = 255;

    // Test right here !!!
    MaxPool_TFLM(
        input_data, input_dims,
        stride_width, stride_height, 
        0, 0,
        filter_width, filter_height,
        output_data, output_dims,
        0, 9999999
    );
    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}
/****************************/

void testMixed2D_NoAccel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height,
    int8_t* output_conv_data , const int* output_conv_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int8_t act_funct_type
) {
    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

    reg_leds = 255;

    // Test right here !!!
    Conv2D_TFLM(
        input_data, input_dims, input_offset,
        filter_data, filter_dims,
        bias_data, bias_dims, 
        stride_width, stride_height,
        0, 0, 
        output_conv_data, output_conv_dims, output_offset,
        output_multiplier, output_shift,
        0, 9999999
    );

    MaxPool_TFLM(
        output_conv_data, output_conv_dims,
        2, 2, 
        0, 0,
        2, 2,
        output_data, output_dims,
        0, 9999999
    );

    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}
/****************************/

/****************************/
/* Test Layer with Al Accel */
void testFullyConnected2D_Accel(
    const int8_t* input_data , const int* input_dims , int32_t input_offset, 
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t output_multiplier, int8_t output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
) {
	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;



    reg_leds = 255;

    // Test right here !!!
	set_al_accel_mode(RESET);
    set_al_accel_mode(CONFIG);
	config_al_accel_DENSE_layer(
		input_data	, input_dims, input_offset,
		filter_data	, filter_dims,
		bias_data   , bias_dims,
		output_data , output_dims, output_offset,
		ps_data,
		output_multiplier, output_shift,
		act_funct_type
	);
    __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

	run_and_wait_al_accel();
    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray1DI(output_data, output_dims[0]);
}

void testConv2D_Accel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height, 
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
) {

    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

    reg_leds = 255;

    // Test right here !!!
    set_al_accel_mode(RESET); 

    set_al_accel_mode(CONFIG);
    
	config_al_accel_CONV_layer(
		input_data	, input_dims, input_offset,
		filter_data	, filter_dims,
		bias_data	, bias_dims,
		output_data	, output_dims, output_offset,
		ps_data,
		stride_width, stride_height,
		output_multiplier, output_shift,
		act_funct_type
	);

    __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

	run_and_wait_al_accel();
    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}

void testMaxPool_Accel(
    const int8_t* input_data, const int* input_dims,
    int stride_width, int stride_height, 
    int filter_width, int filter_height,
    int8_t* output_data     , const int* output_dims
) {
    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

    reg_leds = 255;

    // Test right here !!!
    set_al_accel_mode(RESET);

    set_al_accel_mode(CONFIG);

	config_al_accel_POOL_layer(
		input_data	, input_dims,
		output_data	, output_dims,
		filter_width, filter_height,
		stride_width, stride_height
	);

	run_and_wait_al_accel();
    
    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}


void testMixed2D_Accel(
    const int8_t* input_data , const int* input_dims, int32_t input_offset,
    const int8_t* filter_data, const int* filter_dims,
    const int32_t* bias_data  , const int* bias_dims, 
    int stride_width, int stride_height,
    const int* output_conv_dims,
    int8_t* output_data      , const int* output_dims, int32_t output_offset, 
    int32_t* output_multiplier, int8_t* output_shift,
    int32_t* ps_data		 , int8_t act_funct_type
) {

    uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;



    reg_leds = 255;

    // Test right here !!!
    set_al_accel_mode(RESET); 

    set_al_accel_mode(CONFIG);
    
	config_al_accel_MIXED_layer(
		input_data	, input_dims, input_offset,
		filter_data	, filter_dims,
		bias_data	, bias_dims,
        output_conv_dims,
		output_data	, output_dims, output_offset,
		ps_data,
		stride_width, stride_height,
		output_multiplier, output_shift,
		act_funct_type
	);

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    
	run_and_wait_al_accel();
    // *********** //

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

    print("BENCHMARK\n");
	print("Cycles: 0x");
	print_hex(cycles_end - cycles_begin, 8);
	putchar('\n');

	print("Instns: 0x");
	print_hex(instns_end - instns_begin, 8);
	putchar('\n');    

    print("LAYER RESULT\n");
    printArray3DI(output_data, output_dims);
}
/****************************/


