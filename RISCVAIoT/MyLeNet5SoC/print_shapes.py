import numpy as np
import os

MODEL_PARAM_DIR = "../DLCProgram/JupyterNotebook/customized_LeNet5_model_parameters/"

for file in sorted(os.listdir(MODEL_PARAM_DIR)):
    if file.endswith(".npy"):
        data = np.load(os.path.join(MODEL_PARAM_DIR, file))
        print(f"{file}: shape {data.shape}, dtype {data.dtype}")
