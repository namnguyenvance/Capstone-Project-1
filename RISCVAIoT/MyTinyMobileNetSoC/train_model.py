#!/usr/bin/env python3
"""
TinyMobileNet Training Script for MNIST
========================================

Trains a small MobileNet-inspired model on MNIST and exports a quantized int8 TFLite model.

Architecture:
    Input 28x28x1
    → Conv2D 3x3, 16 filters, stride 1, padding same, ReLU6
    → DepthwiseConv2D 3x3, stride 1, padding same, ReLU6
    → Conv2D 1x1, 32 filters (Pointwise), ReLU6
    → DepthwiseConv2D 3x3, stride 2, padding same, ReLU6
    → Conv2D 1x1, 48 filters (Pointwise), ReLU6
    → DepthwiseConv2D 3x3, stride 2, padding same, ReLU6
    → Conv2D 1x1, 64 filters (Pointwise), ReLU6
    → GlobalAveragePooling2D
    → Dense 10 (softmax)

Usage:
    python3 train_model.py

Output:
    tinymobilenet_mnist_quant.tflite
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np
import os

# ============================================================
# 1. Load MNIST
# ============================================================
print("Loading MNIST dataset...")
(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()

# Reshape to add channel dimension: (N, 28, 28) → (N, 28, 28, 1)
x_train = x_train.reshape(-1, 28, 28, 1).astype('float32') / 255.0
x_test = x_test.reshape(-1, 28, 28, 1).astype('float32') / 255.0
y_train = y_train.flatten()
y_test = y_test.flatten()

print(f"Train: {x_train.shape}, Test: {x_test.shape}")

# ============================================================
# 2. Build TinyMobileNet Model
# ============================================================
print("\nBuilding TinyMobileNet model...")


def build_tiny_mobilenet(input_shape=(28, 28, 1), num_classes=10):
    inputs = keras.Input(shape=input_shape)

    # Initial Conv: 3x3, stride 1, same padding → 28x28x16
    x = layers.Conv2D(16, 3, strides=1, padding='same', use_bias=True)(inputs)
    x = layers.ReLU(max_value=6)(x)  # ReLU6

    # DW Block 1: DW 3x3 s1 → PW 1x1 16→32
    x = layers.DepthwiseConv2D(3, strides=1, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)
    x = layers.Conv2D(32, 1, strides=1, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)

    # DW Block 2: DW 3x3 s2 → PW 1x1 32→48
    x = layers.DepthwiseConv2D(3, strides=2, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)
    x = layers.Conv2D(48, 1, strides=1, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)

    # DW Block 3: DW 3x3 s2 → PW 1x1 48→64
    x = layers.DepthwiseConv2D(3, strides=2, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)
    x = layers.Conv2D(64, 1, strides=1, padding='same', use_bias=True)(x)
    x = layers.ReLU(max_value=6)(x)

    # Global Average Pooling → FC
    x = layers.GlobalAveragePooling2D()(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)

    model = keras.Model(inputs=inputs, outputs=outputs)
    return model


model = build_tiny_mobilenet()
model.summary()

# ============================================================
# 3. Train
# ============================================================
print("\nTraining TinyMobileNet on MNIST...")

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

history = model.fit(
    x_train, y_train,
    batch_size=64,
    epochs=10,  # MNIST converges fast, 10 epochs is enough
    validation_data=(x_test, y_test),
    verbose=1
)

# Evaluate
test_loss, test_acc = model.evaluate(x_test, y_test, verbose=0)
print(f"\nFloat model test accuracy: {test_acc:.4f}")

# Save float model
model.save("tinymobilenet_mnist_float.keras")
print("Saved float model: tinymobilenet_mnist_float.keras")

# ============================================================
# 4. Quantize to int8 using TFLite
# ============================================================
print("\nQuantizing model to int8...")


def representative_dataset():
    """Representative dataset for full integer quantization."""
    for i in range(200):
        sample = x_train[i:i + 1].astype(np.float32)
        yield [sample]


converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8

tflite_model = converter.convert()

tflite_path = "tinymobilenet_mnist_quant.tflite"
with open(tflite_path, "wb") as f:
    f.write(tflite_model)

print(f"Saved quantized model: {tflite_path}")
print(f"Model size: {len(tflite_model)} bytes ({len(tflite_model)/1024:.1f} KB)")

# ============================================================
# 5. Verify quantized model accuracy
# ============================================================
print("\nVerifying quantized model...")

interpreter = tf.lite.Interpreter(model_content=tflite_model)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

input_scale = input_details[0]['quantization'][0]
input_zero_point = input_details[0]['quantization'][1]
output_scale = output_details[0]['quantization'][0]
output_zero_point = output_details[0]['quantization'][1]

print(f"Input: scale={input_scale}, zero_point={input_zero_point}")
print(f"Output: scale={output_scale}, zero_point={output_zero_point}")

correct = 0
total = min(1000, len(x_test))

for i in range(total):
    # Quantize input
    img = x_test[i:i + 1]
    img_quant = (img / input_scale + input_zero_point).astype(np.int8)

    interpreter.set_tensor(input_details[0]['index'], img_quant)
    interpreter.invoke()

    output = interpreter.get_tensor(output_details[0]['index'])
    predicted = np.argmax(output)

    if predicted == y_test[i]:
        correct += 1

print(f"Quantized model accuracy (first {total} test images): {correct}/{total} = {correct / total:.4f}")
print("\nDone! Next step: run generate_model_data.py")
