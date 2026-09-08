/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 * 
 *  Modified by ThaiNgo
 *  Date: Saturday, March 4, 2023
 */

#include "pico_std.h"
#include "fw_layer_data.h"
#include "mnist_input_data.h"
#include "mnist_alpico_model_data.h"
#include "cnn_alpico_model_data.h"
#include "cnnnew_alpico_model_data.h"

// -------------------------------------------------------- //
extern uint32_t sram;

void layer_test() {
	#if defined(CL_TEST)
		testConv2D_Accel(
			// input_data	, input_dims, input_offset,
			input_data, input_dims, input_offset,
			filter_data	, filter_dims,
			bias_data	, bias_dims,
			stride_width, stride_height,
			output_data	, output_dims, output_offset,
			output_multiplier, output_shift,
			ps_data, RELU
		);
	#elif defined(FCL_TEST)
		testFullyConnected2D_Accel(
			input_data , input_dims, input_offset, 
			filter_data, filter_dims,
			bias_data  , bias_dims, 
			output_data, output_dims, output_offset,
			output_multiplier, output_shift,
			ps_data, NO_FUNC
		);
	#elif defined(PL_TEST)
		testMaxPool_Accel(
			input_data, input_dims,
			stride_width, stride_height, 
			filter_width, filter_height,
			output_data, output_dims
		);
	#endif
}

void model_test() {
	#if defined(MODEL_TEST)
		testInference_SimpleMNISTModel_Accel(
			test_images, test_labels, number_of_test,
			model_input_dims,

			conv_ps_data, dense_ps_data,

			conv_output_multiplier, conv_output_shift,
			dense_output_multiplier, dense_output_shift,

			conv_weight_dims, conv_weight_data,
			conv_bias_dims, conv_bias_data,
			dense_weight_dims, dense_weight_data,
			dense_bias_dims, dense_bias_data,
			conv_output_dims, conv_output_data,
			pool_output_dims, pool_output_data,
			dense_input_dims,
			dense_output_dims, dense_output_data
		);
	#elif defined(MODEL_RUN)
		testInference_SimpleMNISTModel_Accel(
			(void*)reg_ifm_addr, test_labels, number_of_test,
			model_input_dims,

			conv_ps_data, dense_ps_data,

			conv_output_multiplier, conv_output_shift,
			dense_output_multiplier, dense_output_shift,

			conv_weight_dims, conv_weight_data,
			conv_bias_dims, conv_bias_data,
			dense_weight_dims, dense_weight_data,
			dense_bias_dims, dense_bias_data,
			conv_output_dims, conv_output_data,
			pool_output_dims, pool_output_data,
			dense_input_dims,
			dense_output_dims, dense_output_data
		);
	#elif defined(CNN_TEST)
		print("CNN_TEST\n");
		testInference_CNNMNISTModel_Accel(
			test_images, test_labels, number_of_test, 
			model_input_dims, 

			cnn_conv0_ps_data, cnn_conv1_ps_data, 
			cnn_dense0_ps_data, cnn_dense1_ps_data,

			cnn_conv0_output_multiplier, cnn_conv0_output_shift,
			cnn_conv1_output_multiplier, cnn_conv1_output_shift,
			cnn_dense0_output_multiplier,  cnn_dense0_output_shift,
			cnn_dense1_output_multiplier,  cnn_dense1_output_shift,

			cnn_conv0_kernel_dims, cnn_conv0_kernel_data,
			cnn_conv0_bias_dims, cnn_conv0_bias_data,

			cnn_conv1_kernel_dims, cnn_conv1_kernel_data,
			cnn_conv1_bias_dims, cnn_conv1_bias_data,

			cnn_dense0_weight_dims, cnn_dense0_weight_data,
			cnn_dense0_bias_dims, cnn_dense0_bias_data,

			cnn_dense1_weight_dims, cnn_dense1_weight_data,
			cnn_dense1_bias_dims, cnn_dense1_bias_data,

			cnn_conv0_output_dims, cnn_conv0_output_data,
			cnn_pool0_output_dims, cnn_pool0_output_data,
			cnn_conv1_output_dims, cnn_conv1_output_data,
			cnn_pool1_output_dims, cnn_pool1_output_data,
			cnn_dense0_input_dims, 
			cnn_dense0_output_dims, cnn_dense0_output_data,
			cnn_dense1_output_dims, cnn_dense1_output_data
		);
	#elif defined(CNN_RUN)
		print("CNN_RUN\n");
		testInference_CNNMNISTModel_Accel(
			(void*)reg_ifm_addr, test_labels, number_of_test, 
			model_input_dims, 

			cnn_conv0_ps_data, cnn_conv1_ps_data, 
			cnn_dense0_ps_data, cnn_dense1_ps_data,

			cnn_conv0_output_multiplier, cnn_conv0_output_shift,
			cnn_conv1_output_multiplier, cnn_conv1_output_shift,
			cnn_dense0_output_multiplier,  cnn_dense0_output_shift,
			cnn_dense1_output_multiplier,  cnn_dense1_output_shift,

			cnn_conv0_kernel_dims, cnn_conv0_kernel_data,
			cnn_conv0_bias_dims, cnn_conv0_bias_data,

			cnn_conv1_kernel_dims, cnn_conv1_kernel_data,
			cnn_conv1_bias_dims, cnn_conv1_bias_data,

			cnn_dense0_weight_dims, cnn_dense0_weight_data,
			cnn_dense0_bias_dims, cnn_dense0_bias_data,

			cnn_dense1_weight_dims, cnn_dense1_weight_data,
			cnn_dense1_bias_dims, cnn_dense1_bias_data,

			cnn_conv0_output_dims, cnn_conv0_output_data,
			cnn_pool0_output_dims, cnn_pool0_output_data,
			cnn_conv1_output_dims, cnn_conv1_output_data,
			cnn_pool1_output_dims, cnn_pool1_output_data,
			cnn_dense0_input_dims, 
			cnn_dense0_output_dims, cnn_dense0_output_data,
			cnn_dense1_output_dims, cnn_dense1_output_data
		);
	#elif defined(CNNNEW_TEST)
		print("CNNNEW_TEST\n");
		testInference_CNNNEW_MNISTModel_Accel(
			test_images, test_labels, number_of_test, 
			model_input_dims, 

			cnnnew_conv0_ps_data, cnnnew_conv1_ps_data, 
			cnnnew_dense0_ps_data,

			cnnnew_conv0_output_multiplier, cnnnew_conv0_output_shift,
			cnnnew_conv1_output_multiplier, cnnnew_conv1_output_shift,
			cnnnew_dense0_output_multiplier,  cnnnew_dense0_output_shift,

			cnnnew_conv0_kernel_dims, cnnnew_conv0_kernel_data,
			cnnnew_conv0_bias_dims, cnnnew_conv0_bias_data,

			cnnnew_conv1_kernel_dims, cnnnew_conv1_kernel_data,
			cnnnew_conv1_bias_dims, cnnnew_conv1_bias_data,

			cnnnew_dense0_weight_dims, cnnnew_dense0_weight_data,
			cnnnew_dense0_bias_dims, cnnnew_dense0_bias_data,

			cnnnew_conv0_output_dims, cnnnew_conv0_output_data,
			cnnnew_pool0_output_dims, cnnnew_pool0_output_data,
			cnnnew_conv1_output_dims, cnnnew_conv1_output_data,
			cnnnew_pool1_output_dims, cnnnew_pool1_output_data,
			cnnnew_dense0_input_dims, 
			cnnnew_dense0_output_dims, cnnnew_dense0_output_data
		);
	#elif defined(CNNNEW_RUN)
		print("CNNNEW_RUN\n");
		testInference_CNNNEW_MNISTModel_Accel(
			(void*)reg_ifm_addr, test_labels, number_of_test, 
			model_input_dims, 

			cnnnew_conv0_ps_data, cnnnew_conv1_ps_data, 
			cnnnew_dense0_ps_data, 

			cnnnew_conv0_output_multiplier, cnnnew_conv0_output_shift,
			cnnnew_conv1_output_multiplier, cnnnew_conv1_output_shift,
			cnnnew_dense0_output_multiplier,  cnnnew_dense0_output_shift,

			cnnnew_conv0_kernel_dims, cnnnew_conv0_kernel_data,
			cnnnew_conv0_bias_dims, cnnnew_conv0_bias_data,

			cnnnew_conv1_kernel_dims, cnnnew_conv1_kernel_data,
			cnnnew_conv1_bias_dims, cnnnew_conv1_bias_data,

			cnnnew_dense0_weight_dims, cnnnew_dense0_weight_data,
			cnnnew_dense0_bias_dims, cnnnew_dense0_bias_data,

			cnnnew_conv0_output_dims, cnnnew_conv0_output_data,
			cnnnew_pool0_output_dims, cnnnew_pool0_output_data,
			cnnnew_conv1_output_dims, cnnnew_conv1_output_data,
			cnnnew_pool1_output_dims, cnnnew_pool1_output_data,
			cnnnew_dense0_input_dims, 
			cnnnew_dense0_output_dims, cnnnew_dense0_output_data
		);
	#endif
}

void setup() {
    reg_leds = 31;
    reg_uart_clkdiv = 104;
    print("AlPicoSoC booting..\n");

    reg_leds = 63;
    // set_flash_qspi_flag();

	reg_leds = 127;
	// set_flash_mode_qddr();

    reg_leds = 127;
	// cmd_print_spi_state();

	#if defined(LAYER_TEST)
		layer_test();
	#elif defined(MODEL_TEST) || defined(MODEL_RUN) || defined(CNN_TEST) || defined(CNN_RUN) || defined(CNNNEW_TEST) || defined(CNNNEW_RUN) 
		model_test();
	#endif
	reg_leds = 127;
}

void loop() {
    // print("Loop\n");
	// putchar('\n');
	// print("  ____  _          ____         ____\n");
	// print(" |  _ \\(_) ___ ___/ ___|  ___  / ___|\n");
	// print(" | |_) | |/ __/ _ \\___ \\ / _ \\| |\n");
	// print(" |  __/| | (_| (_) |__) | (_) | |___\n");
	// print(" |_|   |_|\\___\\___/____/ \\___/ \\____|\n");
	// print("\n");
	// print("Total memory: ");
	// print_dec(MEM_TOTAL / 1024);
	// print(" KiB\n");
	// print("\n");
	for (int i = 0; i < 100000; i++);
	reg_leds = ~reg_leds;
}

// -------------------------------------------------------- //
// ******************************************************** //

int main() {
    setup();
    while(1) {
        loop();
    }
	return 0;
}