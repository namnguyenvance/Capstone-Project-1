#!/usr/bin/env python3

from sys import argv

if (len(argv) < 4):
    raise Exception("Not enough argument")
    
hex_file = argv[1]
c_file   = argv[2]
h_file   = argv[3]

h_file_name = h_file.split('/')[-1]

with open(hex_file, "rb") as hex_f:
    hex_data = hex_f.read()
    
# Chuyển đổi hex_data từ bytes sang string
hex_data = hex_data.decode('utf-8')  # hoặc 'ascii' nếu phù hợp hơn
addr_list = []
hex_line_list = hex_data.split("\r\n")

h_macro_prefix = h_file_name.upper().replace('.', '_')

H_MACRO = [
    "#ifndef __" + h_macro_prefix + "_\n",
    "#define __" + h_macro_prefix + "_\n",
    "#endif"
]
H_UTIL = [
    "extern ", 
    [
        "const unsigned int ",
        ";\n"
    ],
    [
        "const unsigned int ",
        "[",
        "];\n"    
    ], 
]

C_HEADER_INCLUDE = "#include \"" + h_file_name + "\"\n"
C_ARRAY_UTIL  = [
    [
        "const unsigned int ",
        " = ", 
        ";\n"
    ],
    [
        "const unsigned int ",
        "[",
        "] = {\n",
        "\n};"    
    ], 
]
C_ARRAY_NAME  = "fw_hex_data"
C_ARRAY_LEN   = C_ARRAY_NAME + "_len"
C_ARRAY_ELEM  = ""
C_ARRAY_SIZE  = 0
for line in hex_line_list:
    hex_word_list = line.split(" ")

    if (len(hex_word_list) > 1):
        n_ele = int((len(hex_word_list) - 1) / 4)  # Chuyển đổi thành int

        C_ARRAY_ELEM  += "\t"
        C_ARRAY_SIZE += n_ele
        for idx in range(n_ele):
            C_ARRAY_ELEM  += "0x" \
                        + hex_word_list[4*idx + 3] \
                        + hex_word_list[4*idx + 2] \
                        + hex_word_list[4*idx + 1] \
                        + hex_word_list[4*idx    ] \
                        + (",\n" if (idx == n_ele - 1) else ", ")

    elif (len(hex_word_list) == 1 and len(hex_word_list[0])):
        addr_list.append(hex_word_list[0])

C_ARRAY_ELEM = C_ARRAY_ELEM[:-2] # Ignore "," and "\n" character
C_ARRAY_SIZE = str(C_ARRAY_SIZE)

C_ARRAY_LEN_DEFINE  = C_ARRAY_UTIL[0][0] + C_ARRAY_LEN \
                    + C_ARRAY_UTIL[0][1] + C_ARRAY_SIZE \
                    + C_ARRAY_UTIL[0][2]
C_ARRAY_STR_DEFINE  = C_ARRAY_UTIL[1][0] + C_ARRAY_NAME \
                    + C_ARRAY_UTIL[1][1] + C_ARRAY_SIZE \
                    + C_ARRAY_UTIL[1][2] + C_ARRAY_ELEM \
                    + C_ARRAY_UTIL[1][3]
                    
H_ARRAY_LEN_DEFINE  = H_UTIL[0] + H_UTIL[1][0] + C_ARRAY_LEN \
                    + H_UTIL[1][1]
H_ARRAY_STR_DEFINE  = H_UTIL[0] + H_UTIL[2][0] + C_ARRAY_NAME \
                    + H_UTIL[2][1] + C_ARRAY_SIZE \
                    + H_UTIL[2][2]

with open(c_file, "w") as c_f:
    c_f.write(C_HEADER_INCLUDE)
    c_f.write('\n')
    c_f.write(C_ARRAY_LEN_DEFINE)
    c_f.write('\n')
    c_f.write(C_ARRAY_STR_DEFINE)

with open(h_file, "w") as h_f:
    h_f.write(H_MACRO[0])
    h_f.write(H_MACRO[1])
    h_f.write('\n')
    h_f.write(H_ARRAY_LEN_DEFINE)
    h_f.write(H_ARRAY_STR_DEFINE)
    h_f.write('\n')
    h_f.write(H_MACRO[2])
