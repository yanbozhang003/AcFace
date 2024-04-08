#!/bin/bash

# Default values for arguments
DATA_DIR="./data"
MODEL_PATH="./model.pth"

while getopts ":d:m:" opt; do
  case ${opt} in
    d ) DATA_DIR=$OPTARG ;;
    m ) MODEL_PATH=$OPTARG ;;
    \? ) echo "Usage: cmd [-d data_dir] [-m model_path]"
         exit 1 ;;
  esac
done

python RDNet_train_test.py --mode test --data_dir $DATA_DIR --model_path $MODEL_PATH