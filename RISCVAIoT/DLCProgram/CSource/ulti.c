#include "ulti.h"

void printArray4DI(const int8_t* arr, const int* dims) {
    for (int channel = 0; channel < dims[3]; ++channel) {
        printf("Channel = %d\n", channel);
        printArray3DI(arr + channel * dims[2] * dims[1] * dims[0], dims);
        printf("End Channel %d\n", channel);
    }
}

void printArray3DI(const int8_t* arr, const int* dims) {
    for (int z_i = 0; z_i < dims[2]; ++z_i) {
        printf("  z = %d\n", z_i);
        printArray2DI(arr + z_i * dims[1] * dims[0], dims);
        printf("\n");
    }
}

void printArray2DI(const int8_t* arr, const int* dims) {
    for (int y_i = 0; y_i < dims[1]; ++y_i) {
        printArray1DI(arr + y_i * dims[0], dims[0]);
    }
}

void printArray1DI(const int8_t* arr, const int len) {
    printf("[");
    for (int i = 0; i < len; ++i) {
        int val = arr[i] + 128;
        if (val > 99) 
            printf("%d", val);
        else if (val > 9) 
            printf(" %d", val);
        else
            printf("  %d", val);

        if (i != len - 1) printf(" ");
        // printf("%d ", arr[i] + 128);
        // printf("\t%d ", arr[i]);
    } 
    printf("]\n");
}

void printArray3DIH(const int8_t* arr, const int* dims) {
    for (int z_i = 0; z_i < dims[2]; ++z_i) {
        printf("  z = %d\n", z_i);
        printArray2DIH(arr + z_i * dims[1] * dims[0], dims);
        printf("\n");
    }
}

void printArray2DIH(const int8_t* arr, const int* dims) {
    for (int y_i = 0; y_i < dims[1]; ++y_i) {
        printArray1DIH(arr + y_i * dims[0], dims[0]);
    }
}

void printArray1DIH(const int8_t* arr, const int len) {
    for (int i = 0; i < len; ++i) {
        printf("\t%08x", arr[i]);
    } 
    printf("\n");
}

void printArray1DI32(const int32_t* arr, const int len) {
    for (int i = 0; i < len; ++i) {
        printf("\t%d", arr[i]);
    } 
    printf("\n");
}

// void printArray4DF(const float* arr, const int* dims) {
//     for (int channel = 0; channel < dims[3]; ++channel) {
//         printf("Channel = %d\n", channel);
//         printArray3DF(arr + channel * dims[2] * dims[1] * dims[0], dims);
//         printf("End Channel %d\n", channel);
//     }
// }

// void printArray3DF(const float* arr, const int* dims) {
//     for (int z_i = 0; z_i < dims[2]; ++z_i) {
//         printf("  z = %d\n", z_i);
//         printArray2DF(arr + z_i * dims[1] * dims[0], dims);
//         printf("\n");
//     }
// }

// void printArray2DF(const float* arr, const int* dims) {
//     for (int y_i = 0; y_i < dims[1]; ++y_i) {
//         printArray1DF(arr + y_i * dims[0], dims[0]);
//     }
// }

// void printArray1DF(const float* arr, const int len) {
//     for (int i = 0; i < len; ++i) {
//         printf("\t%f", arr[i]);
//     } 
//     printf("\n");
// }

// Deep Learning Utility Function

int get_label(const int8_t model_output_data[], const int model_output_len) {
    // for (int i = 0; i < model_output_len; i++) 
    //     printf("%d ", model_output_data[i] + 128);
    // printf("\n");

    int8_t max_idx = 0;
    for (int idx = 1; idx < model_output_len; idx++) {
        // int val_0 = (model_output_data[idx] + 128) >= 4 ? model_output_data[idx] : 127;
        // int val_1 = (model_output_data[max_idx] + 128) >= 4 ? model_output_data[max_idx] : 127;
        // if (val_0 > val_1) max_idx = idx;
        if (model_output_data[idx] > model_output_data[max_idx]) max_idx = idx;
    }

    return max_idx;
}

// Get quantized value

// const double cnn_conv0_input_s = 0.003921568859368563;
// const double cnn_conv0_weight_s[32] = {
//     0.004661730490624905, 0.0013631293550133705, 0.003474307246506214, 0.001169819151982665,
//     0.003484762040898204, 0.0019467720994725823, 0.003588446183130145, 0.0008671164978295565,
//     0.0037607592530548573, 0.002154537010937929, 0.0009504713816568255, 0.002534351544454694,
//     0.003915398847311735, 0.00467744842171669, 0.0019737770780920982, 0.0019463051576167345,
//     0.0027922496665269136, 0.0009961541509255767, 0.000789758691098541, 0.000831367215141654,
//     0.0017299398314207792, 0.0039970120415091515, 0.003063331125304103, 0.0031536840833723545,
//     0.0012534994166344404, 0.000981368706561625, 0.002673485316336155, 0.0011172546073794365,
//     0.001013722037896514, 0.004352235235273838, 0.0031692644115537405, 0.002754974877461791
// };
// const double cnn_conv0_output_s = 0.005691605154424906;

// const double cnn_conv1_input_s = 0.005691605154424906;
// const double cnn_conv1_weight_s[32] = {
//     0.001007010811008513, 0.0036890199407935143, 0.004009665921330452, 0.003986130468547344,
//     0.004196186549961567, 0.0041740951128304005, 0.004489888437092304, 0.0030311651062220335,
//     0.0031566054094582796, 0.004015037789940834, 0.0009071845561265945, 0.0010031034471467137,
//     0.00424975948408246, 0.0010457104071974754, 0.0030714271124452353, 0.003924867603927851,
//     0.0009785263100638986, 0.003874726127833128, 0.0008719058241695166, 0.0033612267579883337,
//     0.0010252889478579164, 0.0050157345831394196, 0.0030815431382507086, 0.005519603379070759,
//     0.0038325318600982428, 0.0008007322903722525, 0.0010611711768433452, 0.0009097891161218286,
//     0.0009234079625457525, 0.004257400520145893, 0.002931097522377968, 0.0028193509206175804
// };
// const double cnn_conv1_output_s = 0.024571077898144722;

// const double cnn_dense0_input_s = 0.024571077898144722;
// const double cnn_dense0_weight_s = 0.004592573270201683;
// const double cnn_dense0_output_s = 0.06688600033521652;

// const double cnn_dense1_input_s = 0.06688600033521652;
// const double cnn_dense1_weight_s = 0.004823059309273958;
// const double cnn_dense1_output_s = 0.3374466896057129;

const double cnnnew_conv0_input_s = 0.003921568859368563;
const double cnnnew_conv0_weight_s[32] = {
    0.0034117833711206913, 0.002437792718410492, 0.004054579883813858, 0.002314450219273567, 
    0.001092398539185524, 0.003507507499307394, 0.0036449243780225515, 0.0008671164978295565, 
    0.0037986929528415203, 0.002600826555863023, 0.0009504713816568255, 0.003246112959459424, 
    0.004125118255615234, 0.00103653350379318, 0.0028793099336326122, 0.0021159490570425987, 
    0.0024478170089423656, 0.0049970392137765884, 0.000789758691098541, 0.000831367215141654, 
    0.002422082470729947, 0.004406844265758991, 0.0033320521470159292, 0.002733378205448389, 
    0.0021520790178328753, 0.000981368706561625, 0.0032160328701138496, 0.0010777373099699616, 
    0.001013722037896514, 0.003873599926009774, 0.004224742762744427, 0.0034477002918720245
};
const double cnnnew_conv0_output_s = 0.007330895867198706;

const double cnnnew_conv1_input_s = 0.007330895867198706;
const double cnnnew_conv1_weight_s[32] = {
    0.0009226310066878796, 0.005259892903268337, 0.004674466792494059, 0.0041705770418047905, 
    0.0009419990819878876, 0.004474060609936714, 0.0046455436386168, 0.0039512780494987965, 
    0.0031976355239748955, 0.005475620739161968, 0.0008455343195237219, 0.001012885244563222, 
    0.0047613815404474735, 0.0009283512481488287, 0.004576241597533226, 0.002918320009484887, 
    0.0009082189062610269, 0.0010910022538155317, 0.0009068790823221207, 0.0009505334892310202, 
    0.0030256176833063364, 0.005276343319565058, 0.0037396280094981194, 0.0034814197570085526, 
    0.002990330569446087, 0.0008007322903722525, 0.0034565648529678583, 0.0008513128268532455, 
    0.0036755092442035675, 0.003817749908193946, 0.0009371400810778141, 0.003372774925082922
};
const double cnnnew_conv1_output_s = 0.03521303832530975;

const double cnnnew_dense0_input_s = 0.03521303832530975;
const double cnnnew_dense0_weight_s = 0.004371915943920612;
const double cnnnew_dense0_output_s = 0.21187980473041534;

// Util Function
void dummy() {
    for (int i = 0; i < 32; i++) {
        double  a_s = cnnnew_conv1_input_s;
        double  b_s = cnnnew_conv1_weight_s[i];
        double  c_s = cnnnew_conv1_output_s;
        
        double double_mul = a_s * b_s / c_s;
        // printf("double_mul = %lf\n", double_mul);

        int32_t right_shift;
        int32_t q_mul;

        const double q = frexp(double_mul, &right_shift);
        right_shift = -right_shift;
        int64_t q_fixed = (int64_t)((q * (1LL << 31)));
        q_mul = (int32_t)q_fixed;
        printf("%d, ", q_mul);
        // printf("%d, ", right_shift);
        // printf("q_mul = %d\n", q_mul);
        // printf("right_shift = %d\n", right_shift);

        // int32_t a_test = 1;
        // int32_t b_test = 12554;
        // int32_t acc = (a_test + 128) * b_test;

        // int8_t O_q0, O_q1;
        // O_q0 = acc * double_mul;
        // O_q1 = MultiplyByQuantizedMultiplierSmallerThanOne(
        //     acc, q_mul, right_shift
        // );
        
        // printf("O_q0 = %d\n", O_q0);
        // printf("O_q1 = %d\n", O_q1);
    }
}
