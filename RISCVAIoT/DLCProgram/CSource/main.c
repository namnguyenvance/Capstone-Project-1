#include "main.h"

#ifdef CNNNEW_RUN
    // CNN Model
    const int   cnnnew_conv0_output_dims[] = {26, 26, 32};
    int8_t      cnnnew_conv0_output_data[26 * 26 * 32];
    
    const int   cnnnew_pool0_output_dims[] = {13, 13, 32};
    int8_t      cnnnew_pool0_output_data[13 * 13 * 32];

    const int   cnnnew_conv1_output_dims[] = {11, 11, 32};
    int8_t      cnnnew_conv1_output_data[11 * 11 * 32];

    const int   cnnnew_pool1_output_dims[] = {5, 5, 32};
    int8_t      cnnnew_pool1_output_data[5 * 5 * 32];

    const int   cnnnew_dense0_input_dims[] = {800};

    const int   cnnnew_dense0_output_dims[] = {10};
    int8_t      cnnnew_dense0_output_data[10];


    void cnnnew_run() {
        int number_test_passed = 0;
        // for (int test_idx = 0; test_idx < 10; test_idx++) {
        for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
            // printArray3DI(test_images[test_idx], model_input_dims);
            Conv2D_TFLM(
                test_images[test_idx],   model_input_dims, 128,
                cnnnew_conv0_kernel_data, cnnnew_conv0_kernel_dims,
                cnnnew_conv0_bias_data,   cnnnew_conv0_bias_dims,
                1, 1,
                0, 0,
                cnnnew_conv0_output_data, cnnnew_conv0_output_dims, 128,
                cnnnew_conv0_output_multiplier, cnnnew_conv0_output_shift,
                0, 999999
            );
            // printArray3DI(cnnnew_conv0_output_data, cnnnew_conv0_output_dims);
            
            MaxPool_TFLM(
                cnnnew_conv0_output_data, cnnnew_conv0_output_dims,
                2, 2,
                0, 0,
                2, 2,
                cnnnew_pool0_output_data, cnnnew_pool0_output_dims,
                0, 999999
            );
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
            // printArray3DI(cnnnew_conv1_output_data, cnnnew_conv1_output_dims);

            MaxPool_TFLM(
                cnnnew_conv1_output_data, cnnnew_conv1_output_dims,
                2, 2,
                0, 0,
                2, 2,
                cnnnew_pool1_output_data, cnnnew_pool1_output_dims,
                0, 999999
            );
            // printArray3DI(cnnnew_pool1_output_data, cnnnew_pool1_output_dims);

            
            FullyConnected2D_TFLM(
                cnnnew_pool1_output_data,  cnnnew_dense0_input_dims, 128,
                cnnnew_dense0_weight_data, cnnnew_dense0_weight_dims,
                cnnnew_dense0_bias_data,   cnnnew_dense0_bias_dims,
                cnnnew_dense0_output_data, cnnnew_dense0_output_dims, -24, 
                cnnnew_dense0_output_multiplier, cnnnew_dense0_output_shift,
                -999999, 999999
            );
           

            int max_idx = get_label(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);

            if (max_idx == test_labels[test_idx]) number_test_passed += 1;
            // else {
                // printArray1DI(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);
                // printf("FAIL: Test case %d, predicted = %d\n", test_idx, max_idx);
            // }
            // printArray1DI(cnnnew_dense0_output_data, cnnnew_dense0_output_dims[0]);

            printf("Test Case %d: predicted = %d; expected = %d; result = %s\n", 
                test_idx, max_idx, test_labels[test_idx], (max_idx == test_labels[test_idx]) ? "true" : "false");
        }
        printf("Passed Test/Number of Test = %d/%d\n", number_test_passed, number_of_test);
    } 
#endif 

#ifdef CNN_RUN
    // CNN Model
    const int   cnn_conv0_output_dims[] = {26, 26, 32};
    int8_t      cnn_conv0_output_data[26 * 26 * 32];
    
    const int   cnn_pool0_output_dims[] = {13, 13, 32};
    int8_t      cnn_pool0_output_data[13 * 13 * 32];

    const int   cnn_conv1_output_dims[] = {11, 11, 32};
    int8_t      cnn_conv1_output_data[11 * 11 * 32];

    const int   cnn_pool1_output_dims[] = {5, 5, 32};
    int8_t      cnn_pool1_output_data[5 * 5 * 32];

    const int   cnn_dense0_input_dims[] = {800};

    const int   cnn_dense0_output_dims[] = {256};
    int8_t      cnn_dense0_output_data[256];

    const int   cnn_dense1_output_dims[] = {10};
    int8_t      cnn_dense1_output_data[10];


    void cnn_run() {
        int number_test_passed = 0;
        // for (int test_idx = 0; test_idx < 1; test_idx++) {
        for (int test_idx = 0; test_idx < number_of_test; test_idx++) {
            // printArray3DI(test_images[test_idx], model_input_dims);
            Conv2D_TFLM(
                test_images[test_idx],   model_input_dims, 128,
                cnn_conv0_kernel_data, cnn_conv0_kernel_dims,
                cnn_conv0_bias_data,   cnn_conv0_bias_dims,
                1, 1,
                0, 0,
                cnn_conv0_output_data, cnn_conv0_output_dims, 128,
                cnn_conv0_output_multiplier, cnn_conv0_output_shift,
                0, 999999
            );
            // printArray3DI(cnn_conv0_output_data, cnn_conv0_output_dims);
            
            MaxPool_TFLM(
                cnn_conv0_output_data, cnn_conv0_output_dims,
                2, 2,
                0, 0,
                2, 2,
                cnn_pool0_output_data, cnn_pool0_output_dims,
                0, 999999
            );
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
            // printArray3DI(cnn_conv1_output_data, cnn_conv1_output_dims);

            MaxPool_TFLM(
                cnn_conv1_output_data, cnn_conv1_output_dims,
                2, 2,
                0, 0,
                2, 2,
                cnn_pool1_output_data, cnn_pool1_output_dims,
                0, 999999
            );
            // printArray3DI(cnn_pool1_output_data, cnn_pool1_output_dims);

            
            FullyConnected2D_TFLM(
                cnn_pool1_output_data,  cnn_dense0_input_dims, 128,
                cnn_dense0_weight_data, cnn_dense0_weight_dims,
                cnn_dense0_bias_data,   cnn_dense0_bias_dims,
                cnn_dense0_output_data, cnn_dense0_output_dims, 128, 
                cnn_dense0_output_multiplier, cnn_dense0_output_shift,
                0, 999999
            );
            // printArray1DI(cnn_dense0_output_data, cnn_dense0_output_dims[0]);

            FullyConnected2D_TFLM(
                cnn_dense0_output_data, cnn_dense0_output_dims, 128,
                cnn_dense1_weight_data, cnn_dense1_weight_dims,
                cnn_dense1_bias_data,   cnn_dense1_bias_dims,
                cnn_dense1_output_data, cnn_dense1_output_dims, 1, 
                cnn_dense1_output_multiplier, cnn_dense1_output_shift,
                -999999, 999999
            );
            // printArray1DI(cnn_dense1_output_data, cnn_dense1_output_dims[0]);

            int max_idx = get_label(cnn_dense1_output_data, cnn_dense1_output_dims[0]);
            printf("Test Case %d: predicted = %d; expected = %d; result = %s\n", 
                test_idx, max_idx, test_labels[test_idx], (max_idx == test_labels[test_idx]) ? "true" : "false");

            if (max_idx == test_labels[test_idx]) number_test_passed += 1;
        }
        printf("Passed Test/Number of Test = %d/%d\n", number_test_passed, number_of_test);
    } 
#endif

#ifdef LENET_RUN
    // LeNet Model
    const int   lenet_conv0_output_dims[] = {26, 26, 6};
    int8_t      lenet_conv0_output_data[26 * 26 * 6];

    const int   lenet_pool0_output_dims[] = {13, 13, 6};
    int8_t      lenet_pool0_output_data[13 * 13 * 6];

    const int   lenet_conv1_output_dims[] = {11, 11, 16};
    int8_t      lenet_conv1_output_data[11 * 11 * 16];

    const int   lenet_pool1_output_dims[] = {5, 5, 16};
    int8_t      lenet_pool1_output_data[5 * 5 * 16];

    const int   lenet_dense0_input_dims[] = {400};

    const int   lenet_dense0_output_dims[] = {120};
    int8_t      lenet_dense0_output_data[120];

    const int   lenet_dense1_output_dims[] = {84};
    int8_t      lenet_dense1_output_data[84];

    const int   lenet_dense2_output_dims[] = {10};
    int8_t      lenet_dense2_output_data[10];

    void lenet_run() {
        int number_test_passed = 0;
        for (int test_idx = 0; test_idx < 1; test_idx++) {
            // printArray3DI(test_images[test_idx], model_input_dims);
            Conv2D_TFLM(
                test_images[test_idx],   model_input_dims, 128,
                lenet_conv0_kernel_data, lenet_conv0_kernel_dims,
                lenet_conv0_bias_data,   lenet_conv0_bias_dims,
                1, 1,
                0, 0,
                lenet_conv0_output_data, lenet_conv0_output_dims, 128,
                lenet_conv0_output_multiplier, lenet_conv0_output_shift,
                0, 999999
            );
            // printArray3DI(lenet_conv0_output_data, lenet_conv0_output_dims);

            MaxPool_TFLM(
                lenet_conv0_output_data, lenet_conv0_output_dims,
                2, 2,
                0, 0,
                2, 2,
                lenet_pool0_output_data, lenet_pool0_output_dims,
                0, 999999
            );
            // printArray3DI(lenet_pool0_output_data, lenet_pool0_output_dims);

            Conv2D_TFLM(
                lenet_pool0_output_data, lenet_pool0_output_dims, 128,
                lenet_conv1_kernel_data, lenet_conv1_kernel_dims,
                lenet_conv1_bias_data,   lenet_conv1_bias_dims,
                1, 1,
                0, 0,
                lenet_conv1_output_data, lenet_conv1_output_dims, 128,
                lenet_conv1_output_multiplier, lenet_conv1_output_shift,
                0, 999999
            );
            printArray3DI(lenet_conv1_output_data, lenet_conv1_output_dims);

            MaxPool_TFLM(
                lenet_conv1_output_data, lenet_conv1_output_dims,
                2, 2,
                0, 0,
                2, 2,
                lenet_pool1_output_data, lenet_pool1_output_dims,
                0, 999999
            );
            printArray3DI(lenet_pool1_output_data, lenet_pool1_output_dims);

            FullyConnected2D_TFLM(
                lenet_pool1_output_data,  lenet_dense0_input_dims, 128,
                lenet_dense0_weight_data, lenet_dense0_weight_dims,
                lenet_dense0_bias_data,   lenet_dense0_bias_dims,
                lenet_dense0_output_data, lenet_dense0_output_dims, 128, 
                lenet_dense0_output_multiplier, lenet_dense0_output_shift,
                0, 999999
            );
            FullyConnected2D_TFLM(
                lenet_dense0_output_data, lenet_dense0_output_dims, 128,
                lenet_dense1_weight_data, lenet_dense1_weight_dims,
                lenet_dense1_bias_data,   lenet_dense1_bias_dims,
                lenet_dense1_output_data, lenet_dense1_output_dims, 128, 
                lenet_dense1_output_multiplier, lenet_dense1_output_shift,
                0, 999999
            );
            FullyConnected2D_TFLM(
                lenet_dense1_output_data, lenet_dense1_output_dims, 128,
                lenet_dense2_weight_data, lenet_dense2_weight_dims,
                lenet_dense2_bias_data,   lenet_dense2_bias_dims,
                lenet_dense2_output_data, lenet_dense2_output_dims, 19, 
                lenet_dense2_output_multiplier, lenet_dense2_output_shift,
                -999999, 999999
            );

            int max_idx = get_label(lenet_dense2_output_data, lenet_dense2_output_dims[0]);
            printf("Test Case %d: predicted = %d; expected = %d; result = %s\n", 
                test_idx, max_idx, test_labels[test_idx], (max_idx == test_labels[test_idx]) ? "true" : "false");

            if (max_idx == test_labels[test_idx]) number_test_passed += 1;
        }

        printf("Passed Test/Number of Test = %d/%d\n", number_test_passed, number_of_test);
    }
#endif

#ifdef MODEL_TEST
    const int conv_output_dims[] = {26, 26, 12};
    int8_t conv_output_data[26 * 26 * 12];

    const int pool_output_dims[] = {13, 13, 12};
    int8_t pool_output_data[13 * 13 * 12];

    const int dense_input_dims[] = {13 * 13 * 12};

    const int dense_output_dims[] = {10};
    int8_t dense_output_data[10];

    // Model Testing
    void test_model() {
        int number_test_passed = 0;
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

            int max_idx = get_label(dense_output_data, dense_output_dims[0]);
            printf("Test Case %d: predicted = %d; expected = %d; result = %s\n", 
                test_idx, max_idx, test_labels[test_idx], (max_idx == test_labels[test_idx]) ? "true" : "false");

            if (max_idx == test_labels[test_idx]) number_test_passed += 1;
        }

        printf("Passed Test/Number of Test = %d/%d\n", number_test_passed, number_of_test);
    }
#endif

#ifdef CONV_LAYER_TEST
    void test_layer_CONV() {
        Conv2D_TFLM(
            input_data,     input_dims,     input_offset,
            filter_data,    filter_dims,
            bias_data,      bias_dims, 
            stride_width,   stride_height,
            0, 0,
            output_data,    output_dims,    output_offset,
            output_multiplier, 
            output_shift,
            0, 999999
        );

        // printf("Input Data: \n");
        // printArray3DI(input_data, input_dims);
        // printf("Filter Data: \n");
        // printArray4DI(filter_data, filter_dims);
        // printf("Bias Data:\n");
        // printArray1DI32(bias_data, bias_dims[0]);
        printf("Output Data:\n");
        printArray3DIH(output_data, output_dims);

        // Special Print
        // printf("*************\n");
        // printf("SOFTWARE RESULT\n");
        // int length = output_dims[0] * output_dims[1] * output_dims[2];
        // for (int i = 0; i < length; i = i + 4) {
        //     printf("%d %d %d %d\n",
        //         output_data[i], 
        //         (i + 1 < length) ? output_data[i + 1] : 0,
        //         (i + 2 < length) ? output_data[i + 2] : 0,
        //         (i + 3 < length) ? output_data[i + 3] : 0
        //     );
        // }
        // printf("*************\n");
    }
#endif

#ifdef DENSE_LAYER_TEST
    void test_layer_DENSE() {
        FullyConnected2D_TFLM(
            input_data  ,   input_dims ,    input_offset,
            filter_data ,   filter_dims,
            bias_data   ,   bias_dims, 
            output_data ,   output_dims,    output_offset,
            output_multiplier, 
            output_shift,
            -9999999, 9999999
        );
        // printf("Input Data: \n");
        // printArray1DI(input_data, input_dims[0]);
        // printf("Weight Data: \n");
        // printArray2DI(filter_data, filter_dims);
        // printf("Bias Data:\n");
        // printArray1DI32(bias_data, bias_dims[0]);
        printf("Output Data:\n");
        printArray1DI(output_data, output_dims[0]);
        // printf("Output Data (Hex Ver):\n");
        // printArray1DIH(output_data, output_dims[0]);

        // Special Print
        // printf("*************\n");
        // printf("SOFTWARE RESULT\n");
        // int length = output_dims[0];
        // for (int i = 0; i < length; i = i + 4) {
        //     printf("%d %d %d %d\n",
        //         output_data[i], 
        //         (i + 1 < length) ? output_data[i + 1] : 0,
        //         (i + 2 < length) ? output_data[i + 2] : 0,
        //         (i + 3 < length) ? output_data[i + 3] : 0
        //     );
        // }
        // printf("*************\n");
    }
#endif

#ifdef POOL_LAYER_TEST
    void test_layer_POOL() {
        MaxPool_TFLM(
            input_data, input_dims,
            stride_width, stride_height, 
            0, 0, 
            filter_width, filter_height, 
            output_data, output_dims,
            0, 999999
        );

        // printf("Input Data: \n");
        // printArray3DI(input_data, input_dims);
        // printf("Output Data:\n");
        // printArray3DI(output_data, output_dims);

        // Special Print
        printf("*************\n");
        printf("SOFTWARE RESULT\n");
        int length = output_dims[0] * output_dims[1] * output_dims[2];
        for (int i = 0; i < length; i = i + 4) {
            printf("%d %d %d %d\n",
                output_data[i], 
                (i + 1 < length) ? output_data[i + 1] : 0,
                (i + 2 < length) ? output_data[i + 2] : 0,
                (i + 3 < length) ? output_data[i + 3] : 0
            );
        }
        printf("*************\n");
    }
#endif

int main() {
    #if defined(CNNNEW_RUN)
        cnnnew_run();
    #elif defined(CNN_RUN)
        cnn_run();
    #elif defined(LENET_RUN)
        lenet_run();
    #elif defined(MODEL_TEST)
        test_model();
    #elif defined(CONV_LAYER_TEST)
        test_layer_CONV();
    #elif defined(DENSE_LAYER_TEST)
        test_layer_DENSE();
    #elif defined(POOL_LAYER_TEST)
        test_layer_POOL();
    #else 
        dummy();
    #endif

    return 0;
}