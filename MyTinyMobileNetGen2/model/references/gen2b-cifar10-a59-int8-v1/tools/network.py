"""Independent RGB topology. TensorFlow is required only for ML commands."""
EXPECTED = [(32,32,3),(32,32,16),(32,32,16),(32,32,32),
            (16,16,32),(16,16,48),(8,8,48),(8,8,64),(64,),(10,)]

def build(tf):
    k=tf.keras
    x=k.Input((32,32,3),name='rgb'); y=x
    for name,kind,channels,stride in [
        ('conv0','conv',16,1),('dw1','dw',16,1),('pw1','pw',32,1),
        ('dw2','dw',32,2),('pw2','pw',48,1),('dw3','dw',48,2),('pw3','pw',64,1)]:
        if kind=='dw':
            y=k.layers.DepthwiseConv2D(3,strides=stride,padding='same',use_bias=True,name=name)(y)
        else:
            y=k.layers.Conv2D(channels,1 if kind=='pw' else 3,strides=stride,
                              padding='same',use_bias=True,name=name)(y)
        y=k.layers.ReLU(max_value=6,name=name+'_relu6')(y)
    y=k.layers.GlobalAveragePooling2D(name='gap')(y)
    y=k.layers.Dense(10,name='logits')(y)
    model=k.Model(x,y,name='gen2_rgb')
    shapes=[tuple(model.input.shape[1:])]+[tuple(model.get_layer(n).output.shape[1:]) for n in
        ['conv0_relu6','dw1_relu6','pw1_relu6','dw2_relu6','pw2_relu6','dw3_relu6','pw3_relu6','gap','logits']]
    if shapes != EXPECTED:
        raise ValueError(f'Actual Keras shapes differ: {shapes}')
    if model.count_params()!=7322:
        raise ValueError(f'Unexpected parameter count: {model.count_params()}')
    return model,shapes
