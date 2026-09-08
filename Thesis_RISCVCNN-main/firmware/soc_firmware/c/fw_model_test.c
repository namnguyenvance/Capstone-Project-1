#include "fw_model_test.h"


static inline uint64_t read_cycle() {
    uint32_t hi, lo, hi2;
    do {
        __asm__ volatile ("rdcycleh %0" : "=r"(hi));
        __asm__ volatile ("rdcycle  %0" : "=r"(lo));
        __asm__ volatile ("rdcycleh %0" : "=r"(hi2));
    } while (hi != hi2);
    return ((uint64_t)hi << 32) | lo;
}

static inline uint64_t read_instret() {
    uint32_t hi, lo, hi2;
    do {
        __asm__ volatile ("rdinstreth %0" : "=r"(hi));
        __asm__ volatile ("rdinstret  %0" : "=r"(lo));
        __asm__ volatile ("rdinstreth %0" : "=r"(hi2));
    } while (hi != hi2);
    return ((uint64_t)hi << 32) | lo;
}


/***************************************************************/
// 2 Mixed Layer + 1 Dense
/* Test Model without Al Accel */
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

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
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
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins += (instns_end - instns_begin);


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

        MaxPool_TFLM(
            cnnnew_conv0_output_data, cnnnew_conv0_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims,
            0, 999999
        );

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

        MaxPool_TFLM(
            cnnnew_conv1_output_data, cnnnew_conv1_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnnnew_pool1_output_data, cnnnew_pool1_output_dims,
            0, 999999
        );

        FullyConnected2D_TFLM(
            cnnnew_pool1_output_data,  cnnnew_dense0_input_dims, 128,
            cnnnew_dense0_weight_data, cnnnew_dense0_weight_dims,
            cnnnew_dense0_bias_data,   cnnnew_dense0_bias_dims,
            cnnnew_dense0_output_data, cnnnew_dense0_output_dims, -24, 
            cnnnew_dense0_output_multiplier, cnnnew_dense0_output_shift,
            -999999, 999999
        );
        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
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

    }
    reg_leds = 0;


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

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
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

        /*********************/
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));
        
        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins += (instns_end - instns_begin);

        /* COMPUTATION PART */
        // First Mixed Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_MIXED_layer(
            input_image, new_model_input_dims, 128,
            cnnnew_conv0_kernel_data, cnnnew_conv0_kernel_dims,
            cnnnew_conv0_bias_data, cnnnew_conv0_bias_dims,
            cnnnew_conv0_output_dims, 
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims, 128,
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
        
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        // Second MIXED Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);

        config_al_accel_MIXED_layer(
            cnnnew_pool0_output_data, cnnnew_pool0_output_dims, 128,
            cnnnew_conv1_kernel_data, cnnnew_conv1_kernel_dims,
            cnnnew_conv1_bias_data, cnnnew_conv1_bias_dims,
            cnnnew_conv1_output_dims, 
            cnnnew_pool1_output_data, cnnnew_pool1_output_dims, 128,
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

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

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

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
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

    }

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
// 2 Mixed Layer + 2 Dense
/* Test Model without Al Accel */
/***************************************************************/
// 2 Conv + 2 Pool + 2 Dense
/* Test Model without Accelerator */
// void testInference_CNNMNISTModel_NoAccel(
//     const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
//     const int model_input_dims[], 

//     const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
//     const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
//     const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
//     const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

//     const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
//     const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

//     const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
//     const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],

//     const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
//     const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

//     const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
//     const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

//     const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
//     const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
//     const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
//     const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
//     const int cnn_dense0_input_dims[], 
//     const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
//     const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
// ) {
//     int8_t    input_image[28 * 28 * 1];

//     uint64_t total_input_cycles = 0, total_input_ins = 0;
//     uint64_t total_comps_cycles = 0, total_comps_ins = 0;
//     uint64_t total_output_cycles = 0, total_output_ins = 0;

//     reg_leds = 255;
//     int passed_test = 0;

//     for (int test_idx = 0; test_idx < number_of_test; test_idx++) {

//         // ================= READ INPUT =================
//         uint64_t cycles_begin = read_cycle();
//         uint64_t instns_begin = read_instret();

//         for (int channel = 0; channel < model_input_dims[2]; channel++) {
//             int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
//             for (int height = 0; height < model_input_dims[1]; height++) {
//                 int offset_0 = model_input_dims[0] * height;
//                 for (int width = 0; width < model_input_dims[0]; width++)
//                     input_image[offset_1 + offset_0 + width] =
//                         test_images[test_idx][offset_1 + offset_0 + width];
//             }
//         }

//         uint64_t cycles_end = read_cycle();
//         uint64_t instns_end = read_instret();
//         total_input_cycles += (cycles_end - cycles_begin);
//         total_input_ins    += (instns_end - instns_begin);

//         // ================= COMPUTATION =================
//         cycles_begin = read_cycle();
//         instns_begin = read_instret();

//         Conv2D_TFLM(
//             input_image, model_input_dims, 128,
//             cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
//             cnn_conv0_bias_data,   cnn_conv0_bias_dims,
//             1, 1, 0, 0,
//             cnn_conv0_output_data, cnn_conv0_output_dims, 128,
//             cnn_conv0_output_multiplier, cnn_conv0_output_shift,
//             0, 999999
//         );

//         MaxPool_TFLM(cnn_conv0_output_data, cnn_conv0_output_dims,
//                      2, 2, 0, 0, 2, 2,
//                      cnn_pool0_output_data, cnn_pool0_output_dims,
//                      0, 999999);

//         Conv2D_TFLM(
//             cnn_pool0_output_data, cnn_pool0_output_dims, 128,
//             cnn_conv1_kernel_data, cnn_conv1_kernel_dims,
//             cnn_conv1_bias_data,   cnn_conv1_bias_dims,
//             1, 1, 0, 0,
//             cnn_conv1_output_data, cnn_conv1_output_dims, 128,
//             cnn_conv1_output_multiplier, cnn_conv1_output_shift,
//             0, 999999
//         );

//         MaxPool_TFLM(cnn_conv1_output_data, cnn_conv1_output_dims,
//                      2, 2, 0, 0, 2, 2,
//                      cnn_pool1_output_data, cnn_pool1_output_dims,
//                      0, 999999);

//         FullyConnected2D_TFLM(
//             cnn_pool1_output_data,  cnn_dense0_input_dims, 128,
//             cnn_dense0_weight_data, cnn_dense0_weight_dims,
//             cnn_dense0_bias_data,   cnn_dense0_bias_dims,
//             cnn_dense0_output_data, cnn_dense0_output_dims, 128, 
//             cnn_dense0_output_multiplier, cnn_dense0_output_shift,
//             0, 999999
//         );

//         FullyConnected2D_TFLM(
//             cnn_dense0_output_data, cnn_dense0_output_dims, 128,
//             cnn_dense1_weight_data, cnn_dense1_weight_dims,
//             cnn_dense1_bias_data,   cnn_dense1_bias_dims,
//             cnn_dense1_output_data, cnn_dense1_output_dims, 1, 
//             cnn_dense1_output_multiplier, cnn_dense1_output_shift,
//             -999999, 999999
//         );

//         cycles_end = read_cycle();
//         instns_end = read_instret();
//         total_comps_cycles += (cycles_end - cycles_begin);
//         total_comps_ins    += (instns_end - instns_begin);

//         // ================= OUTPUT =================
//         cycles_begin = read_cycle();
//         instns_begin = read_instret();

//         int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
//         print("Test Case ");
//         print_dec(test_idx);
//         print(": predicted = "); 
//         print_dec(max_idx);
//         print("; expected = ");
//         print_dec(test_labels[test_idx]);
//         print("; result = ");
//         print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
//         if (max_idx == test_labels[test_idx]) passed_test++;

//         cycles_end = read_cycle();
//         instns_end = read_instret();

//         total_output_cycles += (cycles_end - cycles_begin);
//         total_output_ins    += (instns_end - instns_begin);
//     }

//     reg_leds = 0;

//     // ================= PRINT TOTAL RESULT =================
//     print("Passed Test/Total = ");
//     print_dec(passed_test);
//     putchar('/');
//     print_dec(number_of_test);
//     putchar('\n');

//     print("TOTAL:\n");
//     print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; ");
//     print_dec(total_input_ins); print(" ins\n");

//     print("\tComputation: "); print_dec(total_comps_cycles); print(" cycles; ");
//     print_dec(total_comps_ins); print(" ins\n");

//     print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; ");
//     print_dec(total_output_ins); print(" ins\n");
// }
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

    uint32_t total_input_cycles = 0;
    uint32_t total_comps_cycles = 0;
    uint32_t total_output_cycles = 0;

    uint32_t total_input_ins = 0;
    uint32_t total_comps_ins = 0;
    uint32_t total_output_ins = 0;

    reg_leds = 255;

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
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

        total_input_cycles = cycles_end - cycles_begin;
        total_input_ins = instns_end - instns_begin;


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

        MaxPool_TFLM(
            cnn_conv0_output_data, cnn_conv0_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnn_pool0_output_data, cnn_pool0_output_dims,
            0, 999999
        );

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

        MaxPool_TFLM(
            cnn_conv1_output_data, cnn_conv1_output_dims,
            2, 2,
            0, 0,
            2, 2,
            cnn_pool1_output_data, cnn_pool1_output_dims,
            0, 999999
        );
        FullyConnected2D_TFLM(
            cnn_pool1_output_data,  cnn_dense0_input_dims, 128,
            cnn_dense0_weight_data, cnn_dense0_weight_dims,
            cnn_dense0_bias_data,   cnn_dense0_bias_dims,
            cnn_dense0_output_data, cnn_dense0_output_dims, 128, 
            cnn_dense0_output_multiplier, cnn_dense0_output_shift,
            0, 999999
        );

        FullyConnected2D_TFLM(
            cnn_dense0_output_data, cnn_dense0_output_dims, 128,
            cnn_dense1_weight_data, cnn_dense1_weight_dims,
            cnn_dense1_bias_data,   cnn_dense1_bias_dims,
            cnn_dense1_output_data, cnn_dense1_output_dims, 1, 
            cnn_dense1_output_multiplier, cnn_dense1_output_shift,
            -999999, 999999
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
        int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        print("Test Case ");
        print_dec(test_idx);
        print(": ");
        printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        print(" - predicted = "); 
        print_dec(max_idx);
        print("; expected = ");
        print_dec(test_labels[test_idx]);
        print("; result = ");
        print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        if (max_idx == test_labels[test_idx]) passed_test++;

        // print("IMAGE ");
        // print_dec(test_idx);
        // print(": ");
        // printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
        // putchar('\n');

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));


        total_output_cycles += (cycles_end - cycles_begin);
        total_output_ins += (instns_end - instns_begin);

    }
    reg_leds = 0;

    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');

    print("Computation cycles: "); print_dec(total_comps_cycles); print("  Computation ins; ");
    print_dec(total_comps_ins); print(" ins\n");
    putchar('\n');
    print("Average cycles: "); print_dec(total_comps_cycles / 10); print(" cycles; ");
    print("Average ins: "); print_dec(total_comps_ins / 10); print(" ins; ");
}

/***************************************************************/
/* Test Model with Accelerator */
// void testInference_CNNMNISTModel_Accel(
//     const int8_t test_images[][28 * 28 * 1], const int8_t test_labels[], int number_of_test, 
//     const int model_input_dims[], 

//     int32_t cnn_conv0_ps_data[], int32_t cnn_conv1_ps_data[], 
//     int32_t cnn_dense0_ps_data[], int32_t cnn_dense1_ps_data[],

//     const int32_t cnn_conv0_output_multiplier[], const int8_t cnn_conv0_output_shift[],
//     const int32_t cnn_conv1_output_multiplier[], const int8_t cnn_conv1_output_shift[],
//     const int32_t cnn_dense0_output_multiplier, const int8_t  cnn_dense0_output_shift,
//     const int32_t cnn_dense1_output_multiplier, const int8_t  cnn_dense1_output_shift,

//     const int cnn_conv0_kernel_dims[], const int8_t cnn_conv0_kernel_data[],
//     const int cnn_conv0_bias_dims[], const int32_t cnn_conv0_bias_data[],

//     const int cnn_conv1_kernel_dims[], const int8_t cnn_conv1_kernel_data[],
//     const int cnn_conv1_bias_dims[], const int32_t cnn_conv1_bias_data[],

//     const int cnn_dense0_weight_dims[], const int8_t cnn_dense0_weight_data[],
//     const int cnn_dense0_bias_dims[], const int32_t cnn_dense0_bias_data[],

//     const int cnn_dense1_weight_dims[], const int8_t cnn_dense1_weight_data[],
//     const int cnn_dense1_bias_dims[], const int32_t cnn_dense1_bias_data[],

//     const int cnn_conv0_output_dims[], int8_t cnn_conv0_output_data[],
//     const int cnn_pool0_output_dims[], int8_t cnn_pool0_output_data[],
//     const int cnn_conv1_output_dims[], int8_t cnn_conv1_output_data[],
//     const int cnn_pool1_output_dims[], int8_t cnn_pool1_output_data[],
//     const int cnn_dense0_input_dims[], 
//     const int cnn_dense0_output_dims[], int8_t cnn_dense0_output_data[],
//     const int cnn_dense1_output_dims[], int8_t cnn_dense1_output_data[]
// ) {
//     const int new_model_input_dims[] = {28, 28, 3};
//     int8_t    input_image[28 * 28 * 1];

//     uint32_t total_input_cycles = 0;
//     uint32_t total_comps_cycles = 0;
//     uint32_t total_output_cycles = 0;

//     uint32_t total_input_ins = 0;
//     uint32_t total_comps_ins = 0;
//     uint32_t total_output_ins = 0;

// 	uint32_t cycles_begin, cycles_end;
// 	uint32_t instns_begin, instns_end;
//     uint32_t high_cycles_begin, high_cycles_end;
// 	uint32_t high_instns_begin, high_instns_end;

//     int passed_test = 0;

//     for (int test_idx = 0; test_idx < number_of_test; test_idx++) {

//         // ================= READ INPUT =================
//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

//         for (int channel = 0; channel < model_input_dims[2]; channel++) {
//             int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
//             for (int height = 0; height < model_input_dims[1]; height++) {
//                 int offset_0 = model_input_dims[0] * height;
//                 for (int width = 0; width < model_input_dims[0]; width++)
//                     input_image[offset_1 + offset_0 + width] =
//                         test_images[test_idx][offset_1 + offset_0 + width];
//             }
//         }

//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         total_input_cycles += (cycles_end - cycles_begin);
//         total_input_ins += (instns_end - instns_begin);

//         // ================= COMPUTATION =================
//         // First Mixed Layer
//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
//         set_al_accel_mode(RESET); 
//         set_al_accel_mode(CONFIG);
//         config_al_accel_MIXED_layer(
//             input_image, new_model_input_dims, 128,
//             cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
//             cnn_conv0_bias_data, cnn_conv0_bias_dims,
//             cnn_conv0_output_dims, 
//             cnn_pool0_output_data, cnn_pool0_output_dims, 128,
//             cnn_conv0_ps_data,
//             1, 1,
//             cnn_conv0_output_multiplier, cnn_conv0_output_shift,
//             RELU
//         );


//         run_and_wait_al_accel();

//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         // total_comps_cycles += (cycles_end - cycles_begin);
//         // total_comps_ins += (instns_end - instns_begin);

//         // Second Mixed Layer
//         set_al_accel_mode(RESET); 
//         set_al_accel_mode(CONFIG);
//         config_al_accel_MIXED_layer(
//             cnn_pool0_output_data, cnn_pool0_output_dims, 128,
//             cnn_conv1_kernel_data, cnn_conv1_kernel_dims,
//             cnn_conv1_bias_data, cnn_conv1_bias_dims,
//             cnn_conv1_output_dims, 
//             cnn_pool1_output_data, cnn_pool1_output_dims, 128,
//             cnn_conv1_ps_data,
//             1, 1,
//             cnn_conv1_output_multiplier, cnn_conv1_output_shift,
//             RELU
//         );

//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

//         run_and_wait_al_accel();

//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         // total_comps_cycles += (cycles_end - cycles_begin);
//         // total_comps_ins += (instns_end - instns_begin);

//         // First Dense Layer
//         set_al_accel_mode(RESET);
//         set_al_accel_mode(CONFIG);
//         config_al_accel_DENSE_layer(
//             cnn_pool1_output_data, cnn_dense0_input_dims, 128,
//             cnn_dense0_weight_data, cnn_dense0_weight_dims,
//             cnn_dense0_bias_data, cnn_dense0_bias_dims,
//             cnn_dense0_output_data , cnn_dense0_output_dims, 128,
//             cnn_dense0_ps_data,
//             cnn_dense0_output_multiplier, cnn_dense0_output_shift,
//             RELU
//         );
//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

//         run_and_wait_al_accel();

//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         // total_comps_cycles += (cycles_end - cycles_begin);
//         // total_comps_ins += (instns_end - instns_begin);

//         // Second Dense Layer
//         set_al_accel_mode(RESET);
//         set_al_accel_mode(CONFIG);
//         config_al_accel_DENSE_layer(
//             cnn_dense0_output_data, cnn_dense0_output_dims, 128,
//             cnn_dense1_weight_data, cnn_dense1_weight_dims,
//             cnn_dense1_bias_data, cnn_dense1_bias_dims,
//             cnn_dense1_output_data , cnn_dense1_output_dims, 1,
//             cnn_dense1_ps_data,
//             cnn_dense1_output_multiplier, cnn_dense1_output_shift,
//             NO_FUNC
//         );
//         // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

//         run_and_wait_al_accel();

//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         total_comps_cycles += (cycles_end - cycles_begin);
//         total_comps_ins += (instns_end - instns_begin);

//         // ================= OUTPUT =================
//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

//         // int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);

//         // print("Test Case ");
//         // print_dec(test_idx);
//         // print(": predicted = "); 
//         // print_dec(max_idx);
//         // print("; expected = ");
//         // print_dec(test_labels[test_idx]);
//         // print("; result = ");
//         // print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
//         // if (max_idx == test_labels[test_idx]) passed_test++;
//         print("IMAGE ");
//         print_dec(test_idx);
//         print(": ");
//         printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
//         putchar('\n');

//         cycles_end = read_cycle();
//         instns_end = read_instret();

//         __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
//         __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
//         __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
//         __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

//         total_output_cycles += (cycles_end - cycles_begin);
//         total_output_ins += (instns_end - instns_begin);
//     }

//     // ================= PRINT TOTAL RESULT =================
//     // print("Passed Test/Total = ");
//     // print_dec(passed_test);
//     // putchar('/');
//     // print_dec(number_of_test);
//     // putchar('\n');

//     // print("TOTAL:\n");
//     // print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; ");
//     // print_dec(total_input_ins); print(" ins\n");

//     print("Computation cycles: "); print_dec(total_comps_cycles); print("  Computation ins; ");
//     print_dec(total_comps_ins); print(" ins\n");
//     putchar('\n');
//     print("Average cycles: "); print_dec(total_comps_cycles / 10); print(" cycles; ");
//     print("Average ins: "); print_dec(total_comps_ins / 10); print(" ins; ");

//     // print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; ");
//     // print_dec(total_output_ins); print(" ins\n");
// }

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
    uint32_t comps_cycles = 0;

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
    uint32_t high_cycles_begin, high_cycles_end;
	uint32_t high_instns_begin, high_instns_end;

    int passed_test = 0;

    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {

        // ================= READ INPUT =================
        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] =
                        test_images[test_idx][offset_1 + offset_0 + width];
            }
        }

        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        // total_input_cycles += (cycles_end - cycles_begin);
        // total_input_ins += (instns_end - instns_begin);

        // ================= COMPUTATION =================
        // First Mixed Layer
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_MIXED_layer(
            input_image, new_model_input_dims, 128,
            cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
            cnn_conv0_bias_data, cnn_conv0_bias_dims,
            cnn_conv0_output_dims, 
            cnn_pool0_output_data, cnn_pool0_output_dims, 128,
            cnn_conv0_ps_data,
            1, 1,
            cnn_conv0_output_multiplier, cnn_conv0_output_shift,
            RELU
        );

	    run_and_wait_al_accel();

        // Second Mixed Layer
        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_MIXED_layer(
            cnn_pool0_output_data, cnn_pool0_output_dims, 128,
            cnn_conv1_kernel_data, cnn_conv1_kernel_dims,
            cnn_conv1_bias_data, cnn_conv1_bias_dims,
            cnn_conv1_output_dims, 
            cnn_pool1_output_data, cnn_pool1_output_dims, 128,
            cnn_conv1_ps_data,
            1, 1,
            cnn_conv1_output_multiplier, cnn_conv1_output_shift,
            RELU
        );

	    run_and_wait_al_accel();

        // First Dense Layer
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

	    run_and_wait_al_accel();

        // Second Dense Layer
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


	    run_and_wait_al_accel();
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        comps_cycles = cycles_end - cycles_begin;
        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        // ================= OUTPUT =================
        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        // int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);

        // print("Test Case ");
        // print_dec(test_idx);
        // print(": predicted = "); 
        // print_dec(max_idx);
        // print("; expected = ");
        // print_dec(test_labels[test_idx]);
        // print("; result = ");
        // // print((max_idx == test_labels[test_idx]) ? "true\n" : "false\n");
        // print((max_idx == test_labels[test_idx]) ? "true" : "false");
        // print(", Cycles Counter: "); print_dec(comps_cycles); print(" cycles"); putchar('\n');

        // if (max_idx == test_labels[test_idx]) passed_test++;

        // __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        // __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        // __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        // __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        // total_output_cycles += (cycles_end - cycles_begin);
        // total_output_ins += (instns_end - instns_begin);
    }

    // ================= PRINT TOTAL RESULT =================
        print("Passed Test/Total = ");
        print_dec(passed_test);
        putchar('/');
        print_dec(number_of_test);
        putchar('\n');

        // print("TOTAL:\n");
        // print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; ");
        // print_dec(total_input_ins); print(" ins\n");

        print("\tComputation: "); print_dec(total_comps_cycles); print(" cycles; ");
        print_dec(total_comps_ins); print(" ins\n");

        // print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; ");
        // print_dec(total_output_ins); print(" ins\n");
}



/***************************************************************/
// 1 Mixed Layer + 1 Dense
/* Test Model without Al Accel */
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
    int8_t    input_image[28 * 28 * 1];

    uint64_t total_input_cycles = 0;
    uint64_t total_comps_cycles = 0;
    uint64_t total_output_cycles = 0;

    uint64_t total_input_ins = 0;
    uint64_t total_comps_ins = 0;
    uint64_t total_output_ins = 0;

    reg_leds = 255;
    int passed_test = 0;

    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
        // ================= READ INPUT =================
        uint64_t cycles_begin = read_cycle();
        uint64_t instns_begin = read_instret();

        for (int channel = 0; channel < model_input_dims[2]; channel++) {
            int offset_1 = model_input_dims[1] * model_input_dims[0] * channel;
            for (int height = 0; height < model_input_dims[1]; height++) {
                int offset_0 = model_input_dims[0] * height;
                for (int width = 0; width < model_input_dims[0]; width++)
                    input_image[offset_1 + offset_0 + width] = test_images[test_idx][offset_1 + offset_0 + width];
            }
        }

        uint64_t cycles_end = read_cycle();
        uint64_t instns_end = read_instret();

        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins    += (instns_end - instns_begin);

        // ================= COMPUTATION =================
        cycles_begin = read_cycle();
        instns_begin = read_instret();

        Conv2D_TFLM(
            input_image,  model_input_dims, 128,
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
            dense_bias_data,   dense_bias_dims,
            dense_output_data, dense_output_dims, -55, 
            dense_output_multiplier, dense_output_shift,
            -999999, 999999
        );

        cycles_end = read_cycle();
        instns_end = read_instret();

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins    += (instns_end - instns_begin);

        // ================= OUTPUT =================
        cycles_begin = read_cycle();
        instns_begin = read_instret();

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

        cycles_end = read_cycle();
        instns_end = read_instret();

        total_output_cycles += (cycles_end - cycles_begin);
        total_output_ins    += (instns_end - instns_begin);
    }

    reg_leds = 0;

    // ================= PRINT TOTAL RESULT =================
    print("Passed Test/Total = ");
    print_dec(passed_test);
    putchar('/');
    print_dec(number_of_test);
    putchar('\n');

    print("TOTAL:\n");
    print("\tRead Data  : "); print_dec(total_input_cycles); print(" cycles; ");
    print_dec(total_input_ins); print(" ins\n");

    print("\tComputation: "); print_dec(total_comps_cycles); print(" cycles; ");
    print_dec(total_comps_ins); print(" ins\n");

    print("\tOutput Data: "); print_dec(total_output_cycles); print(" cycles; ");
    print_dec(total_output_ins); print(" ins\n");
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

    // Test right here !!!
    int passed_test = 0;
    for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
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

        /*********************/
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));
        
        total_input_cycles += (cycles_end - cycles_begin);
        total_input_ins += (instns_end - instns_begin);



        set_al_accel_mode(RESET); 
        set_al_accel_mode(CONFIG);
        config_al_accel_MIXED_layer(
            input_image, new_model_input_dims, 128,
            conv_weight_data, conv_weight_dims,
            conv_bias_data, conv_bias_dims,
            conv_output_dims,
            pool_output_data, pool_output_dims, 128,
            conv_ps_data,
            1, 1,
            conv_output_multiplier, conv_output_shift,
            RELU
        );

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        run_and_wait_al_accel();

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));
        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        print("Cycle: ");
        print_dec(cycles_end - cycles_begin);
        print(" , Inst: ");
        print_dec(instns_end - instns_begin);
        putchar('\n');


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

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));
        run_and_wait_al_accel();

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_comps_cycles += (cycles_end - cycles_begin);
        total_comps_ins += (instns_end - instns_begin);

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_begin));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_begin));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_begin));

        /* PRINT RESULT PART */
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

        /*********************/

        __asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
        __asm__ volatile ("rdinstret %0" : "=r"(instns_end));
        __asm__ volatile ("rdcycleh %0" : "=r"(high_cycles_end));
        __asm__ volatile ("rdinstreth %0" : "=r"(high_instns_end));

        total_output_cycles += (cycles_end - cycles_begin);
        total_output_ins += (instns_end - instns_begin);
    }

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
