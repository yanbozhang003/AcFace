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

import argparse

from data_loader import AudioFaceDataset
from models import RDNet
from train import Trainer
from test import Tester

def main(args):
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
    data_train = AudioFaceDataset(args.data_dir, split='train')
    data_test = AudioFaceDataset(args.data_dir, split='test')

    batch_size = args.batch_size  # Specify your batch size
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
    
    if args.mode == 'train':
        Trainer(model, data_train_loader, device, args).train()
        pass
    elif args.mode == 'test':
        Tester(model, data_test_loader, device, args).test()
        pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train/Test RDNet')
    parser.add_argument('--mode', type=str, required=True, help='Operation mode: train or test')
    parser.add_argument('--data_dir', type=str, default='./data', help='Directory for data')
    parser.add_argument('--batch_size', type=int, default=32, help='Batch size for training')
    parser.add_argument('--learning_rate', type=float, default=0.001, help='Learning rate for training')
    parser.add_argument('--training_epochs', type=int, default=10, help='Number of training epochs')
    parser.add_argument('--save_model', type=str, default='./model.pth', help='Path to save the trained model', required=False)
    parser.add_argument('--model_path', type=str, help='Path to load the model for testing', required=False)
    args = parser.parse_args()

    main(args)
