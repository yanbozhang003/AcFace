#!/bin/bash

# Default values for arguments
DATA_DIR="./data"
BATCH_SIZE=32
LEARNING_RATE=0.001
TRAINING_EPOCHS=10
SAVE_MODEL="./model.pth"

while getopts ":d:b:l:e:m:" opt; do
  case ${opt} in
    d ) DATA_DIR=$OPTARG ;;
    b ) BATCH_SIZE=$OPTARG ;;
    l ) LEARNING_RATE=$OPTARG ;;
    e ) TRAINING_EPOCHS=$OPTARG ;;
    m ) SAVE_MODEL=$OPTARG ;;
    \? ) echo "Usage: cmd [-d data_dir] [-b batch_size] [-l learning_rate] [-e training_epochs] [-m save_model]"
         exit 1 ;;
  esac
done

python RDNet_train_test.py --mode train --data_dir $DATA_DIR --batch_size $BATCH_SIZE --learning_rate $LEARNING_RATE --training_epochs $TRAINING_EPOCHS --save_model $SAVE_MODEL