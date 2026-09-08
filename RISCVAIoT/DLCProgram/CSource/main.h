#ifndef MAIN_H
#define MAIN_H

#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <limits.h>
#include <assert.h>
#include "dl_ops.h"
#include "quantize.h"
#include "ulti.h"

#if defined(CL_TC0) || defined(CL_TC1) || defined(CL_TC2) || defined(CL_TC3) || defined(CL_TC4) || defined(CL_TC5)
    #define CONV_LAYER_TEST
#elif defined(FCL_TC0) || defined(FCL_TC1)
    #define DENSE_LAYER_TEST
#elif defined(PL_TC0) || defined(PL_TC1) || defined(PL_TC2) 
    #define POOL_LAYER_TEST
#endif

#include "mnist_model_data.h"
#include "mnist_input_data.h"
#include "lenet_model_data.h"
#include "cnn_model_data.h"
#include "cnnnew_model_data.h"

#include "layer_CONV_data.h"
#include "layer_DENSE_data.h"
#include "layer_POOL_data.h"

#endif