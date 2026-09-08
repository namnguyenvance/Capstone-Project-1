#include "fw_model_test.h"

// 2 CONV Layer model
/* Test Layer without Al Accel */
void testInference_CNNNEW_MNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    const int32_t cnnnew_conv0_output_multiplier[], const int8_t cnnnew_conv0_output_shift[],
    const int32_t cnnnew_conv1_output_multiplier[], const int8_t cnnnew_conv1_output_shift[],
    const int32_t cnnnew_dense0_output_multiplier, const int8_t  cnnnew_dense0_output_shift,

    const int cnnnew_conv0_kernel_dims[], const int8_t cnnnew_conv0_kernel_data[],
    const int cnnnew_conv0_bias_dims[], const int32_t cnnnew_conv0_bias_data[],

    const int cnnnew_conv1_kernel_dims[], const int8_t cnnnew_conv1_kernel_data[],
    const int cnnnew_conv1_bias_dims[], const int32_t cnnnew_conv1_bias_data[],


    const int cnnnew_dense0_weight_dims[], const int8_t cnnnew_dense0_weight_data[],
    const int cnnnew_dense0_bias_dims[], const int32_t cnnnew_dense0_bias_data[],

    const int cnnnew_conv0_output_dims[], int8_t cnnnew_conv0_output_data[],
    const int cnnnew_pool0_output_dims[], int8_t cnnnew_pool0_output_data[],
    const int cnnnew_conv1_output_dims[], int8_t cnnnew_conv1_output_data[],
    const int cnnnew_pool1_output_dims[], int8_t cnnnew_pool1_output_data[],
    const int cnnnew_dense0_input_dims[], 
    const int cnnnew_dense0_output_dims[], int8_t cnnnew_dense0_output_data[]
) {
    int8_t    input_image[28 * 28 * 1];

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    reg_leds = 255;

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        print("TEST CASE "); print_dec(test_idx); putchar('\n');

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* READ INPUT PART */
        // print("IFM\n");
        // printArray3DI(test_images[test_idx], model_input_dims);
        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] = test_images[test_idx][offset_1 + offset_0 + width];
            }
        }
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* READ INPUT PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* COMPUTATION PART */

        Conv2D_TFLM(
            input_image, model_input_dims, 128,
            cnnnew_conv0_kernel_data, cnnnew_conv0_kernel_dims,
            cnnnew_conv0_bias_data,   cnnnew_conv0_bias_dims,
            1, 1,
            0, 0,
            cnnnew_conv0_output_data, cnnnew_conv0_output_dims, 128,
            cnnnew_conv0_output_multiplier, cnnnew_conv0_output_shift,
            0, 999999
        );
        // print("CONV_0\n");
        // printArray3DI(cnnnew_conv0_output_data, cnnnew_conv0_output_dims);

        MaxPool_TFLM(
            cnnnew_conv0_output_data, cnnnew_conv0_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims,
            0, 999999
        );
        // print("POOL_0\n");
        // printArray3DI(cnnnew_pool0_output_data, cnnnew_pool0_output_dims);

        Conv2D_TFLM(
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims, 128,
            cnnnew_conv1_kernel_data, cnnnew_conv1_kernel_dims,
            cnnnew_conv1_bias_data,   cnnnew_conv1_bias_dims,
            1, 1,
            0, 0,
            cnnnew_conv1_output_data, cnnnew_conv1_output_dims, 128,
            cnnnew_conv1_output_multiplier, cnnnew_conv1_output_shift,
            0, 999999
        );
        // print("CONV_1\n");
        // printArray3DI(cnnnew_conv1_output_data, cnnnew_conv1_output_dims);

        MaxPool_TFLM(
            cnnnew_conv1_output_data, cnnnew_conv1_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnnnew_pool1_output_data, cnnnew_pool1_output_dims,
            0, 999999
        );
        // print("POOL_1\n");
        // printArray3DI(cnnnew_pool1_output_data, cnnnew_pool1_output_dims);

        // print("INPUT\n");
        // printArray1DI(cnnnew_pool1_output_data, cnnnew_dense0_input_dims[0]);
        // print("WEIGHT\n");
        // const int cnnnew_dense0_new_weight_dims[] = {800, 256};
        // printArray2DI(cnnnew_dense0_weight_data, cnnnew_dense0_new_weight_dims);
        // print("BIAS");
        // printArray1DI(cnnnew_dense0_bias_data, cnnnew_dense0_bias_dims[0]);
        FullyConnected2D_TFLM(
            cnnnew_pool1_output_data,  cnnnew_dense0_input_dims, 128,
            cnnnew_dense0_weight_data, cnnnew_dense0_weight_dims,
            cnnnew_dense0_bias_data,   cnnnew_dense0_bias_dims,
            cnnnew_dense0_output_data, cnnnew_dense0_output_dims, -24, 
            cnnnew_dense0_output_multiplier, cnnnew_dense0_output_shift,
            -999999, 999999
        );
        // print("DENSE_0\n");
        // printArray1DI(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* COMPUTATION PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
        print("MODEL RESULT\n");
        int max_idx = get_label(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* PRINT RESULT PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');
    }
    reg_leds = 0;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    // print("BENCHMARK\n");
	// print("Cycles: BEGIN 0x");
    // print_hex(high_cycles_begin, 8);
	// print_hex(cycles_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_cycles_end, 8);
	// print_hex(cycles_end, 8);
	// putchar('\n');

    // print("Instns: BEGIN 0x");
    // print_hex(high_instns_begin, 8);
	// print_hex(instns_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_instns_end, 8);
	// print_hex(instns_end, 8);
	// putchar('\n');

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');
}


/* Test Model with Al Accel */
void testInference_CNNNEW_MNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    int32_t cnnnew_conv0_ps_data[], int32_t cnnnew_conv1_ps_data[], 
    int32_t cnnnew_dense0_ps_data[],

    const int32_t cnnnew_conv0_output_multiplier[], const int8_t cnnnew_conv0_output_shift[],
    const int32_t cnnnew_conv1_output_multiplier[], const int8_t cnnnew_conv1_output_shift[],
    const int32_t cnnnew_dense0_output_multiplier, const int8_t  cnnnew_dense0_output_shift,

    const int cnnnew_conv0_kernel_dims[], const int8_t cnnnew_conv0_kernel_data[],
    const int cnnnew_conv0_bias_dims[], const int32_t cnnnew_conv0_bias_data[],

    const int cnnnew_conv1_kernel_dims[], const int8_t cnnnew_conv1_kernel_data[],
    const int cnnnew_conv1_bias_dims[], const int32_t cnnnew_conv1_bias_data[],


    const int cnnnew_dense0_weight_dims[], const int8_t cnnnew_dense0_weight_data[],
    const int cnnnew_dense0_bias_dims[], const int32_t cnnnew_dense0_bias_data[],

    const int cnnnew_conv0_output_dims[], int8_t cnnnew_conv0_output_data[],
    const int cnnnew_pool0_output_dims[], int8_t cnnnew_pool0_output_data[],
    const int cnnnew_conv1_output_dims[], int8_t cnnnew_conv1_output_data[],
    const int cnnnew_pool1_output_dims[], int8_t cnnnew_pool1_output_data[],
    const int cnnnew_dense0_input_dims[], 
    const int cnnnew_dense0_output_dims[], int8_t cnnnew_dense0_output_data[]
) {
    const int new_model_input_dims[] = {28, 28, 3};
    int8_t    input_image[28 * 28 * 1];

    uint32_t total_input_cycles = 0;
    uint32_t total_comps_cycles = 0;
    uint32_t total_output_cycles = 0;

    uint32_t total_input_ins = 0;
    uint32_t total_comps_ins = 0;
    uint32_t total_output_ins = 0;

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        print("TEST CASE "); print_dec(test_idx); putchar('\n');

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* READ INPUT PART */
        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] = test_images[test_idx][offset_1 + offset_0 + width];
            }
        }

        // printArray3DI(input_image, model_input_dims);

        /*********************/
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));
        
        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins += (instns_end - instns_begin);

        // print("/* READ INPUT PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');


        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* COMPUTATION PART */

        // First CONV Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_CONV_layer(
            input_image, new_model_input_dims, 128,
            cnnnew_conv0_kernel_data, cnnnew_conv0_kernel_dims,
            cnnnew_conv0_bias_data, cnnnew_conv0_bias_dims,
            cnnnew_conv0_output_data, cnnnew_conv0_output_dims, 128,
            cnnnew_conv0_ps_data,
            1, 1,
            cnnnew_conv0_output_multiplier, cnnnew_conv0_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        run_and_wait_al_accel();
        // print("CONV_0\n");
        // printArray3DI(cnnnew_conv0_output_data, cnnnew_conv0_output_dims);
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // First POOL Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_POOL_layer(
            cnnnew_conv0_output_data, cnnnew_conv0_output_dims,
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims,
            2, 2,
            2, 2
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

	    run_and_wait_al_accel();
        // print("POOL_0\n");
        // printArray3DI(cnnnew_pool0_output_data, cnnnew_pool0_output_dims);
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // Second CONV Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_CONV_layer(
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims, 128,
            cnnnew_conv1_kernel_data, cnnnew_conv1_kernel_dims,
            cnnnew_conv1_bias_data, cnnnew_conv1_bias_dims,
            cnnnew_conv1_output_data, cnnnew_conv1_output_dims, 128,
            cnnnew_conv1_ps_data,
            1, 1,
            cnnnew_conv1_output_multiplier, cnnnew_conv1_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();
        // print("CONV_1\n");
        // printArray3DI(cnnnew_conv1_output_data, cnnnew_conv1_output_dims);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // Second POOL Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_POOL_layer(
            cnnnew_conv1_output_data, cnnnew_conv1_output_dims,
            cnnnew_pool1_output_data, cnnnew_pool1_output_dims,
            2, 2,
            2, 2
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
	    run_and_wait_al_accel();
        // print("POOL_1\n");
        // printArray3DI(cnnnew_pool1_output_data, cnnnew_pool1_output_dims);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // First DENSE Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_DENSE_layer(
            cnnnew_pool1_output_data, cnnnew_dense0_input_dims, 128,
            cnnnew_dense0_weight_data, cnnnew_dense0_weight_dims,
            cnnnew_dense0_bias_data, cnnnew_dense0_bias_dims,
            cnnnew_dense0_output_data , cnnnew_dense0_output_dims, -24,
            cnnnew_dense0_ps_data,
            cnnnew_dense0_output_multiplier, cnnnew_dense0_output_shift,
            NO_FUNC
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();
        // print("DENSE_0\n");
        // printArray1DI(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');
        /*********************/

        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        // total_comps_cycles += (cycles_end - cycles_begin);
        // total_comps_ins += (instns_end - instns_begin);

        // print("/* COMPUTATION PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
        print("MODEL RESULT\n");
        int max_idx = get_label(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_output_cycles += (cycles_end - cycles_begin);
        total_output_ins += (instns_end - instns_begin);

        // print("/* PRINT RESULT PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');
    }

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    // print("BENCHMARK\n");
	// print("Cycles: BEGIN 0x");
    // print_hex(high_cycles_begin, 8);
	// print_hex(cycles_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_cycles_end, 8);
	// print_hex(cycles_end, 8);
	// putchar('\n');

    // print("Instns: BEGIN 0x");
    // print_hex(high_instns_begin, 8);
	// print_hex(instns_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_instns_end, 8);
	// print_hex(instns_end, 8);
	// putchar('\n');

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');

    print("TOTAL: \n");
    print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; "); print_dec(total_input_ins); print(" ins\n");
    print("\tComputation: "); print_dec(total_comps_cycles); print(" cycles; "); print_dec(total_comps_ins); print(" ins\n");
    print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; "); print_dec(total_output_ins); print(" ins\n");
}



// 2 CONV Layer
/* Test Layer without Al Accel */
void testInference_CNNMNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
    const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
    const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
    const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

    const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
    const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

    const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
    const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],


    const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
    const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

    const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
    const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

    const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
    const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
    const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
    const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
    const int cnn_dense0_input_dims[], 
    const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
    const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
) {
    int8_t    input_image[28 * 28 * 1];

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    reg_leds = 255;

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        print("TEST CASE "); print_dec(test_idx); putchar('\n');

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* READ INPUT PART */
        // print("IFM\n");
        // printArray3DI(test_images[test_idx], model_input_dims);
        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] = test_images[test_idx][offset_1 + offset_0 + width];
            }
        }
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* READ INPUT PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* COMPUTATION PART */

        Conv2D_TFLM(
            input_image, model_input_dims, 128,
            cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
            cnn_conv0_bias_data,   cnn_conv0_bias_dims,
            1, 1,
            0, 0,
            cnn_conv0_output_data, cnn_conv0_output_dims, 128,
            cnn_conv0_output_multiplier, cnn_conv0_output_shift,
            0, 999999
        );
        // print("CONV_0\n");
        // printArray3DI(cnn_conv0_output_data, cnn_conv0_output_dims);

        MaxPool_TFLM(
            cnn_conv0_output_data, cnn_conv0_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnn_pool0_output_data, cnn_pool0_output_dims,
            0, 999999
        );
        // print("POOL_0\n");
        // printArray3DI(cnn_pool0_output_data, cnn_pool0_output_dims);

        Conv2D_TFLM(
            cnn_pool0_output_data, cnn_pool0_output_dims, 128,
            cnn_conv1_kernel_data, cnn_conv1_kernel_dims,
            cnn_conv1_bias_data,   cnn_conv1_bias_dims,
            1, 1,
            0, 0,
            cnn_conv1_output_data, cnn_conv1_output_dims, 128,
            cnn_conv1_output_multiplier, cnn_conv1_output_shift,
            0, 999999
        );
        // print("CONV_1\n");
        // printArray3DI(cnn_conv1_output_data, cnn_conv1_output_dims);

        MaxPool_TFLM(
            cnn_conv1_output_data, cnn_conv1_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnn_pool1_output_data, cnn_pool1_output_dims,
            0, 999999
        );
        // print("POOL_1\n");
        // printArray3DI(cnn_pool1_output_data, cnn_pool1_output_dims);

        // print("INPUT\n");
        // printArray1DI(cnn_pool1_output_data, cnn_dense0_input_dims[0]);
        // print("WEIGHT\n");
        // const int cnn_dense0_new_weight_dims[] = {800, 256};
        // printArray2DI(cnn_dense0_weight_data, cnn_dense0_new_weight_dims);
        // print("BIAS");
        // printArray1DI(cnn_dense0_bias_data, cnn_dense0_bias_dims[0]);
        FullyConnected2D_TFLM(
            cnn_pool1_output_data,  cnn_dense0_input_dims, 128,
            cnn_dense0_weight_data, cnn_dense0_weight_dims,
            cnn_dense0_bias_data,   cnn_dense0_bias_dims,
            cnn_dense0_output_data, cnn_dense0_output_dims, 128, 
            cnn_dense0_output_multiplier, cnn_dense0_output_shift,
            0, 999999
        );
        // print("DENSE_0\n");
        // printArray1DI(cnn_dense0_output_data, cnn_dense0_output_dims[0]);

        FullyConnected2D_TFLM(
            cnn_dense0_output_data, cnn_dense0_output_dims, 128,
            cnn_dense1_weight_data, cnn_dense1_weight_dims,
            cnn_dense1_bias_data,   cnn_dense1_bias_dims,
            cnn_dense1_output_data, cnn_dense1_output_dims, 1, 
            cnn_dense1_output_multiplier, cnn_dense1_output_shift,
            -999999, 999999
        );
        // print("DENSE_1\n");
        // printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* COMPUTATION PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
        print("MODEL RESULT\n");
        int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        print("/* PRINT RESULT PART */\n");
        print("Cycles: BEGIN ");
        print_hex(high_cycles_begin, 2);
        print_hex(cycles_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_cycles_end, 2);
        print_hex(cycles_end, 8);
        putchar('\n');

        print("Instns: BEGIN ");
        print_hex(high_instns_begin, 2);
        print_hex(instns_begin, 8);
        print(" - ");
        print("END ");
        print_hex(high_instns_end, 2);
        print_hex(instns_end, 8);
        putchar('\n');
    }
    reg_leds = 0;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    // print("BENCHMARK\n");
	// print("Cycles: BEGIN 0x");
    // print_hex(high_cycles_begin, 8);
	// print_hex(cycles_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_cycles_end, 8);
	// print_hex(cycles_end, 8);
	// putchar('\n');

    // print("Instns: BEGIN 0x");
    // print_hex(high_instns_begin, 8);
	// print_hex(instns_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_instns_end, 8);
	// print_hex(instns_end, 8);
	// putchar('\n');

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');
}

/* Test Model with Al Accel */
void testInference_CNNMNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    int32_t cnn_conv0_ps_data[], int32_t cnn_conv1_ps_data[], 
    int32_t cnn_dense0_ps_data[], int32_t cnn_dense1_ps_data[],

    const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
    const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
    const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
    const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

    const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
    const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

    const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
    const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],


    const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
    const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

    const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
    const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

    const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
    const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
    const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
    const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
    const int cnn_dense0_input_dims[], 
    const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
    const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
) {
    const int new_model_input_dims[] = {28, 28, 3};
    int8_t    input_image[28 * 28 * 1];

    uint32_t total_input_cycles = 0;
    uint32_t total_comps_cycles = 0;
    uint32_t total_output_cycles = 0;

    uint32_t total_input_ins = 0;
    uint32_t total_comps_ins = 0;
    uint32_t total_output_ins = 0;

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        print("TEST CASE "); print_dec(test_idx); putchar('\n');

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* READ INPUT PART */
        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] = test_images[test_idx][offset_1 + offset_0 + width];
            }
        }

        // printArray3DI(input_image, model_input_dims);

        /*********************/
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));
        
        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins += (instns_end - instns_begin);

        // print("/* READ INPUT PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');


        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* COMPUTATION PART */

        // First CONV Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_CONV_layer(
            input_image, new_model_input_dims, 128,
            cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
            cnn_conv0_bias_data, cnn_conv0_bias_dims,
            cnn_conv0_output_data, cnn_conv0_output_dims, 128,
            cnn_conv0_ps_data,
            1, 1,
            cnn_conv0_output_multiplier, cnn_conv0_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        run_and_wait_al_accel();
        // print("CONV_0\n");
        // printArray3DI(cnn_conv0_output_data, cnn_conv0_output_dims);
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // First POOL Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_POOL_layer(
            cnn_conv0_output_data, cnn_conv0_output_dims,
            cnn_pool0_output_data, cnn_pool0_output_dims,
            2, 2,
            2, 2
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

	    run_and_wait_al_accel();
        // print("POOL_0\n");
        // printArray3DI(cnn_pool0_output_data, cnn_pool0_output_dims);
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // Second CONV Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_CONV_layer(
            cnn_pool0_output_data, cnn_pool0_output_dims, 128,
            cnn_conv1_kernel_data, cnn_conv1_kernel_dims,
            cnn_conv1_bias_data, cnn_conv1_bias_dims,
            cnn_conv1_output_data, cnn_conv1_output_dims, 128,
            cnn_conv1_ps_data,
            1, 1,
            cnn_conv1_output_multiplier, cnn_conv1_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();
        // print("CONV_1\n");
        // printArray3DI(cnn_conv1_output_data, cnn_conv1_output_dims);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // Second POOL Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_POOL_layer(
            cnn_conv1_output_data, cnn_conv1_output_dims,
            cnn_pool1_output_data, cnn_pool1_output_dims,
            2, 2,
            2, 2
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
	    run_and_wait_al_accel();
        // print("POOL_1\n");
        // printArray3DI(cnn_pool1_output_data, cnn_pool1_output_dims);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // First DENSE Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_DENSE_layer(
            cnn_pool1_output_data, cnn_dense0_input_dims, 128,
            cnn_dense0_weight_data, cnn_dense0_weight_dims,
            cnn_dense0_bias_data, cnn_dense0_bias_dims,
            cnn_dense0_output_data , cnn_dense0_output_dims, 128,
            cnn_dense0_ps_data,
            cnn_dense0_output_multiplier, cnn_dense0_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();
        // print("DENSE_0\n");
        // printArray1DI(cnn_dense0_output_data, cnn_dense0_output_dims[0]);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');

        // Second DENSE Layer
        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_DENSE_layer(
            cnn_dense0_output_data, cnn_dense0_output_dims, 128,
            cnn_dense1_weight_data, cnn_dense1_weight_dims,
            cnn_dense1_bias_data, cnn_dense1_bias_dims,
            cnn_dense1_output_data , cnn_dense1_output_dims, 1,
            cnn_dense1_ps_data,
            cnn_dense1_output_multiplier, cnn_dense1_output_shift,
            NO_FUNC
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();
        // print("DENSE_1\n");
        // printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);
        print("Cycles: "); print_dec(cycles_end - cycles_begin); putchar('\n');
        /*********************/

        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        // total_comps_cycles += (cycles_end - cycles_begin);
        // total_comps_ins += (instns_end - instns_begin);

        // print("/* COMPUTATION PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');


        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
        print("MODEL RESULT\n");
        int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_output_cycles += (cycles_end - cycles_begin);
        total_output_ins += (instns_end - instns_begin);

        // print("/* PRINT RESULT PART */\n");
        // print("Cycles: BEGIN ");
        // print_hex(high_cycles_begin, 2);
        // print_hex(cycles_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_cycles_end, 2);
        // print_hex(cycles_end, 8);
        // putchar('\n');

        // print("Instns: BEGIN ");
        // print_hex(high_instns_begin, 2);
        // print_hex(instns_begin, 8);
        // print(" - ");
        // print("END ");
        // print_hex(high_instns_end, 2);
        // print_hex(instns_end, 8);
        // putchar('\n');
    }

	// __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	// __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	// __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    // print("BENCHMARK\n");
	// print("Cycles: BEGIN 0x");
    // print_hex(high_cycles_begin, 8);
	// print_hex(cycles_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_cycles_end, 8);
	// print_hex(cycles_end, 8);
	// putchar('\n');

    // print("Instns: BEGIN 0x");
    // print_hex(high_instns_begin, 8);
	// print_hex(instns_begin, 8);
	// print(" - ");
    // print("END 0x");
    // print_hex(high_instns_end, 8);
	// print_hex(instns_end, 8);
	// putchar('\n');

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');

    print("TOTAL: \n");
    print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; "); print_dec(total_input_ins); print(" ins\n");
    print("\tComputation: "); print_dec(total_comps_cycles); print(" cycles; "); print_dec(total_comps_ins); print(" ins\n");
    print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; "); print_dec(total_output_ins); print(" ins\n");
}

/***************************************************************/
void testInference_SimpleMNISTModel_NoAccel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    const int32_t conv_output_multiplier[], const int8_t conv_output_shift[],
    const int32_t dense_output_multiplier, const int8_t  dense_output_shift,
    const int conv_weight_dims[], const int8_t conv_weight_data[],
    const int conv_bias_dims[], const int32_t conv_bias_data[],
    const int dense_weight_dims[], const int8_t dense_weight_data[],
    const int dense_bias_dims[], const int32_t dense_bias_data[],

    const int conv_output_dims[], int8_t conv_output_data[],
    const int pool_output_dims[], int8_t pool_output_data[],
    const int dense_input_dims[], 
    const int dense_output_dims[], int8_t dense_output_data[]
) {
	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	__asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    reg_leds = 255;

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        Conv2D_TFLM(
            test_images[test_idx],  model_input_dims, 128,
            conv_weight_data,       conv_weight_dims,
            conv_bias_data,         conv_bias_dims,
            1, 1,
            0, 0,
            conv_output_data,       conv_output_dims, 128,
            conv_output_multiplier, conv_output_shift,
            0, 999999
        );

        MaxPool_TFLM(
            conv_output_data, conv_output_dims,
            2, 2,
            0, 0,
            2, 2,
            pool_output_data, pool_output_dims,
            0, 999999
        );

        FullyConnected2D_TFLM(
            pool_output_data, dense_input_dims, 128,
            dense_weight_data, dense_weight_dims,
            dense_bias_data, dense_bias_dims,
            dense_output_data, dense_output_dims, -55, 
            dense_output_multiplier, dense_output_shift,
            -999999, 999999
        );
        printArray1DI(dense_output_data, 10);

        print("MODEL RESULT\n");
        int max_idx = get_label(dense_output_data, dense_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;
    }
    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	__asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    print("BENCHMARK\n");
	print("Cycles: BEGIN 0x");
    print_hex(high_cycles_begin, 8);
	print_hex(cycles_begin, 8);
	print(" - ");
    print("END 0x");
    print_hex(high_cycles_end, 8);
	print_hex(cycles_end, 8);
	putchar('\n');

    print("Instns: BEGIN 0x");
    print_hex(high_instns_begin, 8);
	print_hex(instns_begin, 8);
	print(" - ");
    print("END 0x");
    print_hex(high_instns_end, 8);
	print_hex(instns_end, 8);
	putchar('\n');

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');

    // print("BENCHMARK\n");
	// print("Cycles: 0x");
	// print_hex(cycles_end - cycles_begin, 8);
	// putchar('\n');

	// print("Instns: 0x");
	// print_hex(instns_end - instns_begin, 8);
	// putchar('\n');    
}

void testInference_SimpleMNISTModel_Accel(
    const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
    const int model_input_dims[], 

    int32_t conv_ps_data[], int32_t dense_ps_data[],

    const int32_t conv_output_multiplier[], const int8_t conv_output_shift[],
    const int32_t dense_output_multiplier, const int8_t  dense_output_shift,
    const int conv_weight_dims[], const int8_t conv_weight_data[],
    const int conv_bias_dims[], const int32_t conv_bias_data[],
    const int dense_weight_dims[], const int8_t dense_weight_data[],
    const int dense_bias_dims[], const int32_t dense_bias_data[],

    const int conv_output_dims[], int8_t conv_output_data[],
    const int pool_output_dims[], int8_t pool_output_data[],
    const int dense_input_dims[], 
    const int dense_output_dims[], int8_t dense_output_data[]
) {
    const int new_model_input_dims[] = {28, 28, 3};

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
    __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
	__asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

    reg_leds = 255;
    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_CONV_layer(
            test_images[test_idx], new_model_input_dims, 128,
            conv_weight_data, conv_weight_dims,
            conv_bias_data, conv_bias_dims,
            conv_output_data, conv_output_dims, 128,
            conv_ps_data,
            1, 1,
            conv_output_multiplier, conv_output_shift,
            RELU
        );
        run_and_wait_al_accel();

        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_POOL_layer(
            conv_output_data, conv_output_dims,
            pool_output_data, pool_output_dims,
            2, 2,
            2, 2
        );
	    run_and_wait_al_accel();

        set_al_accel_mode(RESET);
        set_al_accel_mode(CONFIG);
        config_al_accel_DENSE_layer(
            pool_output_data, dense_input_dims, 128,
            dense_weight_data, dense_weight_dims,
            dense_bias_data, dense_bias_dims,
            dense_output_data , dense_output_dims, -55,
            dense_ps_data,
            dense_output_multiplier, dense_output_shift,
            NO_FUNC
        );
        run_and_wait_al_accel();
        printArray1DI(dense_output_data, 10);

        print("MODEL RESULT\n");
        int max_idx = get_label(dense_output_data, dense_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;
    }

    reg_leds = 0;

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));
    __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
	__asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

    print("BENCHMARK\n");
	print("Cycles: BEGIN 0x");
    print_hex(high_cycles_begin, 8);
	print_hex(cycles_begin, 8);
	print(" - ");
    print("END 0x");
    print_hex(high_cycles_end, 8);
	print_hex(cycles_end, 8);
	putchar('\n');

    print("Instns: BEGIN 0x");
    print_hex(high_instns_begin, 8);
	print_hex(instns_begin, 8);
	print(" - ");
    print("END 0x");
    print_hex(high_instns_end, 8);
	print_hex(instns_end, 8);
	putchar('\n');

    // print("BENCHMARK\n");
	// print("Cycles: 0x");
	// print_hex(cycles_end - cycles_begin, 8);
	// putchar('\n');

	// print("Instns: 0x");
	// print_hex(instns_end - instns_begin, 8);
	// putchar('\n');    

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');
}
