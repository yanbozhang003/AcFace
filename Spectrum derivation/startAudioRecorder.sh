#!/bin/bash

# Help function to explain the usage
function show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -f <filename>    Specify the path and filename for the recording. Default is 'Rx_file'."
    echo "  -d <device>      Specify the device name. Default is 'nanoSHARC micArray16 UAC2.0'."
    echo "  -r <duration>    Specify the recording duration in seconds. Default is 5."
    echo "  -s <sample rate> Specify the sample rate in Hz. Default is 48000."
    echo "  -n <num channels> Specify the number of channels. Default is 16."
    echo "  -h               Display this help and exit."
    echo ""
    echo "Example:"
    echo "  $0 -f MyRecording -d MyDevice -r 10 -s 44100 -n 8"
}

FILENAME="Rx_file"
DEVICE="nanoSHARC micArray16 UAC2.0"
RX_DURATION=5
FS=48000
NUMCH=16

while getopts "hf:d:r:s:n:" opt; do
  case ${opt} in
    f ) FILENAME=$OPTARG ;;
    d ) DEVICE=$OPTARG ;;
    r ) RX_DURATION=$OPTARG ;;
    s ) FS=$OPTARG ;;
    n ) NUMCH=$OPTARG ;;
    h ) show_help
        exit 0 ;;
    \? ) show_help
         exit 1 ;;
  esac
done

matlab -batch "audioRecorder('filename', '${FILENAME}', 'Device', '${DEVICE}', 'Rx_duration', ${RX_DURATION}, 'Fs', ${FS}, 'NumCh', ${NUMCH})"
