# MAIN_OBJS = CSource/quantize.c CSource/dl_ops.c CSource/ulti.c \
# 			CSource/mnist_model_data.c 	CSource/mnist_input_data.c \
# 			CSource/lenet_model_data.c \
# 			CSource/layer_CONV_data.c	CSource/layer_DENSE_data.c	CSource/layer_POOL_data.c \
# 			CSource/main.c 
# MAIN_OBJS = CSource/quantize.c CSource/dl_ops.c CSource/ulti.c \
# 			CSource/mnist_model_data.c 	CSource/mnist_input_data.c \
# 			CSource/cnn_model_data.c \
# 			CSource/layer_CONV_data.c	CSource/layer_DENSE_data.c	CSource/layer_POOL_data.c \
# 			CSource/main.c 
MAIN_OBJS = CSource/quantize.c CSource/dl_ops.c CSource/ulti.c \
			CSource/mnist_model_data.c 	CSource/mnist_input_data.c \
			CSource/cnnnew_model_data.c \
			CSource/main.c 

# TD = MODEL_TEST
TD = NON
# Demo function
main: main.o
	./main.o > out.log
	rm main.o

main.o: $(MAIN_OBJS)
	gcc $^ -D$(TD) -o main.o

clean: 
	rm *.o