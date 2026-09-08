import os

C_FILE = "../DLCProgram/CSource/mnist_input_data.c"
OUT_FILE = "mnist_test_images.h"

def main():
    if not os.path.exists(C_FILE):
        print(f"Error: {C_FILE} not found!")
        return
        
    print(f"Reading {C_FILE}...")
    lines_to_write = []
    lines_to_write.append("/* Automatically extracted from mnist_input_data.c */")
    lines_to_write.append("#ifndef MNIST_TEST_IMAGES_H")
    lines_to_write.append("#define MNIST_TEST_IMAGES_H")
    lines_to_write.append("")
    lines_to_write.append("#include <stdint.h>")
    lines_to_write.append("")
    lines_to_write.append("const int model_input_dims[] = {28, 28, 1};")
    lines_to_write.append("const int number_of_test = 5;")
    
    # We want to extract the first 5 labels:
    # From line 6 of mnist_input_data.c:
    # const int8_t test_labels[] = { 7, 2, 1, 0, 4, ... }
    # So the first 5 labels are 7, 2, 1, 0, 4
    lines_to_write.append("const int8_t test_labels[] = {7, 2, 1, 0, 4};")
    lines_to_write.append("")
    lines_to_write.append("const int8_t test_images[][28 * 28 * 1] = {")
    
    # Now read the C file to grab the first 5 image arrays
    with open(C_FILE, "r") as f:
        in_images = False
        bracket_count = 0
        image_count = 0
        for line in f:
            if "test_images" in line and "=" in line:
                in_images = True
                continue
            if in_images:
                lines_to_write.append(line.rstrip())
                
                if line.startswith('\t{'):
                    bracket_count += 1
                
                if line.startswith('\t},'):
                    bracket_count -= 1
                    if bracket_count == 0: # Closed one image block
                        image_count += 1
                        if image_count == 5:
                            lines_to_write.append("};")
                            break
                            
    lines_to_write.append("#endif // MNIST_TEST_IMAGES_H")
    
    with open(OUT_FILE, "w") as out:
        out.write("\n".join(lines_to_write) + "\n")
        
    print(f"Successfully generated {OUT_FILE} with 5 test images!")

if __name__ == "__main__":
    main()
