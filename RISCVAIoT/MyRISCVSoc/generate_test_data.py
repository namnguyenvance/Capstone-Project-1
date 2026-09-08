def generate_conv_data():
    # 1. Define a 5x5 Input Image (represented as 2D list of integers)
    # Using simple numbers from 1 to 25 to make it easy to follow
    image = [
        [1,  2,  3,  4,  5],
        [6,  7,  8,  9,  10],
        [11, 12, 13, 14, 15],
        [16, 17, 18, 19, 20],
        [21, 22, 23, 24, 25]
    ]

    # 2. Define a 3x3 Filter Kernel
    # A simple vertical edge detector (Sobel-like filter)
    kernel = [
        [1,  0, -1],
        [2,  0, -2],
        [1,  0, -1]
    ]

    # 3. Perform 2D Convolution (Valid padding, stride = 1)
    # Output size: (5 - 3 + 1) x (5 - 3 + 1) = 3x3
    img_h, img_w = 5, 5
    ker_h, ker_w = 3, 3
    out_h = img_h - ker_h + 1
    out_w = img_w - ker_w + 1
    
    output = [[0 for _ in range(out_w)] for _ in range(out_h)]
    
    for r in range(out_h):
        for c in range(out_w):
            total_sum = 0
            for kr in range(ker_h):
                for kc in range(ker_w):
                    # Multiplicand from image
                    val_img = image[r + kr][c + kc]
                    # Multiplier from kernel
                    val_ker = kernel[kr][kc]
                    total_sum += val_img * val_ker
            output[r][c] = total_sum

    # 4. Generate C Header File content
    header_content = []
    header_content.append("/* Generated automatically by generate_test_data.py */")
    header_content.append("#ifndef CONV_DATA_H")
    header_content.append("#define CONV_DATA_H")
    header_content.append("")
    header_content.append("#define IMG_ROWS 5")
    header_content.append("#define IMG_COLS 5")
    header_content.append("#define KERNEL_SIZE 3")
    header_content.append("#define OUT_ROWS 3")
    header_content.append("#define OUT_COLS 3")
    header_content.append("")

    # Flatten image to 1D C array
    img_flat = [val for row in image for val in row]
    img_str = ", ".join(map(str, img_flat))
    header_content.append(f"const int input_matrix[25] = {{ {img_str} }};")

    # Flatten kernel to 1D C array
    ker_flat = [val for row in kernel for val in row]
    ker_str = ", ".join(map(str, ker_flat))
    header_content.append(f"const int conv_kernel[9] = {{ {ker_str} }};")

    # Flatten golden output to 1D C array
    out_flat = [val for row in output for val in row]
    out_str = ", ".join(map(str, out_flat))
    header_content.append(f"const int golden_output[9] = {{ {out_str} }};")
    
    header_content.append("")
    header_content.append("#endif // CONV_DATA_H")

    # Write to conv_data.h
    with open("conv_data.h", "w") as f:
        f.write("\n".join(header_content))

    print("Successfully generated conv_data.h!")
    print("--- 5x5 Input Image ---")
    for row in image:
        print(row)
    print("\n--- 3x3 Kernel ---")
    for row in kernel:
        print(row)
    print("\n--- 3x3 Expected Output (Golden Output) ---")
    for row in output:
        print(row)

if __name__ == "__main__":
    generate_conv_data()
