#!/usr/bin/env python3
"""
Extract CIFAR-10 test images for SoC inference.
================================================

Loads CIFAR-10 test set, quantizes selected images to int8,
and exports them as a C header file.

Usage:
    python extract_cifar_test.py

Output:
    cifar_test_images.h
"""

import numpy as np
import sys

try:
    import tensorflow as tf
except ImportError:
    print("ERROR: tensorflow required. Install with: pip install tensorflow")
    sys.exit(1)

NUM_TEST_IMAGES = 5
TFLITE_MODEL = "tinymobilenet_cifar10_quant.tflite"
OUTPUT_FILE = "cifar_test_images.h"

CIFAR10_CLASSES = [
    "airplane", "automobile", "bird", "cat", "deer",
    "dog", "frog", "horse", "ship", "truck"
]


def main():
    # Load CIFAR-10
    print("Loading CIFAR-10 test set...")
    (_, _), (x_test, y_test) = tf.keras.datasets.cifar10.load_data()
    x_test = x_test.astype('float32') / 255.0
    y_test = y_test.flatten()

    # Load TFLite model for input quantization params
    print(f"Loading {TFLITE_MODEL} for quantization parameters...")
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    
    input_scale = input_details[0]['quantization'][0]
    input_zp = input_details[0]['quantization'][1]
    print(f"Input quantization: scale={input_scale:.6f}, zero_point={input_zp}")

    # Select diverse test images (one from each class if possible)
    selected_indices = []
    classes_found = set()
    
    for i in range(len(y_test)):
        cls = y_test[i]
        if cls not in classes_found and len(selected_indices) < NUM_TEST_IMAGES:
            selected_indices.append(i)
            classes_found.add(cls)
        if len(selected_indices) >= NUM_TEST_IMAGES:
            break

    # If we didn't find enough diverse classes, fill with whatever
    if len(selected_indices) < NUM_TEST_IMAGES:
        for i in range(len(y_test)):
            if i not in selected_indices:
                selected_indices.append(i)
            if len(selected_indices) >= NUM_TEST_IMAGES:
                break

    print(f"\nSelected {len(selected_indices)} test images:")
    for idx in selected_indices:
        print(f"  Image {idx}: class {y_test[idx]} ({CIFAR10_CLASSES[y_test[idx]]})")

    # Verify with TFLite interpreter
    print("\nVerifying with TFLite interpreter...")
    output_details = interpreter.get_output_details()
    
    for idx in selected_indices:
        img = x_test[idx:idx+1]
        img_quant = np.clip(img / input_scale + input_zp, -128, 127).astype(np.int8)
        
        interpreter.set_tensor(input_details[0]['index'], img_quant)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        predicted = np.argmax(output)
        
        print(f"  Image {idx}: true={CIFAR10_CLASSES[y_test[idx]]}, "
              f"predicted={CIFAR10_CLASSES[predicted]}, "
              f"{'OK' if predicted == y_test[idx] else 'MISMATCH'}")

    # Generate C header
    print(f"\nGenerating {OUTPUT_FILE}...")
    
    with open(OUTPUT_FILE, "w") as f:
        f.write("/* Auto-generated CIFAR-10 test images (int8 quantized) */\n")
        f.write("#ifndef CIFAR_TEST_IMAGES_H\n")
        f.write("#define CIFAR_TEST_IMAGES_H\n\n")
        f.write("#include <stdint.h>\n\n")
        
        f.write(f"const int number_of_test = {NUM_TEST_IMAGES};\n\n")
        
        # Labels
        labels = [int(y_test[idx]) for idx in selected_indices]
        f.write(f"const int8_t test_labels[] = {{{', '.join(str(l) for l in labels)}}};\n\n")
        
        # Images: quantized to int8, stored as CHW (channel-first) layout
        # Matching our C firmware's expected format
        f.write(f"const int8_t test_images[{NUM_TEST_IMAGES}][32 * 32 * 3] = {{\n")
        
        for img_num, idx in enumerate(selected_indices):
            img = x_test[idx]  # Shape: [32, 32, 3], float [0,1]
            
            # Quantize
            img_quant = np.clip(img / input_scale + input_zp, -128, 127).astype(np.int8)
            
            # Transpose from HWC to CHW for our C code
            img_chw = np.transpose(img_quant, (2, 0, 1))  # [3, 32, 32]
            flat = img_chw.flatten()
            
            f.write(f"    /* Image {img_num}: {CIFAR10_CLASSES[y_test[idx]]} (index {idx}) */\n")
            f.write("    {\n        ")
            for i, val in enumerate(flat):
                f.write(f"{val}, ")
                if (i + 1) % 32 == 0:
                    f.write("\n        ")
            f.write("\n    },\n")
        
        f.write("};\n\n")
        f.write("#endif /* CIFAR_TEST_IMAGES_H */\n")

    import os
    print(f"Successfully generated {OUTPUT_FILE}!")
    print(f"File size: {os.path.getsize(OUTPUT_FILE)} bytes")
    print("\nReady to compile! Run: make sim")


if __name__ == "__main__":
    main()
