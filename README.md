# AcFace

This project introduces a novel acoustic-based facial recognition system designed to deliver exceptional performance even under conditions where facial masks obscure parts of the face. The system is built around two primary components:

1. **Signal Processing Module**: This module processes raw acoustic signals to create precise 3D representations of faces. It is engineered to accurately capture facial features, ensuring the system's effectiveness even when traditional visual cues are partially hidden.

2. **Deep Learning Model**: This component is responsible for the recognition and differentiation of faces based on the 3D representations generated by the signal processing module. It has been meticulously trained to maintain high accuracy levels, specifically in scenarios involving facial masks.

The diagram below offers a visual overview of the system's architecture.

<div style="text-align: center;">
    <img src="https://github.com/yanbozhang003/AcFace-AE/blob/main/AcFace_structure.png" alt="Acface system structure" width="800" height="275"/>
</div>

Within this repository, we offer a comprehensive suite of tools required to deploy this system, including the signal processing algorithms essential for extracting facial spectrums and the deep learning framework for spectrum analysis and recognition. Furthermore, we have included a specially curated dataset to facilitate the evaluation of the system's performance across a diverse range of scenarios.

## Code overview

This section outlines the key components of our codebase and their functionalities. The implementations of the two primary components are introduced separately in below.

### Signal Processing Module

- `Spectrum derivation/get_tx_signal.m:` This file generates acoustic signal for facial scanning. It allows defining the scanning signal by considering various parameters including duration, cycles, bandwidth, center frequency, etc.

- `Spectrum derivation/audioRecorder.m:` This file connects the MINIDSP UMA-16 acoustic array to a PC to collect the facial reflected acoustic samples. It sets up a convenient method for data collection by leveraging MATLAB communication toolbox.  

- `Spectrum derivation/start_pcoc.m:` This file starts the processing flow for deriving facial spectrum. It takes in raw acoustic samples as input, together with multiple paramters that are defined by the actual hardware configurations and experiment settings, then starts signal processing flow including cir derivation and multipath recombining. It finally outputs the facial spectrums that characterizes the facial features of certain users. 

### Deep Learning Model

- `RD-Net/RDNet_train_test.py:` This file serves as the entry point for running the entire training and testing pipeline. It orchestrates the process from data loading to model evaluation, involving initialization of dataset loaders, model instantiation, training, and testing. This file ties all components together, facilitating an end-to-end execution of the RD-Net model.

- `RD-Net/model.py:` This file defines the architecture of RD-Net. It includes the ResidualBlock and RDNet classes, which together construct the backbone of our facial recognition model.

- `RD-Net/train.py:` This file encapsulates the training logic within the Trainer class, including model optimization and loss computation. It manages the training process over multiple epochs, leveraging backpropagation and gradient descent to minimize the loss function. Metrics such as accuracy and loss per batch/epoch are computed and displayed to monitor the training progress. 

- `RD-Net/test.py:` This file hosts the Tester class, which oversees the model evaluation on test data. This class is responsible for loading the trained model, executing the forward pass without gradient calculation, and computing key performance metrics such as accuracy, precision, recall, and F1-score.

- `RD-Net/data_loader.py:` This file defines the AudioFaceDataset class, responsible for loading and preprocessing the facial spectrum data. This class facilitates the creation of a dataset ready for input into the neural network, handling tasks such as signal normalization and transformation.

- `RD-Net/Eva_scripts/:` This folder contains Colab scripts that evaluate the performance of RD-Net from different aspects, including the robustness at different environments, scalability to increased number of users, accuracy of using varied number of microphones, impact of the discriminators' weightings, training and inferencing computational cost, etc.

## Hardware and software dependencies

- The spectrum derivation technique requires the support from multi-channel microphone arrays. The hardware model used in this project is the UMA-16(v2) USB mic array which is manufactured by miniDSP company. This device contains sixteen microphone channels, which are arranged as a 4-by-4 uniform rectangular array. The captured raw samples are delivered to a PC through plug&play USB audio connectivity. The distance between adjacent microphone element is 44mm and the array spans the area of 132mm x 132mm. Useful links regarding this device is introduced in below:
    - Specification: https://www.minidsp.com/products/usb-audio-interface/uma-16-microphone-array
    - User manual: https://www.minidsp.com/images/documents/UMA-16%20v2%20User%20Manual.pdf
    - Schematic: https://www.minidsp.com/images/UMA-16_Lite_rev-a_2022y01m05d_1500%20(1).zip
    - Driver installation: https://www.minidsp.com/userdownloads/usb-mic-array-series

- The speaker used in this project is the Grove speaker that is designed by Seeed studio. The speaker is drived by Raspeberry Pi for audio control. Useful links are listed in below:
    - Seeed studio grove-speaker: https://wiki.seeedstudio.com/Grove-Speaker/
    - Schematic: https://files.seeedstudio.com/wiki/Grove-Speaker/res/Grove-Speaker_v1.0_sch.pdf
    - Driver installation: https://github.com/HinTak/seeed-voicecard

- The execution of facial spectrum derivation requires MATLAB and the following toolbox software to be installed: Signal Processing Toolbox, DSP System Toolbox, Mapping Toolbox, and Image Processing Toolbox. During code execution, you may encounter prompts asking for the installation of any missing toolboxes.
  The implementation of RD-Net utilizes Python 3.10.12 and PyTorch 2.2.1+cu121. Additionally, several additional software packages are necessary, including scipy, numpy, pandas, pathlib, drive, time, and sklearn.

## Usage

Using the AcFace framework for face recognition requires executing three main modules: Facial scanning, Facial spectrum derivation, and RD-Net processing (including training and testing). Below, we will introduce the operational methods of these three modules in three parts.

### Facial Scanning

Facial scanning is the initial step in our process. It involves controlling the grove-speaker to transmit signals and utilizing the UMA-16 microphone array to receive signals.

#### Starting the UMA-16

To prepare the UMA-16 for operation, use the following command to set it to standby mode:

```bash
./startAudioRecorder.sh -f <filename> -d <device> -r <duration> -s <sample rate> -n <num channels>
```

The options for this command are defined as follows:

``` 
Options:
    -f <filename>           Specify the path and filename for the recording. Default is 'Rx_file'.
    -d <device>             Specify the device name. Default is 'nanoSHARC micArray16 UAC2.0'.
    -r <duration>           Specify the recording duration in seconds. Default is 5.
    -s <sample rate>        Specify the sample rate in Hz. Default is 48000.
    -n <num channels>       Specify the number of channels. Default is 16.
```

Use the `-h` option to view the definitions of these options.

#### Transmitting the Acoustic Signal

With the UMA-16 ready, begin transmitting the acoustic signal necessary for facial scanning. Control of the speaker is managed through commands provided by the seeed-voicecard. The seeed-voicecard can be installed from [this GitHub repository](https://github.com/HinTak/seeed-voicecard).

After setting up on an RPI (Raspberry Pi), use the following command to play the audio file:

```bash
aplay -D <device> -r <sample rate> <filename>
```

The options for this command are detailed below:

``` 
Options:
    -D <device>             Specify the device name. Default is 'plughw:1,0'.
    -r <sample rate>        Specify the sample rate in Hz. Default is 48000.
    <filename>              Specify the path and filename for storing the audio file.
```

### Facial spectrum derivation

This module processes the received raw samples and derives facial spectrums. It takes in the raw signal and experimental settings (define the settings under `Spectrum derivation/settings/` ) as the input, and calls multiple functions for facial spectrum derivation. 

To start the processing, execute:

```
./startFsProc.sh -s ./settings/ -g ./signal/ -u user1 -m 0
```

The options for this command are detailed below:

``` 
Options:
    -s <settings_folder>   Specify the settings folder path. Default is "./settings/".
    -g <signal_folder>     Specify the signal folder path. Default is "./signal/".
    -u <USER>              Specify the user index, e.g., "user1".
    -m <MASK>              Specify the mask indicator, "1" means with mask, "0" means without mask.
```

### RD-Net processing

Last but not least, RD-Net serves the purpose of accurate and robust facial spectrum recognition. The core of RD-Net is a recognizer-discriminator design, which is optimized for maximal recognition accuracy and minimized mask distinguishing capabiilty. 

The training process can be started by executing the following command:

```
./model_train.sh -d <data folder> -b <batch size> -l <learning rate> -e <num epochs> -m <model folder>
```

The options for this command are detailed below:

``` 
Options:
    -d <data folder>       Specify the directory for data. Default is "./data". 
    -b <batch size>        Specify the batch size. Default is 32.
    -l <learning rate>     Specify the learning rate. Default is 0.001.
    -e <num epochs>        Specify the number of epochs. Default is 30.
    -m <model path>        Specify the path for model saving. Default is "./model.pth"
```

After training completes, you can start model testing by executing the following command:

```
./model_test.sh -d <data folder> -m <model path>
```

The definition of these two arguments is the same as they are in `model_train.sh`. 


#### Training

#### Evaluation

##### Accuracy, Precision, Recall, F1-score

##### Scalability

##### Efficiency

##### Parameter settings


