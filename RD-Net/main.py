import torch
from torch.autograd import Variable
import torchvision.datasets as dsets
import torchvision.transforms as transforms
import torch.nn.init
from scipy.io import loadmat
import numpy as np
import pandas as pd
from pathlib import Path
from torch.utils.data import Dataset, DataLoader

from data_loader import AudioFaceDataset
from models import RDNet
from train import Trainer
from test import Tester

def main():
    # Preparing GPU
    torch.cuda.is_available()
    n_gpu = torch.cuda.device_count()
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

    t = torch.cuda.get_device_properties(0).total_memory
    r = torch.cuda.memory_reserved(0)
    a = torch.cuda.memory_allocated(0)
    f = r-a
    print("Number of GPU: ", n_gpu, type(device))
    print("total GPU memory: ", t, " memory reserved: ", r, "memory allocated: ", a)
    
    # Initialize data loader
    data_dir = './Dataset/samples_all'
    data_train = AudioFaceDataset(data_dir, split='train')
    data_test = AudioFaceDataset(data_dir, split='test')

    batch_size = 128  # Specify your batch size
    data_train_loader = DataLoader(dataset=data_train,
                                batch_size=batch_size,
                                shuffle=True,
                                num_workers=8)

    data_test_loader = DataLoader(dataset=data_test,
                                batch_size=batch_size,
                                shuffle=True, 
                                num_workers=8)

    print("Data loader setup complete.")
    
    # Initialize the model
    model = RDNet().to(device)

    param_size = sum(p.numel() * p.element_size() for p in model.parameters())
    buffer_size = sum(b.numel() * b.element_size() for b in model.buffers())
    total_size = param_size + buffer_size
    
    # Train the model
    Trainer(model, data_train_loader, device)
    
    # Test the model
    Tester(model, data_test_loader, device)

if __name__ == '__main__':
    main()
