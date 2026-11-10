import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path="tinymobilenet_mnist_quant.tflite")
interpreter.allocate_tensors()

for op in interpreter._get_ops_details():
    print(f"Op: {op['op_name']}")
    for idx in op['inputs']:
        t = interpreter.get_tensor_details()[idx]
        print(f"  Input {idx}: {t['name']} shape={t['shape']} q={t['quantization']}")
    for idx in op['outputs']:
        t = interpreter.get_tensor_details()[idx]
        print(f"  Output {idx}: {t['name']} shape={t['shape']} q={t['quantization']}")
