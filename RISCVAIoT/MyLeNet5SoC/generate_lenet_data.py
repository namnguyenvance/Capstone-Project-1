import struct
import ast
import os

MODEL_PARAM_DIR = "../DLCProgram/JupyterNotebook/customized_LeNet5_model_parameters/"

def read_npy(filepath):
    with open(filepath, 'rb') as f:
        magic = f.read(6)
        if magic != b'\x93NUMPY':
            raise ValueError("Not a .npy file")
        major, minor = struct.unpack('<BB', f.read(2))
        header_len = struct.unpack('<H', f.read(2))[0]
        header = f.read(header_len).decode('ascii')
        header_dict = ast.literal_eval(header)
        
        dtype = header_dict['descr']
        shape = header_dict['shape']
        if not shape:
            shape = (1,)
            
        data = f.read()
        num_elements = 1
        for s in shape:
            num_elements *= s
            
        if dtype in ('|i1', '<i1'):
            values = struct.unpack(f'<{num_elements}b', data)
            c_type = "int8_t"
        elif dtype == '<i4':
            values = struct.unpack(f'<{num_elements}i', data)
            c_type = "int32_t"
        else:
            raise ValueError(f"Unsupported dtype: {dtype}")
            
        return shape, values, c_type

def generate_c_array(name, values, c_type):
    arr_str = f"const {c_type} {name}[{len(values)}] = {{\n    "
    for i, val in enumerate(values):
        arr_str += f"{val}, "
        if (i + 1) % 16 == 0:
            arr_str += "\n    "
    arr_str = arr_str.rstrip(", \n ") + "\n};\n\n"
    return arr_str

with open("lenet_data.h", "w") as out:
    out.write("#ifndef LENET_DATA_H\n#define LENET_DATA_H\n\n#include <stdint.h>\n\n")
    
    files_to_parse = [
        ("conv0_w", "lenet_conv0_kernel_tensor.npy"),
        ("conv0_b", "lenet_conv0_bias_tensor.npy"),
        ("conv1_w", "lenet_conv1_kernel_tensor.npy"),
        ("conv1_b", "lenet_conv1_bias_tensor.npy"),
        ("dense0_w", "lenet_dense0_weight_tensor.npy"),
        ("dense0_b", "lenet_dense0_bias_tensor.npy"),
        ("dense1_w", "lenet_dense1_weight_tensor.npy"),
        ("dense1_b", "lenet_dense1_bias_tensor.npy"),
        ("dense2_w", "lenet_dense2_weight_tensor.npy"),
        ("dense2_b", "lenet_dense2_bias_tensor.npy"),
    ]
    
    for c_name, filename in files_to_parse:
        shape, values, c_type = read_npy(os.path.join(MODEL_PARAM_DIR, filename))
        print(f"Parsed {filename}: shape={shape}, type={c_type}")
        out.write(f"// Shape: {shape}\n")
        out.write(generate_c_array(c_name, values, c_type))
        
    # Generate dummy 28x28 image (a simple vertical line for digit 1)
    dummy_img = [0] * (28 * 28)
    for i in range(5, 25):
        dummy_img[i * 28 + 14] = 100
    
    out.write("// Dummy test image 28x28\n")
    out.write(generate_c_array("test_image", dummy_img, "int8_t"))
    
    out.write("#endif\n")

print("Successfully generated lenet_data.h!")
